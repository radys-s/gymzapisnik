import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/missions.dart';
import 'package:gymzapisnik/coach/streak.dart';

// 2026-10-05 je pondělí.
DateTime day(int d, [int h = 18]) => DateTime(2026, 10, d, h);

void main() {
  group('mission', () {
    Mission m(List<DateTime> f, DateTime now, {int goal = 3}) =>
        todayMission(goal: goal, finished: f, now: now);

    test('monday without workouts: train today', () {
      final r = m([], day(5, 8));
      expect(r.kind, MissionKind.trainToday);
      expect(r.remaining, 3);
      expect(r.daysLeft, 7);
      expect(r.shouldTrain, isTrue);
    });

    test('trained today: done today', () {
      expect(m([day(5, 7)], day(5, 20)).kind, MissionKind.doneToday);
    });

    test('goal met: week done, even on a day without training', () {
      final r = m([day(5), day(6), day(7)], day(8));
      expect(r.kind, MissionKind.weekDone);
      expect(r.remaining, 0);
      expect(r.shouldTrain, isFalse);
    });

    test('trained yesterday and time is left: rest', () {
      final r = m([day(5)], day(6));
      expect(r.kind, MissionKind.rest);
      expect(r.shouldTrain, isFalse);
    });

    test('remaining equals days left: catch up', () {
      // čtvrtek 8.: zbývají 4 dny (čt–ne), cíl 4, nic neodcvičeno
      final r = m([], day(8), goal: 4);
      expect(r.kind, MissionKind.catchUp);
      expect(r.daysLeft, 4);
      expect(r.shouldTrain, isTrue);
    });

    test('catch up beats rest', () {
      // neděle 11.: poslední den, chybí 1, včera cvičil -> dnes je potřeba
      expect(m([day(5), day(10)], day(11)).kind, MissionKind.catchUp);
    });

    test('ignores previous weeks and future dates', () {
      final r = m([DateTime(2026, 10, 4, 10), day(12)], day(6));
      expect(r.done, 0);
    });
  });

  group('streak', () {
    Streak s(List<DateTime> f, DateTime now, {int goal = 2}) =>
        computeStreak(goal: goal, finished: f, now: now);

    // pondělky: 5. 10., 12. 10., 19. 10. ...
    DateTime wk(int week, [int dayOffset = 0]) =>
        DateTime(2026, 10, 5 + week * 7 + dayOffset, 18);

    test('no workouts: no streak', () {
      final r = s([], day(5));
      expect(r.weeks, 0);
      expect(r.jokerReady, isTrue);
    });

    test('counts consecutive met weeks and the current one when met', () {
      final f = [wk(0), wk(0, 2), wk(1), wk(1, 1)];
      expect(s(f, wk(2, 1)).weeks, 2);
      expect(s([...f, wk(2), wk(2, 1)], wk(2, 2)).weeks, 3);
    });

    test('unmet current week does not break the streak', () {
      final f = [wk(0), wk(0, 1), wk(1)];
      expect(s(f, wk(1, 3)).weeks, 1);
      expect(s(f, wk(1, 3)).currentWeekMet, isFalse);
    });

    test('a missed week is saved by the joker once', () {
      final f = [wk(0), wk(0, 1), wk(1), wk(1, 1), wk(3), wk(3, 1)];
      final r = s(f, wk(3, 3));
      expect(r.weeks, 3); // týdny 0, 1, (2 = žolík bez bodu), 3
      expect(r.jokerReady, isFalse);
    });

    test('a second miss inside the cooldown resets the streak', () {
      final f = [
        wk(0), wk(0, 1), wk(1), wk(1, 1), // 2 týdny
        // týden 2 zmeškán (žolík), týden 3 zmeškán (reset)
        wk(4), wk(4, 1),
      ];
      expect(s(f, wk(4, 3)).weeks, 1);
    });

    test('joker is not wasted before any streak exists', () {
      final f = [wk(2), wk(2, 1)];
      final r = s(f, wk(2, 3));
      expect(r.weeks, 1);
      expect(r.jokerReady, isTrue);
    });

    test('future-dated workouts do not count', () {
      final f = [wk(0), wk(0, 1), wk(0, 3)];
      expect(s(f, wk(0, 1)).weeks, 1);
      expect(s([wk(0), wk(0, 3)], wk(0, 1)).currentWeekMet, isFalse);
    });

    test('first workout in the current week', () {
      expect(s([wk(0)], wk(0, 1)).weeks, 0);
      expect(s([wk(0), wk(0, 1)], wk(0, 1)).weeks, 1);
    });
  });
}
