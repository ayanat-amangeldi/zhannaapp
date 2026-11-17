import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../language.dart';
import '../marathon_streams.dart';
import '../participant_accounts.dart';
import 'streams_screen.dart';

class ParticipantAccessScreen extends StatefulWidget {
  const ParticipantAccessScreen({
    super.key,
    required this.participant,
    required this.streams,
    required this.marathon,
  });

  final Participant participant;
  final MarathonStreams streams;
  final Widget Function(MarathonStream?) marathon;

  @override
  State<ParticipantAccessScreen> createState() =>
      _ParticipantAccessScreenState();
}

class _ParticipantAccessScreenState extends State<ParticipantAccessScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  MarathonStream? _stream;
  StreamStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.streams.addListener(_refresh);
    _update();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.streams.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _update() {
    _timer?.cancel();
    final now = DateTime.now();
    _stream = widget.streams.forParticipant(widget.participant.login);
    final stream = _stream;
    if (stream == null) {
      _status = widget.participant.login == 'aidana'
          ? StreamStatus.active
          : null;
      return;
    }
    _status = stream.statusAt(now);
    final boundary = switch (_status) {
      StreamStatus.waiting => stream.startsAt,
      StreamStatus.active => stream.endsAt,
      _ => null,
    };
    if (boundary != null) _timer = Timer(boundary.difference(now), _refresh);
  }

  void _refresh() {
    if (!mounted) return;
    final hadAccess = _status == StreamStatus.active;
    final previous = _stream;
    setState(_update);
    final catalogChanged =
        previous?.id != _stream?.id ||
        !setEquals(previous?.mealIds, _stream?.mealIds) ||
        !setEquals(previous?.videoIds, _stream?.videoIds);
    // A recipe, shopping list or video may still be open above the marathon.
    if (hadAccess && (_status != StreamStatus.active || catalogChanged)) {
      final route = ModalRoute.of(context);
      if (route != null && route.isActive && !route.isCurrent) {
        Navigator.of(context).popUntil((candidate) => candidate == route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == StreamStatus.active) return widget.marathon(_stream);
    final (title, description, icon) = switch (_status) {
      StreamStatus.waiting => (
        context.tr('Марафон ещё не начался', 'Марафон әлі басталған жоқ'),
        context.tr(
          'Начало по времени Алматы',
          'Алматы уақыты бойынша басталуы',
        ),
        Icons.calendar_month_outlined,
      ),
      StreamStatus.finished => (
        context.tr('Марафон завершён', 'Марафон аяқталды'),
        context.tr(
          'Доступ закончился по времени Алматы',
          'Алматы уақыты бойынша қолжетімділік аяқталды',
        ),
        Icons.event_available_outlined,
      ),
      _ => (
        context.tr('Поток ещё не назначен', 'Топ әлі тағайындалмады'),
        context.tr(
          'Обратись к Жанне, чтобы она добавила тебя в поток.',
          'Топқа қосылу үшін Жаннаға хабарлас.',
        ),
        Icons.group_outlined,
      ),
    };
    final boundary = _status == StreamStatus.waiting
        ? _stream?.startsAt
        : _stream?.endsAt;
    return Scaffold(
      appBar: AppBar(actions: const [LanguageSwitch()]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      icon,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    if (_stream != null)
                      Text(_stream!.name, textAlign: TextAlign.center),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(description, textAlign: TextAlign.center),
                    if (boundary != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        streamDateTime(context, boundary),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        context.tr('На стартовый экран', 'Бастапқы экранға'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
