/// Trenér, který tlačí dopředu: hodnocení tréninku, poznání zaseknuté
/// váhy, rady co s tím a týdenní cíl. Čistý Dart bez Flutteru.
library;

import '../core/i18n.dart';
import '../domain/history.dart';
import '../domain/models.dart';
import '../domain/profile_keys.dart';
import '../domain/stats.dart';
import 'progression.dart';
import 'weeks.dart';

/// Jak těžký byl trénink. Ukládá se do `Workout.extra['rating']`
/// a mění, jak rychle kouč přidává váhu.
enum WorkoutRating {
  easy,
  good,
  hard,
  limit;

  String get label => switch (this) {
    WorkoutRating.easy => tr('Lehký', 'Easy'),
    WorkoutRating.good => tr('Akorát', 'Just right'),
    WorkoutRating.hard => tr('Těžký', 'Hard'),
    WorkoutRating.limit => tr('Na hraně', 'At the limit'),
  };

  String get hint => switch (this) {
    WorkoutRating.easy => tr('Měl jsem rezervu', 'I had something left'),
    WorkoutRating.good => tr(
      'Zabralo to, ale šlo to',
      'It was hard but doable',
    ),
    WorkoutRating.hard => tr('Poslední série na doraz', 'Last set to failure'),
    WorkoutRating.limit => tr('Víc už by nešlo', 'Could not do any more'),
  };

  static WorkoutRating? tryParse(Object? v) =>
      values.where((r) => r.name == v).firstOrNull;
}

const ratingKey = 'rating';

WorkoutRating? ratingOf(Workout w) =>
    WorkoutRating.tryParse(w.extra[ratingKey]);

/// Cvik, na kterém váha stojí: nejlepší odhad 1RM z posledních
/// [sessions] provedení nepřekonal rekord z doby před nimi.
class Plateau {
  final String exerciseId;

  /// Kolik provedení po sobě bez nového maxima.
  final int sessions;

  /// Nejlepší odhad 1RM (kg), na který se nedaří navázat.
  final double best;

  /// Nejtěžší váha posledního provedení.
  final double topWeight;

  /// Kolikrát týdně cvik průměrně dělá (poslední čtyři týdny).
  final double perWeek;
  const Plateau({
    required this.exerciseId,
    required this.sessions,
    required this.best,
    required this.topWeight,
    this.perWeek = 1,
  });
}

double _bestE1rm(ExerciseSession s) => s.entry.countedSets.fold(
  0.0,
  (m, set) => e1rm(set.weight, set.reps) > m ? e1rm(set.weight, set.reps) : m,
);

double _top(ExerciseSession s) =>
    s.entry.countedSets.fold(0.0, (m, set) => set.weight > m ? set.weight : m);

/// Nejvíc opakování v jedné sérii s danou váhou.
int _repsAt(ExerciseSession s, double kg) => s.entry.countedSets
    .where((set) => (set.weight - kg).abs() < 0.01)
    .fold(0, (m, set) => set.reps > m ? set.reps : m);

/// Odlehčený trénink: navržený koučem nebo o víc než 8 % lehčí.
bool _isDeload(ExerciseSession s, double previousTop) =>
    wasDeload(s) || (previousTop > 0 && _top(s) <= previousTop * 0.92);

/// Zaseknutí u cviku s váhou: aspoň tři provedení po sobě bez posunu.
/// Posun je nové maximum, těžší váha, nebo víc opakování se stejnou
/// váhou (dvojitá progrese). Odlehčené tréninky se nepočítají.
/// Historie od nejstarší (jako z [exerciseHistory]).
Plateau? plateauOf(
  String exerciseId,
  ExerciseType type,
  List<ExerciseSession> history,
) {
  if (type != ExerciseType.weighted || history.length < 4) return null;
  // Jen posledních deset provedení: dávný rekord po pauze není zaseknutí.
  final recent = history.length > 10
      ? history.sublist(history.length - 10)
      : history;
  var best = _bestE1rm(recent.first);
  var previousTop = _top(recent.first);
  var heaviest = previousTop;
  // Nejvíc opakování, jaké kdy s danou váhou padlo (klíč v gramech).
  final repsBest = <int, int>{
    (previousTop * 1000).round(): _repsAt(recent.first, previousTop),
  };
  var since = 0;
  var lastWasDeload = false;
  for (final s in recent.skip(1)) {
    final top = _top(s);
    lastWasDeload = _isDeload(s, previousTop);
    if (lastWasDeload) continue;
    final e = _bestE1rm(s);
    final key = (top * 1000).round();
    final reps = _repsAt(s, top);
    final moved =
        e > best + 0.01 ||
        top > heaviest + 0.01 ||
        (repsBest.containsKey(key) && reps > repsBest[key]!);
    if (e > best) best = e;
    if (top > heaviest) heaviest = top;
    if (reps > (repsBest[key] ?? 0)) repsBest[key] = reps;
    since = moved ? 0 : since + 1;
    previousTop = top;
  }
  // Po odlehčení se nejdřív čeká, jak se vrátí síla.
  if (since < 3 || lastWasDeload || best <= 0) return null;
  final last = recent.last.entry.countedSets;
  final from = recent.last.date.subtract(const Duration(days: 28));
  final month = history.where((s) => s.date.isAfter(from)).length;
  return Plateau(
    exerciseId: exerciseId,
    sessions: since,
    best: best,
    topWeight: last.fold(0.0, (m, s) => s.weight > m ? s.weight : m),
    perWeek: month / 4,
  );
}

