import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/reminders.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/notify/notifier.dart';
import 'package:gymzapisnik/state/app_state.dart';

Workout done(DateTime at) => Workout(
  id: 'w${at.microsecondsSinceEpoch}',
  name: 'T',
  startedAt: at,
  finishedAt: at.add(const Duration(hours: 1)),
);

// 2026-10-05 je pondělí.
final monday = DateTime(2026, 10, 5);

class FakeNotifier implements Notifier {
  bool allow = true;
  int cancels = 0;
  List<Reminder>? last;

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<void> schedule(List<Reminder> reminders) async => last = reminders;

  @override
  Future<void> cancelAll() async => cancels++;
}

void main() {
  test('goal 3 reminds Mon/Wed/Fri at the chosen time, never in the past', () {
    final r = planReminders(
      now: DateTime(2026, 10, 5, 7),
      hour: 18,
      minute: 30,
      goal: 3,
      finished: const [],
      horizonDays: 7,
    );
    expect(r.map((x) => x.at), [
      DateTime(2026, 10, 5, 18, 30),
      DateTime(2026, 10, 7, 18, 30),
      DateTime(2026, 10, 9, 18, 30),
    ]);
    // po čase dnešní připomínky už dnes nic
    final late = planReminders(
      now: DateTime(2026, 10, 5, 19),
      hour: 18,
      minute: 30,
      goal: 3,
      finished: const [],
      horizonDays: 7,
    );
    expect(late.first.at, DateTime(2026, 10, 7, 18, 30));
  });

  test('skips a day already trained and a week with the goal met', () {
    final trainedToday = planReminders(
      now: DateTime(2026, 10, 5, 7),
      hour: 18,
      minute: 0,
      goal: 3,
      finished: [done(DateTime(2026, 10, 5, 6))],
      horizonDays: 7,
    );
    expect(trainedToday.first.at, DateTime(2026, 10, 7, 18));

    final weekDone = planReminders(
      now: DateTime(2026, 10, 6, 7),
      hour: 18,
      minute: 0,
      goal: 2,
      finished: [
        done(DateTime(2026, 10, 5, 9)),
        done(DateTime(2026, 10, 6, 6)),
      ],
      horizonDays: 6,
    );
    // týden splněn: žádná připomínka do neděle, další týden pondělí 12.
    expect(weekDone, isEmpty);
    final nextWeek = planReminders(
      now: DateTime(2026, 10, 6, 7),
      hour: 18,
      minute: 0,
      goal: 2,
      finished: [
        done(DateTime(2026, 10, 5, 9)),
        done(DateTime(2026, 10, 6, 6)),
      ],
      horizonDays: 14,
    );
    expect(nextWeek.first.at, DateTime(2026, 10, 12, 18));
  });

  test(
    'AppState schedules, cancels and respects a denied permission',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final fake = FakeNotifier();
      final state = AppState(LocalStore(db), notifier: fake);
      await state.load();

      fake.allow = false;
      expect(await state.setReminder(18 * 60), isFalse);
      expect(state.profile.reminderMinutes, isNull);

      fake.allow = true;
      expect(await state.setReminder(18 * 60), isTrue);
      expect(state.profile.reminderMinutes, 1080);
      expect(fake.last, isNotEmpty);

      final before = fake.cancels;
      expect(await state.setReminder(null), isTrue);
      expect(state.profile.reminderMinutes, isNull);
      expect(fake.cancels, before + 1);
    },
  );
}
