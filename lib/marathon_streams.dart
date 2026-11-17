import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StreamStatus { waiting, active, finished }

class MarathonStream {
  MarathonStream({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required Iterable<String> members,
    Iterable<String>? mealIds,
    Iterable<String>? videoIds,
  }) : members = Set.unmodifiable(members),
       mealIds = mealIds == null ? null : Set.unmodifiable(mealIds),
       videoIds = videoIds == null ? null : Set.unmodifiable(videoIds);

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final Set<String> members;
  // Null means the full catalog. An empty set grants access to no entries.
  final Set<String>? mealIds;
  final Set<String>? videoIds;

  StreamStatus statusAt(DateTime now) {
    if (now.isBefore(startsAt)) return StreamStatus.waiting;
    if (!now.isBefore(endsAt)) return StreamStatus.finished;
    return StreamStatus.active;
  }

  MarathonStream withMembers(Iterable<String> members) => MarathonStream(
    id: id,
    name: name,
    startsAt: startsAt,
    endsAt: endsAt,
    members: members,
    mealIds: mealIds,
    videoIds: videoIds,
  );
}

// The local prototype uses the Almaty clock (UTC+05:00).
const almatyOffset = Duration(hours: 5);
DateTime almatyClock(DateTime instant) => instant.toUtc().add(almatyOffset);

class MarathonStreams extends ChangeNotifier {
  MarathonStreams(this._preferences) {
    final raw = _preferences?.getString(_key);
    if (raw == null) return;
    try {
      for (final entry in jsonDecode(raw) as List) {
        _streams.add(
          MarathonStream(
            id: entry['id'] as String,
            name: entry['name'] as String,
            startsAt: DateTime.parse(entry['startsAt'] as String),
            endsAt: DateTime.parse(entry['endsAt'] as String),
            members: (entry['members'] as List).cast<String>(),
            mealIds: (entry['mealIds'] as List?)?.cast<String>(),
            videoIds: (entry['videoIds'] as List?)?.cast<String>(),
          ),
        );
      }
    } on FormatException {
      _streams.clear();
    }
  }

  static const _key = 'local_marathon_streams_v1';
  final SharedPreferences? _preferences;
  List<MarathonStream> _streams = [];
  bool _saving = false;

  Iterable<MarathonStream> get all => _streams;

  MarathonStream? forParticipant(String login) {
    for (final stream in _streams) {
      if (stream.members.contains(login)) return stream;
    }
    return null;
  }

  Future<void> save(MarathonStream stream) async {
    if (_saving) throw StateError('A stream update is already in progress');
    if (stream.name.trim().isEmpty || !stream.endsAt.isAfter(stream.startsAt)) {
      throw ArgumentError('Invalid stream');
    }
    _saving = true;
    try {
      final next = [
        for (final item in _streams)
          if (item.id == stream.id)
            stream
          else
            item.withMembers(item.members.difference(stream.members)),
        if (_streams.every((item) => item.id != stream.id)) stream,
      ];
      final json = jsonEncode([
        for (final item in next)
          {
            'id': item.id,
            'name': item.name,
            'startsAt': item.startsAt.toUtc().toIso8601String(),
            'endsAt': item.endsAt.toUtc().toIso8601String(),
            'members': item.members.toList(),
            'mealIds': item.mealIds?.toList(),
            'videoIds': item.videoIds?.toList(),
          },
      ]);
      if (await _preferences?.setString(_key, json) == false) {
        throw StateError('Could not save stream');
      }
      _streams = next;
      notifyListeners();
    } finally {
      _saving = false;
    }
  }
}