String _kg(double v) =>
    (v == v.roundToDouble()
            ? v.toStringAsFixed(0)
            : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), ''))
        .replaceAll('.', ',');

String _count(int n, String one, String few, String many) =>
    '$n ${n == 1
        ? one
        : n >= 2 && n <= 4
        ? few
        : many}';

/// Bílkoviny za posledních sedm dní: průměr dní, kdy se jídlo zapsalo.
/// `null`, když je zapsaných dní málo na úsudek (méně než tři).
typedef ProteinWeek = ({double average, double target, int days});

/// Málo bílkovin: průměr pod 80 % cíle.
bool proteinLow(ProteinWeek? p) =>
    p != null && p.target > 0 && p.average < p.target * 0.8;

/// Co zkusit, když váha stojí. Nejdřív to, co pravděpodobně pomůže
/// nejvíc; čísla jsou spočítaná pro tenhle cvik.
List<String> plateauTips(
  Plateau p, {
  ProteinWeek? protein,
  double increment = 2.5,
  WorkoutRating? lastRating,
}) {
  final lighter = (p.topWeight * 0.9 / increment).round() * increment;
  return [
    if (proteinLow(protein))
      tr(
        'Jíš v průměru ${protein!.average.round()} g bílkovin z '
            '${protein.target.round()} g. Bez nich síla neroste, '
            'dobij je dřív, než budeš měnit trénink.',
        'You average ${protein.average.round()} g of protein out of '
            '${protein.target.round()} g. Without it strength will not grow, '
            'so fix that before changing your training.',
      ),
    if (lastRating == WorkoutRating.limit || lastRating == WorkoutRating.hard)
      tr(
        'Jedeš na doraz. Dej si lehčí týden: ${_kg(lighter)} kg (−10 %) na '
            'všechny série, pak zpět na ${_kg(p.topWeight)} kg.',
        'You are going all out. Take a lighter week: ${_kg(lighter)} kg '
            '(−10 %) on all sets, then back to ${_kg(p.topWeight)} kg.',
      )
    else
      tr(
        'Dej si jeden lehčí trénink: ${_kg(lighter)} kg (−10 %). Odpočaté '
            'tělo pak rekord zvedne snáz.',
        'Do one lighter workout: ${_kg(lighter)} kg (−10 %). A rested body '
            'will hit the record more easily.',
      ),
    tr(
      'Přidávej menší kroky: 1,25 kg místo ${_kg(increment)} kg. '
          'Malé kotouče se sčítají.',
      'Use smaller steps: 1.25 kg instead of ${_kg(increment)} kg. '
          'Small plates add up.',
    ),
    tr(
      'Změň rozsah: tři týdny 4–6 opakování s těžší váhou, pak se vrať '
          'k obvyklému rozsahu.',
      'Change the rep range: three weeks of 4–6 reps with a heavier weight, '
          'then return to your usual range.',
    ),
    if (p.perWeek < 1.5)
      tr(
        'Zařaď cvik dvakrát týdně místo jednou, ať má sval víc podnětů.',
        'Do the exercise twice a week instead of once to give the muscle '
            'more stimulus.',
      ),
    tr(
      'Mezi těžkými sériemi pauza 3 minuty a spánek aspoň 7 hodin.',
      'Rest 3 minutes between heavy sets and sleep at least 7 hours.',
    ),
  ];
}

/// Na co se tento týden tlačí.
enum FocusKind {
  strength,
  consistency,
  volume,
  protein;

