/// Krátký dotazník „Tvůj plán“ a doporučení programu podle odpovědí.
/// Čistý Dart bez Flutteru.
library;

import '../core/i18n.dart';
import '../domain/anatomy.dart';
import '../domain/catalog.dart';
import '../domain/models.dart';
import 'plan_prefs.dart';
import 'splits.dart';
import 'tips.dart';

export 'plan_prefs.dart';

enum PlanGoal {
  muscle,
  strength,
  fitness;

  String get label => switch (this) {
    muscle => tr('Svaly', 'Muscle'),
    strength => tr('Síla', 'Strength'),
    fitness => tr('Kondice', 'Fitness'),
  };

  String get hint => switch (this) {
    muscle => tr(
      'Víc svalů a lepší postava',
      'More muscle and a better physique',
    ),
    strength => tr(
      'Zvednout víc v hlavních cvicích',
      'Lift more on the main lifts',
    ),
    fitness => tr(
      'Cítit se líp a mít víc energie',
      'Feel better and have more energy',
    ),
  };

  static PlanGoal parse(Object? v) =>
      values.where((g) => g.name == v).firstOrNull ?? muscle;
}

/// How the recommended plan is built. `null` in [PlanAnswers] = answers
/// saved before styles existed (the original mapping).
enum PlanStyle {
  science,
  oldSchool,
  strength;

  String get label => switch (this) {
    science => tr('Vědecký přístup', 'Science-based'),
    oldSchool => tr('Old school', 'Old school'),
    strength => tr('Síla', 'Strength'),
  };

  String get hint => switch (this) {
    science => tr(
      'Každý sval 2× týdně, cviky v protažení, 1–2 opakování v záloze. '
          'U každého cviku zdroj.',
      'Every muscle twice a week, exercises that load the stretch, '
          '1–2 reps in reserve. A source for every exercise.',
    ),
    oldSchool => tr(
      'Těžké základy, 5×5 nebo bro split. Jednoduché a osvědčené.',
      'Heavy basics, 5×5 or a bro split. Simple and proven.',
    ),
    strength => tr(
      'Dřep, bench, mrtvý tah. Málo opakování, dlouhé pauzy.',
      'Squat, bench, deadlift. Low reps, long rests.',
    ),
  };

  static PlanStyle? tryParse(Object? v) =>
      values.where((s) => s.name == v).firstOrNull;
}

enum PlanLevel {
  beginner,
  advanced;

  String get label => switch (this) {
    beginner => tr('Začínám', 'Beginner'),
    advanced => tr('Pokročilý', 'Advanced'),
  };

  String get hint => switch (this) {
    beginner => tr(
      'Do roka pravidelného cvičení',
      'Under a year of regular training',
    ),
    advanced => tr('Cvičím déle než rok', 'Training for more than a year'),
  };

  static PlanLevel parse(Object? v) =>
      values.where((l) => l.name == v).firstOrNull ?? beginner;
}

/// Nabízené délky tréninku v minutách.
const planMinutes = [30, 45, 60, 90];

final _builtInIds = [for (final e in builtInExercises) e.id];

class PlanAnswers {
  final PlanGoal goal;

  /// Style of the recommended plan; `null` for older saved answers.
  final PlanStyle? style;

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

  /// Stroje, které v posilovně chybí (odškrtnuté v Moje posilovna).
  final Set<String> missing;

  /// Stroje, které posilovna má navzdory typu (zaškrtnuté zpátky).
  final Set<String> present;
  final Sex? sex;
  final int? heightCm;
  final int? birthYear;
  final WeightGoal? weightGoal;

  const PlanAnswers({
    this.goal = PlanGoal.muscle,
    this.style,
    this.days = 3,
    this.experience = Experience.quarter,
    this.minutes = 60,
    this.place = TrainingPlace.gym,
    this.focus = const {},
    this.avoid = const {},
    this.favorites = const {},
    this.missing = const {},
    this.present = const {},
    this.sex,
    this.heightCm,
    this.birthYear,
    this.weightGoal,
  });

  /// Cviky, které v posilovně nejdou: chybějící stroje podle typu
  /// a uživatelových úprav.
  Set<String> get unavailable => {
    ...place.presetMissing.difference(present),
    ...missing,
  };

