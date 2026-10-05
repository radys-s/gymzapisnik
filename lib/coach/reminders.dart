/// Plán připomínek tréninku. Čistý Dart bez Flutteru.
///
/// Připomínka se plánuje jen na dny, kdy má smysl: v týdnu, kde ještě není
/// splněný cíl, a ne v den, kdy už se cvičilo. Plán se přepočítává při každém
/// otevření aplikace a po tréninku, takže dnešní připomínka po tréninku
/// zmizí a splněný týden je klidný.
library;

import '../domain/models.dart';
import 'weeks.dart';

/// Dny v týdnu (1 = pondělí), kdy se připomíná při daném týdenním cíli.
const reminderDays = <int, List<int>>{
  1: [3],
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 3, 5, 6],
  6: [1, 2, 3, 4, 5, 6],
  7: [1, 2, 3, 4, 5, 6, 7],
};

class Reminder {
  final DateTime at;
  final String title;
  final String body;
  const Reminder(this.at, this.title, this.body);
}

/// Připomínky na nejbližších [horizonDays] dní od [now], v čase [hour]:[minute].
List<Reminder> planReminders({
  required DateTime now,
  required int hour,
  required int minute,
  required int goal,
  required Iterable<Workout> finished,
  int horizonDays = 14,
}) {
  final days = reminderDays[goal.clamp(1, 7)]!;
  final doneDays = <DateTime>{};
  final perWeek = <DateTime, int>{};
  for (final w in finished) {
    if (!w.finished) continue;
    doneDays.add(dayStart(w.date));
    final monday = weekStart(w.date);
    perWeek[monday] = (perWeek[monday] ?? 0) + 1;
  }
  final result = <Reminder>[];
  final today = dayStart(now);
  for (var i = 0; i < horizonDays; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    final at = DateTime(day.year, day.month, day.day, hour, minute);
    if (!at.isAfter(now)) continue;
    if (!days.contains(day.weekday)) continue;
    if (doneDays.contains(day)) continue;
    if ((perWeek[weekStart(day)] ?? 0) >= goal) continue;
    result.add(
      Reminder(
        at,
        'Čas na trénink',
        'Otevři Gym zápisník, kouč má pro dnešek návrh.',
      ),
    );
  }
  return result;
}