  String get label => switch (this) {
    FocusKind.strength => tr('Síla v cviku', 'Strength in one lift'),
    FocusKind.consistency => tr('Pravidelnost', 'Consistency'),
    FocusKind.volume => tr('Objem', 'Volume'),
    FocusKind.protein => tr('Bílkoviny', 'Protein'),
  };

  String get hint => switch (this) {
    FocusKind.strength => tr(
      'Zvednout víc v jednom cviku',
      'Lift more in one exercise',
    ),
    FocusKind.consistency => tr(
      'Nevynechat ani jeden trénink',
      'Do not miss a workout',
    ),
    FocusKind.volume => tr(
      'Víc sérií než minulý týden',
      'More sets than last week',
    ),
    FocusKind.protein => tr(
      'Trefit cíl bílkovin aspoň 5 dní',
      'Hit your protein goal at least 5 days',
    ),
  };

  static FocusKind? tryParse(Object? v) =>
      values.where((k) => k.name == v).firstOrNull;
}

/// Klíč v profilu se zvoleným zaměřením týdne.
const weekFocusKey = ProfileKey.weekFocus;

/// Krátkodobý cíl na jeden týden (od pondělí). Ukládá se do profilu.
class WeekFocus {
  final FocusKind kind;

  /// Cvik pro [FocusKind.strength].
  final String? exerciseId;

  /// Pondělí týdne, pro který cíl platí.
  final DateTime week;
  const WeekFocus(this.kind, {required this.week, this.exerciseId});

  /// Cíl platí jen v týdnu, kdy byl nastaven.
  bool activeAt(DateTime now) => weekStart(now) == week;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'exerciseId': ?exerciseId,
    'week': '${week.year}-${week.month}-${week.day}',
  };

  static WeekFocus? tryParse(Object? json) {
    if (json is! Map) return null;
    final kind = FocusKind.tryParse(json['kind']);
    final parts = '${json['week']}'.split('-').map(int.tryParse).toList();
    if (kind == null || parts.length != 3 || parts.contains(null)) {
      return null;
    }
    final id = json['exerciseId'];
    if (kind == FocusKind.strength && id is! String) return null;
    return WeekFocus(
      kind,
      week: DateTime(parts[0]!, parts[1]!, parts[2]!),
      exerciseId: id is String ? id : null,
    );
  }
}

/// Jak je na tom týdenní cíl: hodnota, cíl a věta, která tlačí dál.
class FocusProgress {
  final double value;
  final double target;

  /// Jednotka nebo popis hodnoty („kg 1RM“, „tréninky“).
  final String unit;
  final String push;
  const FocusProgress(this.value, this.target, this.unit, this.push);

  bool get done => value >= target;
  double get fraction => target <= 0 ? 0 : (value / target).clamp(0, 1);
}