  /// Cvik jde v téhle posilovně a nebolí.
  bool allows(Exercise e) =>
      exerciseAllowed(e, place, avoid, unavailable: unavailable);

  /// Do roka cvičení začátečník, pak pokročilý.
  PlanLevel get level =>
      experience.months >= 12 ? PlanLevel.advanced : PlanLevel.beginner;

  PlanAnswers copyWith({
    PlanGoal? goal,
    PlanStyle? style,
    int? days,
    Experience? experience,
    int? minutes,
    TrainingPlace? place,
    Set<String>? focus,
    Set<Joint>? avoid,
    Set<String>? favorites,
    Set<String>? missing,
    Set<String>? present,
  }) => PlanAnswers(
    goal: goal ?? this.goal,
    style: style ?? this.style,
    days: days ?? this.days,
    experience: experience ?? this.experience,
    minutes: minutes ?? this.minutes,
    place: place ?? this.place,
    focus: focus ?? this.focus,
    avoid: avoid ?? this.avoid,
    favorites: favorites ?? this.favorites,
    missing: missing ?? this.missing,
    present: present ?? this.present,
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
    style: style,
    days: days,
    experience: experience,
    minutes: minutes,
    place: place,
    focus: focus,
    avoid: avoid,
    favorites: favorites,
    missing: missing,
    present: present,
    sex: sex,
    heightCm: heightCm,
    birthYear: birthYear,
    weightGoal: weightGoal,
  );

  /// Věk v roce [now]; `null` bez roku narození.
  int? ageIn(DateTime now) => birthYear == null ? null : now.year - birthYear!;

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'style': ?style?.name,
    'days': days,
    // Starší verze aplikace čtou jen úroveň.
    'level': level.name,
    'experience': experience.name,
    'minutes': minutes,
    'place': place.name,
    if (focus.isNotEmpty) 'focus': focus.toList(),
    if (avoid.isNotEmpty) 'avoid': [for (final j in avoid) j.name],
    if (favorites.isNotEmpty) 'favorites': favorites.toList(),
    if (missing.isNotEmpty) 'missing': missing.toList(),
    if (present.isNotEmpty) 'present': present.toList(),
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
      style: PlanStyle.tryParse(json['style']),
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
      missing: ids(json['missing'], _builtInIds),
      present: ids(json['present'], _builtInIds),
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
  final (id, why) = switch (a.style) {
    PlanStyle.science => _science(a, days),
    PlanStyle.oldSchool => _oldSchool(days),
    PlanStyle.strength => _strength(days),
    null => _classic(a, days),
  };
  return PlanRecommendation(
    splitId: id,
    why: why,
    perWeek: days,
    exercises: recommendedCount(a.minutes, a.level),
    restSeconds: switch ((a.style, a.goal)) {
      (PlanStyle.strength, _) => 180,
      (_, PlanGoal.strength) => 180,
      (_, PlanGoal.muscle) => 120,
      (_, PlanGoal.fitness) => 90,
    },
  );
}

(String, String) _science(PlanAnswers a, int days) => switch (days) {
  <= 3 => (
    'science_full_body',
    tr(
      'Celé tělo při každém tréninku: každý sval dostane 2–3 podněty '
          'týdně, což vychází v metaanalýzách líp než 1×.',
      'Full body every session: each muscle gets 2–3 sessions a week, '
          'which beats once a week in meta-analyses.',
    ),
  ),
  4 || 5 when a.level == PlanLevel.beginner || days == 4 => (
    'science_upper_lower',
    tr(
      'Horní a dolní polovina střídavě: každý sval 2× týdně a mezi '
          'tréninky čas na regeneraci.',
      'Upper and lower body in turn: every muscle twice a week with '
          'time to recover in between.',
    ),
  ),
  _ => (
    'science_ppl',
    tr(
      'Push / Pull / Legs dokola: každý sval skoro 2× týdně a dost '
          'sérií na partii pro pokročilé.',
      'Push / Pull / Legs on repeat: every muscle almost twice a week '
          'and enough sets per muscle for advanced lifters.',
    ),
  ),
};

