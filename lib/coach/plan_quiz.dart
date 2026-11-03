/// Krátký dotazník „Tvůj plán“ a doporučení programu podle odpovědí.
/// Čistý Dart bez Flutteru.
library;

import '../domain/anatomy.dart';
import '../domain/catalog.dart';
import '../domain/models.dart';
import 'plan_prefs.dart';
import 'splits.dart';
import 'tips.dart';

export 'plan_prefs.dart';

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
  final Experience experience;

  /// Kolik minut má na jeden trénink.
  final int minutes;
  final TrainingPlace place;

  /// Partie, kterým dát přednost (`focusChoices`).
  final Set<String> focus;

  /// Klouby, které se mají šetřit.
  final Set<Joint> avoid;

  /// Cviky, které si chce v plánu nechat (`favoriteChoices`).
  final Set<String> favorites;
  final Sex? sex;
  final int? heightCm;
  final int? birthYear;
  final WeightGoal? weightGoal;

  const PlanAnswers({
    this.goal = PlanGoal.muscle,
    this.days = 3,
    this.experience = Experience.quarter,
    this.minutes = 60,
    this.place = TrainingPlace.gym,
    this.focus = const {},
    this.avoid = const {},
    this.favorites = const {},
    this.sex,
    this.heightCm,
    this.birthYear,
    this.weightGoal,
  });

  /// Do roka cvičení začátečník, pak pokročilý.
  PlanLevel get level =>
      experience.months >= 12 ? PlanLevel.advanced : PlanLevel.beginner;

  PlanAnswers copyWith({
    PlanGoal? goal,
    int? days,
    Experience? experience,
    int? minutes,
    TrainingPlace? place,
    Set<String>? focus,
    Set<Joint>? avoid,
    Set<String>? favorites,
  }) => PlanAnswers(
    goal: goal ?? this.goal,
    days: days ?? this.days,
    experience: experience ?? this.experience,
    minutes: minutes ?? this.minutes,
    place: place ?? this.place,
    focus: focus ?? this.focus,
    avoid: avoid ?? this.avoid,
    favorites: favorites ?? this.favorites,
    sex: sex,
    heightCm: heightCm,
    birthYear: birthYear,
    weightGoal: weightGoal,
  );

  /// Údaje o těle; `null` hodnotu smaže (pole jsou nepovinná).
  PlanAnswers withBody({
    required Sex? sex,
    required int? heightCm,
    required int? birthYear,
    required WeightGoal? weightGoal,
  }) => PlanAnswers(
    goal: goal,
    days: days,
    experience: experience,
    minutes: minutes,
    place: place,
    focus: focus,
    avoid: avoid,
    favorites: favorites,
    sex: sex,
    heightCm: heightCm,
    birthYear: birthYear,
    weightGoal: weightGoal,
  );

  /// Věk v roce [now]; `null` bez roku narození.
  int? ageIn(DateTime now) => birthYear == null ? null : now.year - birthYear!;

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'days': days,
    // Starší verze aplikace čtou jen úroveň.
    'level': level.name,
    'experience': experience.name,
    'minutes': minutes,
    'place': place.name,
    if (focus.isNotEmpty) 'focus': focus.toList(),
    if (avoid.isNotEmpty) 'avoid': [for (final j in avoid) j.name],
    if (favorites.isNotEmpty) 'favorites': favorites.toList(),
    'sex': ?sex?.name,
    'heightCm': ?heightCm,
    'birthYear': ?birthYear,
    'weightGoal': ?weightGoal?.name,
  };

  /// Odpovědi ze zálohy nebo profilu; neplatné vrací `null`.
  static PlanAnswers? tryParse(Object? json) {
    if (json is! Map) return null;
    final days = json['days'];
    final minutes = json['minutes'];
    if (days is! num || minutes is! num) return null;
    if (!days.isFinite || !minutes.isFinite) return null;
    final m = minutes.toInt();
    Set<String> ids(Object? v, List<String> allowed) => {
      if (v is List)
        for (final x in v)
          if (x is String && allowed.contains(x)) x,
    };
    int? whole(Object? v, int min, int max) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toInt() : null;
    final year = DateTime.now().year;
    return PlanAnswers(
      goal: PlanGoal.parse(json['goal']),
      days: days.toInt().clamp(2, 6),
      experience:
          Experience.tryParse(json['experience']) ??
          (PlanLevel.parse(json['level']) == PlanLevel.advanced
              ? Experience.two
              : Experience.quarter),
      minutes: planMinutes.contains(m) ? m : 60,
      place: TrainingPlace.parse(json['place']),
      focus: ids(json['focus'], focusChoices),
      avoid: Joint.parseAll(json['avoid']),
      favorites: ids(json['favorites'], favoriteChoices),
      sex: Sex.tryParse(json['sex']),
      heightCm: whole(json['heightCm'], 120, 230),
      birthYear: whole(json['birthYear'], year - 100, year - 10),
      weightGoal: WeightGoal.tryParse(json['weightGoal']),
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

/// Den přizpůsobený odpovědím z úvodu. Oblíbený cvik nahradí cvik na
/// stejný sval, cvik bez vybavení nebo na šetřený kloub se vymění (když
/// náhrada není, vypadne), první cvik prioritní partie dostane sérii
/// navíc a úplný nováček cvičí méně sérií s víc opakováními.
SplitDay personalizeDay(SplitDay day, PlanAnswers a) {
  final taken = {for (final e in day.exercises) e.exerciseId};
  final out = <PlannedExercise>[];
  for (final planned in day.exercises) {
    final id = planned.exerciseId;
    final e = findExercise(id, const []);
    final favorite = a.favorites.where((f) {
      final fav = findExercise(f, const []);
      return !taken.contains(f) &&
          e != null &&
          fav != null &&
          _sameRole(e, fav) &&
          exerciseAllowed(fav, a.place, a.avoid);
    }).firstOrNull;
    if (favorite != null) {
      taken.add(favorite);
      out.add(planned.copyWith(exerciseId: favorite));
      continue;
    }
    if (e == null || e.custom || exerciseAllowed(e, a.place, a.avoid)) {
      out.add(planned);
      continue;
    }
    final swap = replacementFor(
      id,
      place: a.place,
      avoid: a.avoid,
      taken: taken,
    );
    if (swap == null) continue;
    taken.add(swap.id);
    out.add(planned.copyWith(exerciseId: swap.id));
  }
  // Bez vybavení nemusí zbýt nic: radši původní den než prázdný.
  if (out.isEmpty) return day;
  // Začátečník nejdřív méně sérií a víc opakování, teprve pak přidá
  // série partiím, na které se chce zaměřit.
  if (a.experience == Experience.fresh) {
    for (final (i, planned) in out.indexed) {
      final repMin = planned.repMin < 10 ? 10 : planned.repMin;
      out[i] = planned.copyWith(
        sets: planned.sets.clamp(1, 3),
        repMin: repMin,
        repMax: planned.repMax < repMin + 2 ? repMin + 2 : planned.repMax,
      );
    }
  }
  final boosted = <String>{};
  for (final (i, planned) in out.indexed) {
    final head = primaryHead(planned.exerciseId);
    final focus = head == null ? null : focusOfHead(head);
    if (focus != null && a.focus.contains(focus) && boosted.add(focus)) {
      out[i] = planned.copyWith(sets: (planned.sets + 1).clamp(1, 5));
    }
  }
  return day.copyWith(exercises: out);
}

/// Oblíbený cvik zastoupí plánovaný, když dělá stejnou práci: stejný
/// pohybový vzor (mrtvý tah za rumunský), nebo jde o dvě izolace se
/// stejnou hlavní hlavou svalu. Vícekloubový cvik tak nikdy nezabere
/// místo izolace a leg press nevytlačí dřep.
bool _sameRole(Exercise planned, Exercise favorite) {
  if (planned.pattern == favorite.pattern) return true;
  final head = primaryHead(planned.id);
  final favHead = primaryHead(favorite.id);
  final plannedMulti = (anatomyOf(planned.id)?.primary.length ?? 0) > 1;
  final favMulti = (anatomyOf(favorite.id)?.primary.length ?? 0) > 1;
  return head != null && head == favHead && !plannedMulti && !favMulti;
}
