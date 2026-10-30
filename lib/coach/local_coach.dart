/// Trenér bez sítě: odpovědi poskládané z dat aplikace. Čistý Dart.
///
/// Odpovídá okamžitě na „co dnes cvičit“ (tam AI nic nepřidá a mýlila se)
/// a zastoupí AI, když je vypnutá nebo nedostupná. Stejná čísla jako
/// hlavní karta, takže si trenér a aplikace nikdy neodporují.
library;

import 'dart:math';

import '../domain/history.dart';
import '../domain/models.dart';
import '../domain/stats.dart';
import 'missions.dart';
import 'progression.dart';

/// O čem otázka je (podle klíčových slov, bez AI).
enum CoachIntent { today, stall, substitute, volume, week, other }

String _fold(String s) {
  const from = 'áčďéěíňóřšťúůýž';
  const to = 'acdeeinorstuuyz';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = from.indexOf(c);
    b.write(i < 0 ? c : to[i]);
  }
  return b.toString();
}

CoachIntent classifyQuestion(String question) {
  final q = _fold(question);
  bool any(List<String> words) => words.any(q.contains);
  // Místní náhrada umí jen koleno; jiné bolesti řeší AI.
  if (q.contains('kolen') && any(['nahrad', 'misto', 'boli', 'bolest'])) {
    return CoachIntent.substitute;
  }
  if (any(['stagn', 'zasek', 'neroste', 'nepostup', 'plato'])) {
    return CoachIntent.stall;
  }
  if (any(['kolik seri', 'serii tydne', 'objem', 'na partii'])) {
    return CoachIntent.volume;
  }
  // Jen otázky na dnešní plán, ne cokoli se slovem „dnes“ (jídlo, bolest).
  if (any([
    'co mam dnes',
    'co mam dneska',
    'co dnes cvicit',
    'co dneska cvicit',
    'dnes cvicit',
    'dneska cvicit',
    'co mam cvicit',
    'co cvicit',
    'ted cvicit',
    'dnesni trenink',
    'dnesni plan',
  ])) {
    return CoachIntent.today;
  }
  if (any(['do konce tydne', 'rozlozit', 'tyden', 'tydn'])) {
    return CoachIntent.week;
  }
  return CoachIntent.other;
}

/// Jeden cvik dnešního plánu.
class PlanLine {
  final String name;
  final int sets;
  final int repMin;
  final int repMax;
  final Suggestion suggestion;

  /// S činkou nebo na stroji (ne vlastní váha).
  final bool weighted;

  /// Popisek startovní váhy, když cvik dělá poprvé („prázdná osa 20 kg“).
  final String? start;

  const PlanLine({
    required this.name,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.suggestion,
    this.weighted = true,
    this.start,
  });
}

/// Cvik, kde se poslední tréninky nehnuly.
class Stall {
  final String name;
  final double kg;
  final int reps;
  const Stall(this.name, this.kg, this.reps);
}

/// Všechno, co trenér o uživateli ví. Skládá [AppState.coachFacts].
class CoachFacts {
  final Mission mission;
  final String? program;
  final String? day;
  final int dayNumber;
  final int dayCount;
  final List<PlanLine> plan;

  /// Partie → těžké série za posledních 7 dní.
  final Map<String, int> hardSets;
  final List<String> ready;
  final List<String> tired;
  final List<Stall> stalls;

  /// Zkratky dnů tréninku („po“, „st“) od dneška do neděle.
  final List<String> trainingDaysLeft;
  final int? daysSinceLast;
  final bool activeWorkout;

  const CoachFacts({
    required this.mission,
    this.program,
    this.day,
    this.dayNumber = 1,
    this.dayCount = 1,
    this.plan = const [],
    this.hardSets = const {},
    this.ready = const [],
    this.tired = const [],
    this.stalls = const [],
    this.trainingDaysLeft = const [],
    this.daysSinceLast,
    this.activeWorkout = false,
  });

  /// Dnes má smysl nabídnout start tréninku.
  bool get canStart => day != null && !activeWorkout;
}

String _kg(double v) {
  final t = v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return t.replaceAll('.', ',');
}

String _line(PlanLine l) {
  final range = l.repMin == l.repMax
      ? '${l.repMin}'
      : '${l.repMin}–${l.repMax}';
  final s = l.suggestion;
  final String load;
  if (s.weight > 0) {
    load = '${_kg(s.weight)} kg × ${s.reps}';
  } else if (!l.weighted) {
    load = '$range opakování';
  } else if (l.start != null) {
    load = 'začni na ${l.start}';
  } else {
    load = 'váhu na $range opakování';
  }
  return '• ${l.name} ${l.sets}×$range · $load';
}