/// Spočítá stav týdenního cíle. [proteinDays] = počet dní tohoto týdne
/// s trefeným cílem bílkovin.
FocusProgress focusProgress(
  WeekFocus focus, {
  required Iterable<Workout> workouts,
  required DateTime now,
  required ExerciseType Function(String id) typeOf,
  required String Function(String id) nameOf,
  required int weekGoal,
  int proteinDays = 0,
}) {
  final monday = focus.week;
  final end = nextWeek(monday);
  bool inWeek(Workout w) {
    final at = w.date.toLocal();
    return w.finished && !at.isBefore(monday) && at.isBefore(end);
  }

  final today = dayStart(now);
  // Kalendářní dny, ne hodiny: přechod na letní čas nic neposune.
  final left = DateTime.utc(end.year, end.month, end.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays
      .clamp(0, 7);
  switch (focus.kind) {
    case FocusKind.strength:
      final id = focus.exerciseId!;
      final history = exerciseHistory(workouts, id);
      final before = history.where((s) => s.date.toLocal().isBefore(monday));
      final baseline = before.fold(0.0, (m, s) {
        final b = _bestE1rm(s);
        return b > m ? b : m;
      });
      final week = history.where((s) => inWeek(s.workout));
      final value = week.fold(0.0, (m, s) {
        final b = _bestE1rm(s);
        return b > m ? b : m;
      });
      final name = nameOf(id);
      if (baseline <= 0) {
        // Bez dřívějšího měření se cíl odvodí z prvního: je co překonat.
        return FocusProgress(
          value,
          value > 0 ? (value * 1.025 * 2).ceil() / 2 : 1,
          'kg 1RM',
          value > 0
              ? tr(
                  'První měření v cviku $name je zapsané. Příští týden ho překonáš.',
                  'The first measurement for $name is logged. Beat it next week.',
                )
              : tr(
                  'Zacvič $name a zapiš série, ať je od čeho se odrazit.',
                  'Train $name and log your sets so there is a baseline.',
                ),
        );
      }
      // Cíl +2,5 %: v týdnu reálné, a přesto je potřeba zabrat.
      final target = (baseline * 1.025 * 2).ceil() / 2;
      return FocusProgress(
        value,
        target,
        'kg 1RM',
        value >= target
            ? tr(
                'Cíl v cviku $name splněný. Takhle se roste.',
                'Goal for $name reached. This is how you grow.',
              )
            : value > 0
            ? tr(
                'Do cíle chybí ${_kg(target - value)} kg odhadu maxima. '
                    'Příště přidej opakování nebo malý kotouč.',
                'You are ${_kg(target - value)} kg short of the estimated max. '
                    'Add a rep or a small plate next time.',
              )
            : tr(
                'Tento týden jdeš po síle v cviku $name. '
                    'Cíl je ${_kg(target)} kg odhadu maxima.',
                'This week you are going for strength in $name. '
                    'The goal is ${_kg(target)} kg estimated max.',
              ),
      );
    case FocusKind.consistency:
      final done = workouts.where(inWeek).length;
      final missing = weekGoal - done;
      return FocusProgress(
        done.toDouble(),
        weekGoal.toDouble(),
        tr('tréninky', 'workouts'),
        missing <= 0
            ? tr(
                'Všechny tréninky týdne hotové. Přesně tohle dělá výsledky.',
                'All workouts for the week are done. That is what gets results.',
              )
            : missing > left
            ? tr(
                'Zbývá ${_count(missing, 'trénink', 'tréninky', 'tréninků')} '
                    'a jen ${_count(left, 'den', 'dny', 'dní')}. Zvládni, co jde.',
                '${_count(missing, 'workout', 'workouts', 'workouts')} left '
                    'and only ${_count(left, 'day', 'days', 'days')}. Do what you can.',
              )
            : tr(
                'Zbývá ${_count(missing, 'trénink', 'tréninky', 'tréninků')}. '
                    'Nevynechej.',
                '${_count(missing, 'workout', 'workouts', 'workouts')} left. '
                    'Do not skip.',
              ),
      );
    case FocusKind.volume:
      int setsIn(DateTime from) {
        final to = nextWeek(from);
        var n = 0;
        for (final w in workouts) {
          final at = w.date.toLocal();
          if (!w.finished || at.isBefore(from) || !at.isBefore(to)) continue;
          for (final e in w.exercises) {
            n += e.countedSets.length;
          }
        }
        return n;
      }
      final last = setsIn(DateTime(monday.year, monday.month, monday.day - 7));
      final target = last == 0 ? 30 : (last * 1.1).ceil();
      final value = setsIn(monday);
      return FocusProgress(
        value.toDouble(),
        target.toDouble(),
        tr('sérií', 'sets'),
        value >= target
            ? tr(
                'Objem nad minulým týdnem. Hlídej spánek a jídlo.',
                'Volume above last week. Watch your sleep and food.',
              )
            : tr(
                'Ještě ${_count(target - value, 'série', 'série', 'sérií')} do cíle. '
                    'Přidej jednu sérii ke hlavním cvikům.',
                '${_count(target - value, 'set', 'sets', 'sets')} to go. '
                    'Add one set to the main lifts.',
              ),
      );
    case FocusKind.protein:
      const target = 5;
      final missing = target - proteinDays;
      return FocusProgress(
        proteinDays.toDouble(),
        target.toDouble(),
        tr('dní', 'days'),
        missing <= 0
            ? tr(
                'Bílkoviny trefené. Svaly mají z čeho růst.',
                'Protein goal hit. Your muscles have what they need to grow.',
              )
            : missing > left
            ? tr(
                'Na $target dní to tento týden nevyjde, ale každý trefený '
                    'den se počítá.',
                'You will not hit $target days this week, but every day '
                    'you hit still counts.',
              )
            : tr(
                'Ještě ${_count(missing, 'den', 'dny', 'dní')} s cílem '
                    'bílkovin. Zapisuj jídlo.',
                '${_count(missing, 'day', 'days', 'days')} more with your '
                    'protein goal. Keep logging food.',
              ),
      );
  }
}