(String, String) _oldSchool(int days) => switch (days) {
  <= 3 => (
    'basics_5x5',
    tr(
      'Tři těžké základy, 5 sérií po 5. Každý trénink přidáš kousek váhy.',
      'Three heavy basics, 5 sets of 5. Add a little weight every session.',
    ),
  ),
  4 || 5 => (
    'bro_split',
    tr(
      'Každý den jedna partie a pořádná dávka sérií. Dny jdou dokola.',
      'One muscle group a day and plenty of sets. Days rotate.',
    ),
  ),
  _ => (
    'arnold',
    tr(
      'Arnold split dvakrát týdně: hrudník se zády, ramena s pažemi, nohy.',
      'Arnold split twice a week: chest and back, shoulders and arms, legs.',
    ),
  ),
};

(String, String) _strength(int days) => switch (days) {
  <= 3 => (
    'strength_sbd',
    tr(
      'Dřep, bench a mrtvý tah několikrát týdně: těžké dny po 3–5 '
          'opakováních, lehčí na objem.',
      'Squat, bench and deadlift several times a week: heavy days of '
          '3–5 reps, lighter ones for volume.',
    ),
  ),
  _ => (
    'strength_upper_lower',
    tr(
      'Horní a dolní polovina střídavě, každý hlavní cvik 2× týdně.',
      'Upper and lower body in turn, each main lift twice a week.',
    ),
  ),
};

/// Mapping used before plan styles existed.
(String, String) _classic(PlanAnswers a, int days) {
  return switch (days) {
    2 => (
      'full_body_3',
      tr(
        'Při 2 trénincích týdně je nejlepší celé tělo pokaždé: '
            'každá partie tak dostane 2 tréninky.',
        'With 2 workouts a week, full body every time is best: '
            'each muscle group gets 2 workouts.',
      ),
    ),
    3 when a.level == PlanLevel.advanced && a.goal == PlanGoal.muscle => (
      'ppl',
      tr(
        'Tlaky, tahy a nohy: víc cviků na partii, '
            'což pokročilým pomáhá dál růst.',
        'Push, pull and legs: more exercises per muscle group, '
            'which helps advanced trainees keep growing.',
      ),
    ),
    3 => (
      'full_body_3',
      tr(
        'Celé tělo 3× týdně: každá partie 3 tréninky týdně '
            'a hlavní cviky se rychle naučíš.',
        'Full body 3× a week: each muscle group gets 3 workouts a week '
            'and you learn the main lifts quickly.',
      ),
    ),
    4 => (
      'upper_lower',
      tr(
        'Horní a dolní polovina střídavě: každá partie 2× týdně '
            'a mezi tréninky dost odpočinku.',
        'Upper and lower body in turn: each muscle group 2× a week '
            'with plenty of rest between workouts.',
      ),
    ),
    5 when a.level == PlanLevel.beginner => (
      'upper_lower',
      tr(
        'Upper / Lower dokola i 5× týdně: každá partie 2–3× týdně, '
            'pro začátek nejbezpečnější.',
        'Upper / Lower on repeat even 5× a week: each muscle group 2–3× a '
            'week, the safest option for beginners.',
      ),
    ),
    6 when a.level == PlanLevel.advanced && a.goal == PlanGoal.muscle => (
      'arnold',
      tr(
        'Arnold split dvakrát za týden: každá partie 2×, '
            'velký objem pro pokročilé.',
        'Arnold split twice a week: each muscle group 2×, '
            'high volume for advanced trainees.',
      ),
    ),
    _ => (
      'ppl',
      tr(
        'Push / Pull / Legs dokola: při $days dnech má každá partie '
            'skoro 2 tréninky týdně.',
        'Push / Pull / Legs on repeat: with $days days each muscle group '
            'gets almost 2 workouts a week.',
      ),
    ),
  };
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
          a.allows(fav);
    }).firstOrNull;
    if (favorite != null) {
      taken.add(favorite);
      out.add(planned.copyWith(exerciseId: favorite));
      continue;
    }
    if (e == null || e.custom || a.allows(e)) {
      out.add(planned);
      continue;
    }
    final swap = replacementFor(
      id,
      place: a.place,
      avoid: a.avoid,
      taken: taken,
      unavailable: a.unavailable,
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
