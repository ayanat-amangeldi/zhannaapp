import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhannaapp/marathon_streams.dart';

void main() {
  final start = DateTime.utc(2026, 11, 14, 19);
  final end = start.add(const Duration(days: 1));

  MarathonStream stream(String id, Set<String> members) => MarathonStream(
    id: id,
    name: id,
    startsAt: start,
    endsAt: end,
    members: members,
  );

  test('Start is inclusive and end is exclusive at Almaty midnight', () {
    final flow = stream('test', {'dana01'});
    expect(
      flow.statusAt(start.subtract(const Duration(milliseconds: 1))),
      StreamStatus.waiting,
    );
    expect(flow.statusAt(start), StreamStatus.active);
    expect(
      flow.statusAt(end.subtract(const Duration(milliseconds: 1))),
      StreamStatus.active,
    );
    expect(flow.statusAt(end), StreamStatus.finished);
    expect(almatyClock(start), DateTime.utc(2026, 11, 15));
  });

  test(
    'Reassigning a member removes the old assignment and persists the new one',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final streams = MarathonStreams(prefs);
      addTearDown(streams.dispose);
      await streams.save(stream('first', {'dana01', 'amira'}));
      await streams.save(stream('second', {'dana01'}));
      final restored = MarathonStreams(prefs);
      addTearDown(restored.dispose);
      expect(restored.forParticipant('dana01')?.id, 'second');
      expect(restored.forParticipant('amira')?.id, 'first');
      expect(restored.forParticipant('other'), isNull);
    },
  );
}