String _times(int n) => switch (n) {
  1 => '1 trénink',
  2 || 3 || 4 => '$n tréninky',
  _ => '$n tréninků',
};

String _dayLabel(CoachFacts f) => f.dayCount > 1
    ? '${f.day} (den ${f.dayNumber} z ${f.dayCount})'
    : '${f.day}';

/// Odpověď na „co mám dnes cvičit“.
String todayAnswer(CoachFacts f) {
  final m = f.mission;
  if (f.activeWorkout) {
    return 'Máš rozepsaný trénink. Dokonči ho, pak spolu projdeme, '
        'jak šel.';
  }
  if (f.day == null) {
    return 'Zatím nemáš zvolený program. Otevři Program a vyber si ho, '
        'nebo si sestav trénink z partií, které jsou odpočaté'
        '${f.ready.isEmpty ? '' : ' (${f.ready.take(3).join(', ')})'}.';
  }
  final plan = [for (final l in f.plan) _line(l)].join('\n');
  final head = switch (m.kind) {
    MissionKind.doneToday =>
      'Dnes máš odcvičeno, dobrá práce. Příště je na řadě ${_dayLabel(f)}:',
    MissionKind.weekDone =>
      'Týdenní cíl máš splněný (${m.done} z ${m.goal}). Trénink navíc je '
          'bonus, na řadě je ${_dayLabel(f)}:',
    MissionKind.rest =>
      'Včera byl trénink, dnes je dobré dát svalům pauzu. Když chceš '
          'jít, na řadě je ${_dayLabel(f)}:',
    MissionKind.plannedRest =>
      'Dnes máš podle plánu volno. Až půjdeš, na řadě je ${_dayLabel(f)}:',
    MissionKind.catchUp =>
      'Dnes je potřeba jít, jinak týdenní cíl nevyjde. Na řadě je '
          '${_dayLabel(f)}:',
    MissionKind.trainToday => 'Dnes je na řadě ${_dayLabel(f)}:',
  };
  final tail = f.tired.isEmpty
      ? ''
      : '\nJeště se zotavuje: ${f.tired.take(3).join(', ')}. Když něco '
            'bolí, uber váhu.';
  return '$head\n$plan$tail';
}

/// Odpověď na „kde stagnuju“.
String stallAnswer(CoachFacts f) {
  if (f.stalls.isEmpty) {
    return 'Ve zapsaných trénincích stagnaci nevidím: hlavní cviky se '
        'posouvají nebo jich je zatím málo na srovnání. Zapisuj každou '
        'sérii a po 3 trénincích stejného cviku ti řeknu víc.';
  }
  final lines = [
    for (final s in f.stalls.take(3))
      '• ${s.name}: držíš ${_kg(s.kg)} kg × ${s.reps}',
  ].join('\n');
  return 'Tady se poslední tréninky nehnuly:\n$lines\n'
      'Zkus jeden trénink s váhou o 10 % nižší a plnými opakováními, pak '
      'se vrať a přidávej po opakováních. Pomáhá i spánek a dost bílkovin.';
}

/// Odpověď na „kolik sérií týdně dávám“.
String volumeAnswer(CoachFacts f) {
  if (f.hardSets.isEmpty) {
    return 'Za posledních 7 dní nemáš zapsanou žádnou pracovní sérii. Pro '
        'růst stačí zhruba 10 až 20 těžkých sérií na partii týdně.';
  }
  final sorted = f.hardSets.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final lines = [for (final e in sorted.take(6)) '• ${e.key}: ${e.value}']
      .join('\n');
  final low = [
    for (final e in sorted)
      if (e.value < 10) e.key,
  ];
  return 'Těžké série za posledních 7 dní:\n$lines\n'
      'Cíl pro růst je zhruba 10 až 20 na partii týdně.'
      '${low.isEmpty ? '' : ' Málo zatím: ${low.take(3).join(', ')}.'}';
}

