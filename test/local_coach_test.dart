import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/trainer.dart';
import 'package:gymzapisnik/coach/coach_context.dart';
import 'package:gymzapisnik/coach/local_coach.dart';
import 'package:gymzapisnik/coach/missions.dart';
import 'package:gymzapisnik/coach/progression.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/ui/coach/trainer_page.dart' show trainerSuggestions;

Mission mission(MissionKind kind, {int done = 1, int goal = 3}) => Mission(
  kind: kind,
  done: done,
  goal: goal,
  remaining: goal - done < 0 ? 0 : goal - done,
  daysLeft: 4,
);

const squat = Suggestion(
  kind: SuggestionKind.increase,
  weight: 62.5,
  reps: 5,
  sets: 4,
  reason: '',
);
const firstBench = Suggestion(
  kind: SuggestionKind.start,
  weight: 0,
  reps: 5,
  sets: 3,
  reason: '',
);

CoachFacts facts(MissionKind kind) => CoachFacts(
  mission: mission(kind),
  program: 'Full body 3×',
  day: 'Full body A',
  dayNumber: 1,
  dayCount: 3,
  plan: const [
    PlanLine(name: 'Dřep', sets: 4, repMin: 5, repMax: 8, suggestion: squat),
    PlanLine(
      name: 'Bench press',
      sets: 3,
      repMin: 5,
      repMax: 8,
      suggestion: firstBench,
      start: 'prázdné ose (20 kg)',
    ),
  ],
  ready: const ['Nohy', 'Záda'],
);

void main() {
  test('chips map to local intents', () {
    expect(trainerSuggestions.map(classifyQuestion), [
      CoachIntent.today,
      CoachIntent.stall,
      CoachIntent.substitute,
      CoachIntent.volume,
      CoachIntent.week,
    ]);
    expect(classifyQuestion('Jak dýchat při benchi?'), CoachIntent.other);
    // „Dnes“ samo o sobě neznamená dotaz na plán.
    expect(classifyQuestion('Co dnes jíst?'), CoachIntent.other);
    expect(classifyQuestion('Proč mě dnes bolí záda?'), CoachIntent.other);
    expect(classifyQuestion('Kolik tréninků týdně?'), CoachIntent.week);
  });

  test('local answers never reach the AI history', () {
    final at = DateTime(2026, 10, 30);
    final history = aiHistory([
      ChatMessage(ChatRole.user, 'Co mám dnes cvičit?', at),
      ChatMessage(ChatRole.assistant, '• Anežčino stehno', at, local: true),
      ChatMessage(ChatRole.user, 'Jak dýchat?', at),
    ]);
    expect(history.map((m) => m.content), ['Jak dýchat?']);
    final back = ChatMessage.tryParse(
      ChatMessage(ChatRole.assistant, 'x', at, local: true).toJson(),
    );
    expect(back!.local, isTrue);
  });

  test('today answer names the real day and the plan', () {
    final a = todayAnswer(facts(MissionKind.trainToday));
    expect(a, contains('Full body A (den 1 z 3)'));
    expect(a, contains('• Dřep 4×5–8 · 62,5 kg × 5'));
    expect(a, contains('začni na prázdné ose (20 kg)'));
    expect(a, isNot(contains('*')));
  });

  test('today answer respects rest and done days', () {
    expect(todayAnswer(facts(MissionKind.plannedRest)), contains('volno'));
    expect(todayAnswer(facts(MissionKind.doneToday)), contains('odcvičeno'));
    const none = CoachFacts(
      mission: Mission(
        kind: MissionKind.trainToday,
        done: 0,
        goal: 3,
        remaining: 3,
        daysLeft: 5,
      ),
    );
    expect(todayAnswer(none), contains('nemáš zvolený program'));
    expect(none.canStart, isFalse);
  });

  test('briefing greets by time and counts the week', () {
    final b = briefing(
      facts(MissionKind.trainToday),
      DateTime(2026, 10, 30, 7),
    );
    expect(b, startsWith('Dobré ráno.'));
    expect(b, contains('Full body A, 2 cviky'));
    expect(b, contains('Týden: 1 z 3.'));
  });

  test('tidyReply removes markdown', () {
    expect(
      tidyReply('**Dnes:**\n- dřep 3×8\n* bench\n1. tah\n### Tip'),
      'Dnes:\n• dřep 3×8\n• bench\n1. tah\nTip',
    );
    expect(
      tidyReply('3. série: 60 kg\n#1 priorita'),
      '3. série: 60 kg\n#1 priorita',
    );
  });

  test('stall found when last session did not beat the two before', () {
    Workout w(int day, double kg) => Workout(
      id: 'w$day',
      name: 'T',
      startedAt: DateTime(2026, 10, day, 18),
      finishedAt: DateTime(2026, 10, day, 19),
      exercises: [
        WorkoutExercise(
          id: 'e$day',
          exerciseId: 'bench_press',
          sets: [SetEntry(weight: kg, reps: 8, done: true)],
        ),
      ],
    );
    final now = DateTime(2026, 10, 30);
    final flat = findStalls(
      [w(10, 80), w(17, 80), w(24, 80)],
      now,
      (_) => ExerciseType.weighted,
      (_) => 'Bench',
    );
    expect(flat.single.name, 'Bench');
    final up = findStalls(
      [w(10, 80), w(17, 82.5), w(24, 85)],
      now,
      (_) => ExerciseType.weighted,
      (_) => 'Bench',
    );
    expect(up, isEmpty);
  });

  test('context sends today plan and the real program days', () {
    final split = splitTemplates.firstWhere((s) => s.days.length == 3);
    final c = coachContext(
      now: DateTime(2026, 10, 30, 18),
      workouts: const [],
      exercise: (id) => builtInExercises.firstWhere(
        (e) => e.id == id,
        orElse: () => Exercise(id: id, name: id, muscle: 'Nohy'),
      ),
      adult: true,
      weekGoal: 3,
      split: split,
      todayDay: 1,
      mission: mission(MissionKind.trainToday),
      trainingDays: const [1, 3, 5],
    );
    final today = c['todayPlan'] as Map;
    expect(today['day'], split.days[1].name);
    expect(today['dayNumber'], '2/3');
    expect(today['status'], 'dnes trénovat');
    expect((c['program'] as Map)['days'], [for (final d in split.days) d.name]);
    expect(c['trainingDays'], ['po', 'st', 'pá']);
    expect(c.containsKey('nextDay'), isFalse);
    expect(jsonEncode(c).length, lessThan(5500));
  });
}
