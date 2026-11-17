import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Participant = ({String login, String name});

const invitationScheme = 'kezek-sende';
const invitationHost = 'invite';
const invitationPath = '/activate';

bool _validInvitationToken(String? token) =>
    token != null && RegExp(r'^[a-zA-Z0-9_-]{43}$').hasMatch(token);

String? invitationToken(String value, {bool platformRoute = false}) {
  final link = Uri.tryParse(value.trim());
  if (link == null || link.path != invitationPath) return null;
  final isAppLink =
      link.scheme == invitationScheme &&
      link.host == invitationHost &&
      link.userInfo.isEmpty &&
      !link.hasPort;
  final isPlatformPath = platformRoute && !link.hasScheme && !link.hasAuthority;
  if (!isAppLink && !isPlatformPath) return null;
  try {
    final tokens = link.queryParametersAll['token'];
    if (tokens == null || tokens.length != 1) return null;
    return _validInvitationToken(tokens.single) ? tokens.single : null;
  } on FormatException {
    return null;
  }
}

class ParticipantAccounts extends ChangeNotifier {
  ParticipantAccounts(this._preferences) {
    for (final record
        in jsonDecode(_preferences?.getString(_key) ?? '[]') as List) {
      _records[record['login'] as String] = Map<String, String>.from(
        record as Map,
      );
    }
  }

  static const _key = 'local_participant_accounts_v1';
  final SharedPreferences? _preferences;
  final _records = <String, Map<String, String>>{};
  final _random = Random.secure();
  Future<void> _pendingWrite = Future.value();

  Future<T> _write<T>(Future<T> Function() action) {
    final result = _pendingWrite.then((_) => action());
    _pendingWrite = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _saveRecord(Map<String, String> record) async {
    final login = record['login']!;
    final updated = {..._records, login: record};
    if (await _preferences?.setString(
          _key,
          jsonEncode(updated.values.toList()),
        ) ==
        false) {
      throw StateError('Could not save participant');
    }
    _records[login] = record;
    notifyListeners();
  }

  Future<Uri> createInvitation(String login) => _write(() async {
    final record = _records[_normalize(login)];
    if (record == null) throw ArgumentError('Unknown participant');
    final token = _token(32);
    await _saveRecord({
      ...record,
      'inviteDigest': _digest('invitation', token),
      'inviteEndsAt': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 72))
          .toIso8601String(),
    });
    return Uri(
      scheme: invitationScheme,
      host: invitationHost,
      path: invitationPath,
      queryParameters: {'token': token},
    );
  });

  Future<Participant?> redeemInvitation(String token) => _write(() async {
    if (!_validInvitationToken(token)) return null;
    final digest = _digest('invitation', token);
    final record = _records.values
        .where((item) => item['inviteDigest'] == digest)
        .firstOrNull;
    if (record == null) return null;
    final end = DateTime.tryParse(record['inviteEndsAt'] ?? '');
    if (end == null || !DateTime.now().isBefore(end)) return null;
    final redeemed = {...record}
      ..remove('inviteDigest')
      ..remove('inviteEndsAt');
    await _saveRecord(redeemed);
    return (login: redeemed['login']!, name: redeemed['name']!);
  });

  Iterable<Participant> get participants => _records.values.map(
    (record) => (login: record['login']!, name: record['name']!),
  );

  String _normalize(String value) => value.trim().toLowerCase();

  bool validLogin(String value) =>
      RegExp(r'^[a-z0-9][a-z0-9._-]{2,31}$').hasMatch(_normalize(value));

  bool loginTaken(String value) {
    final login = _normalize(value);
    return login == 'aidana' ||
        login == 'zhanna' ||
        _records.containsKey(login);
  }

  Future<String> create({required String name, required String login}) =>
      _write(() async {
        final normalized = _normalize(login);
        if (name.trim().isEmpty ||
            !validLogin(normalized) ||
            loginTaken(normalized)) {
          throw ArgumentError('Invalid participant');
        }
        final password = _token(12);
        final salt = _token(16);
        final record = {
          'login': normalized,
          'name': name.trim(),
          'salt': salt,
          'digest': _digest(salt, password),
        };
        await _saveRecord(record);
        return password;
      });

  Participant? signIn(String login, String password) {
    final normalized = _normalize(login);
    if (normalized == 'aidana' && password == 'AidanaDemo2026') {
      return (login: normalized, name: 'Айдана');
    }
    final record = _records[normalized];
    if (record == null ||
        _digest(record['salt']!, password) != record['digest']) {
      return null;
    }
    return (login: normalized, name: record['name']!);
  }

  String _token(int size) => base64UrlEncode(
    List.generate(size, (_) => _random.nextInt(256)),
  ).replaceAll('=', '');

  String _digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}