/// Odpověď na „jak rozložit tréninky do konce týdne“.
String weekAnswer(CoachFacts f) {
  final m = f.mission;
  if (m.remaining == 0) {
    return 'Tento týden máš hotovo: ${m.done} z ${m.goal}. Zbytek týdne '
        'odpočívej, nebo dej lehký trénink navíc.';
  }
  final days = f.trainingDaysLeft.isEmpty
      ? ''
      : ' Tvoje dny do neděle: ${f.trainingDaysLeft.join(', ')}.';
  final tight = m.remaining >= m.daysLeft
      ? ' Musíš jít každý zbývající den, klidně kratší tréninky.'
      : ' Mezi tréninky na stejné partie nech aspoň den volna.';
  return 'Tento týden máš ${m.done} z ${m.goal}. Zbývá ${_times(m.remaining)} '
      'a ${m.daysLeft == 1 ? 'dnešek' : '${m.daysLeft} dní včetně dneška'}.'
      '$days$tight';
}

const _substitute =
    'Při bolesti kolene nejdřív ať se na to podívá lékař nebo fyzioterapeut. '
    'Do té doby zkus cviky, které koleno tolik neohýbají:\n'
    '• hip thrust nebo glute bridge\n'
    '• rumunský mrtvý tah\n'
    '• leg press v menším rozsahu, jen bez bolesti\n'
    'Když cvik bolí, přestaň.';

/// Místní odpověď, nebo `null`, když na otázku data nestačí.
String? localAnswer(CoachIntent intent, CoachFacts f) => switch (intent) {
  CoachIntent.today => todayAnswer(f),
  CoachIntent.stall => stallAnswer(f),
  CoachIntent.volume => volumeAnswer(f),
  CoachIntent.week => weekAnswer(f),
  CoachIntent.substitute => _substitute,
  CoachIntent.other => null,
};

/// Úvodní zpráva trenéra, když chat začíná.
String briefing(CoachFacts f, DateTime now) {
  final h = now.hour;
  final hello = h < 10
      ? 'Dobré ráno.'
      : h < 18
      ? 'Ahoj.'
      : 'Dobrý večer.';
  final m = f.mission;
  final today = f.activeWorkout
      ? 'Máš rozepsaný trénink.'
      : f.day == null
      ? 'Zatím nemáš program, pomůžu ti ho vybrat.'
      : switch (m.kind) {
          MissionKind.doneToday => 'Dnes máš odcvičeno.',
          MissionKind.plannedRest ||
          MissionKind.rest => 'Dnes je den volna, příště ${f.day}.',
          MissionKind.weekDone => 'Týden máš splněný, příště ${f.day}.',
          _ =>
            'Dnes je na řadě ${f.day}, ${f.plan.length} '
                '${f.plan.length == 1
                    ? 'cvik'
                    : f.plan.length < 5
                    ? 'cviky'
                    : 'cviků'}.',
        };
  final week = 'Týden: ${m.done} z ${m.goal}.';
  final rec = f.ready.isEmpty
      ? ''
      : ' Odpočaté: ${f.ready.take(3).join(', ')}.';
  return '$hello $today $week$rec';
}

/// Odpověď AI bez markdownu: hvězdičky pryč, odrážky jako „• “.
String tidyReply(String reply) {
  final lines = [
    for (final raw in reply.replaceAll('\r', '').split('\n'))
      raw
          .replaceAll('**', '')
          .replaceAll('__', '')
          // Číslované řádky („3. série“, „30. října“) zůstávají.
          .replaceFirstMapped(RegExp(r'^(\s*)[-*+]\s+'), (m) => '${m[1]}• ')
          .replaceFirst(RegExp(r'^#{1,6}\s+'), ''),
  ];
  return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Cviky (za 8 týdnů aspoň 3×), kde poslední trénink nepřekonal žádný
/// ze dvou předchozích. [name] vrací zobrazovaný název cviku.
List<Stall> findStalls(
  Iterable<Workout> workouts,
  DateTime now,
  ExerciseType Function(String id) typeOf,
  String Function(String id) name,
) {
  final since = now.subtract(const Duration(days: 56));
  final ids = <String>{
    for (final w in workouts)
      if (w.finished && !w.date.isBefore(since))
        for (final e in w.exercises)
          if (e.countedSets.isNotEmpty) e.exerciseId,
  };
  final out = <Stall>[];
  for (final id in ids) {
    final type = typeOf(id);
    if (type != ExerciseType.weighted) continue;
    final best = [
      for (final s in exerciseHistory(workouts, id))
        if (!s.date.isBefore(since)) ?bestSet(type, s.entry.countedSets),
    ];
    if (best.length < 3) continue;
    final last = best.last;
    final prev = best.sublist(best.length - 3, best.length - 1);
    final top = prev.map((b) => e1rm(b.weight, b.reps)).reduce(max);
    if (e1rm(last.weight, last.reps) <= top + 0.01) {
      out.add(Stall(name(id), last.weight, last.reps));
    }
  }
  return out;
}
