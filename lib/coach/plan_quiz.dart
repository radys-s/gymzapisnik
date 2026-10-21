/// Krátký dotazník „Tvůj plán“ a doporučení programu podle odpovědí.
/// Čistý Dart bez Flutteru.
library;

import '../domain/anatomy.dart';
import 'splits.dart';
import 'tips.dart';

enum PlanGoal {
  muscle('Svaly', 'Víc svalů a lepší postava'),
  strength('Síla', 'Zvednout víc v hlavních cvicích'),
  fitness('Kondice', 'Cítit se líp a mít víc energie');

  final String label;
  final String hint;
  const PlanGoal(this.label, this.hint);

  static PlanGoal parse(Object? v) =>
      values.where((g) => g.name == v).firstOrNull ?? muscle;
}

enum PlanLevel {
  beginner('Začínám', 'Do roka pravidelného cvičení'),
  advanced('Pokročilý', 'Cvičím déle než rok');

  final String label;
  final String hint;
  const PlanLevel(this.label, this.hint);

  static PlanLevel parse(Object? v) =>
      values.where((l) => l.name == v).firstOrNull ?? beginner;
}

/// Nabízené délky tréninku v minutách.
const planMinutes = [30, 45, 60, 90];

class PlanAnswers {
  final PlanGoal goal;

  /// Kolikrát týdně chce cvičit (2–6).
  final int days;
  final PlanLevel level;

  /// Kolik minut má na jeden trénink.
  final int minutes;

  const PlanAnswers({
    this.goal = PlanGoal.muscle,
    this.days = 3,
    this.level = PlanLevel.beginner,
    this.minutes = 60,
  });

  PlanAnswers copyWith({
    PlanGoal? goal,
    int? days,
    PlanLevel? level,
    int? minutes,
  }) => PlanAnswers(
    goal: goal ?? this.goal,
    days: days ?? this.days,
    level: level ?? this.level,
    minutes: minutes ?? this.minutes,
  );

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'days': days,
    'level': level.name,
    'minutes': minutes,
  };

  /// Odpovědi ze zálohy nebo profilu; neplatné vrací `null`.
  static PlanAnswers? tryParse(Object? json) {
    if (json is! Map) return null;
    final days = json['days'];
    final minutes = json['minutes'];
    if (days is! num || minutes is! num) return null;
    if (!days.isFinite || !minutes.isFinite) return null;
    final m = minutes.toInt();
    return PlanAnswers(
      goal: PlanGoal.parse(json['goal']),
      days: days.toInt().clamp(2, 6),
      level: PlanLevel.parse(json['level']),
      minutes: planMinutes.contains(m) ? m : 60,
    );
  }
}

class PlanRecommendation {
  final String splitId;

  /// Jedna věta, proč právě tenhle program.
  final String why;
  final int perWeek;

  /// Doporučený počet cviků v jednom tréninku.
  final int exercises;

  /// Pauza mezi sériemi v sekundách podle cíle.
  final int restSeconds;

  const PlanRecommendation({
    required this.splitId,
    required this.why,
    required this.perWeek,
    required this.exercises,
    required this.restSeconds,
  });
}

/// Kolik cviků se vejde do [minutes] (zhruba 9–10 minut na cvik se
/// 3 sériemi a pauzami). Začátečník o jeden méně, ať stihne techniku.
int recommendedCount(int minutes, PlanLevel level) {
  final base = switch (minutes) {
    <= 30 => 4,
    <= 45 => 5,
    <= 60 => 6,
    _ => 8,
  };
  final n = level == PlanLevel.beginner ? base - 1 : base;
  return n.clamp(3, maxBuiltExercises);
}

/// Program podle počtu dnů, zkušenosti a cíle. Každá partie má dostat
/// aspoň 2 tréninky týdně, kde to počet dnů dovolí.
PlanRecommendation recommendPlan(PlanAnswers a) {
  final days = a.days.clamp(2, 6);
  final (id, why) = switch (days) {
    2 => (
      'full_body_3',
      'Při 2 trénincích týdně je nejlepší celé tělo pokaždé: '
          'každá partie tak dostane 2 tréninky.',
    ),
    3 when a.level == PlanLevel.advanced && a.goal == PlanGoal.muscle => (
      'ppl',
      'Tlaky, tahy a nohy: víc cviků na partii, '
          'což pokročilým pomáhá dál růst.',
    ),
    3 => (
      'full_body_3',
      'Celé tělo 3× týdně: každá partie 3 tréninky týdně '
          'a hlavní cviky se rychle naučíš.',
    ),
    4 => (
      'upper_lower',
      'Horní a dolní polovina střídavě: každá partie 2× týdně '
          'a mezi tréninky dost odpočinku.',
    ),
    5 when a.level == PlanLevel.beginner => (
      'upper_lower',
      'Upper / Lower dokola i 5× týdně: každá partie 2–3× týdně, '
          'pro začátek nejbezpečnější.',
    ),
    6 when a.level == PlanLevel.advanced && a.goal == PlanGoal.muscle => (
      'arnold',
      'Arnold split dvakrát za týden: každá partie 2×, '
          'velký objem pro pokročilé.',
    ),
    _ => (
      'ppl',
      'Push / Pull / Legs dokola: při $days dnech má každá partie '
          'skoro 2 tréninky týdně.',
    ),
  };
  return PlanRecommendation(
    splitId: id,
    why: why,
    perWeek: days,
    exercises: recommendedCount(a.minutes, a.level),
    restSeconds: switch (a.goal) {
      PlanGoal.strength => 180,
      PlanGoal.muscle => 120,
      PlanGoal.fitness => 90,
    },
  );
}

/// Den programu upravený na [count] cviků: delší se zkrátí (cviky jsou
/// seřazené od nejdůležitějších), kratší se doplní cviky na stejné
/// partie, které den ještě nepokrývá.
SplitDay fitDay(SplitDay day, int count) {
  final n = count.clamp(1, maxBuiltExercises);
  if (day.exercises.length >= n) {
    return day.copyWith(exercises: day.exercises.take(n).toList());
  }
  final focuses = {
    for (final e in day.exercises)
      if (anatomyOf(e.exerciseId)?.primary.firstOrNull case final h?)
        ?focusOfHead(h),
  };
  if (focuses.isEmpty) return day;
  final have = {for (final e in day.exercises) e.exerciseId};
  final extra = [
    for (final e in buildDay(focuses, maxBuiltExercises).exercises)
      if (!have.contains(e.exerciseId)) e,
  ];
  return day.copyWith(
    exercises: [...day.exercises, ...extra.take(n - day.exercises.length)],
  );
}
