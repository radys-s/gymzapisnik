/// Trenér bez sítě: odpovědi poskládané z dat aplikace. Čistý Dart.
///
/// Odpovídá okamžitě na „co dnes cvičit“ (tam AI nic nepřidá a mýlila se)
/// a zastoupí AI, když je vypnutá nebo nedostupná. Stejná čísla jako
/// hlavní karta, takže si trenér a aplikace nikdy neodporují.
library;

import 'dart:math';

import '../core/i18n.dart';
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
  if (l.start != null) {
    load = tr('začni na ${l.start}', 'start at ${l.start}');
  } else if (s.weight > 0) {
    load = '${_kg(s.weight)} kg × ${s.reps}';
  } else if (!l.weighted) {
    load = tr('$range opakování', '$range reps');
  } else {
    load = tr('váhu na $range opakování', 'weight for $range reps');
  }
  return '• ${l.name} ${l.sets}×$range · $load';
}

String _times(int n) => switch (n) {
  1 => tr('1 trénink', '1 workout'),
  2 || 3 || 4 => tr('$n tréninky', '$n workouts'),
  _ => tr('$n tréninků', '$n workouts'),
};

String _dayLabel(CoachFacts f) => f.dayCount > 1
    ? tr(
        '${f.day} (den ${f.dayNumber} z ${f.dayCount})',
        '${f.day} (day ${f.dayNumber} of ${f.dayCount})',
      )
    : '${f.day}';

/// Odpověď na „co mám dnes cvičit“.
String todayAnswer(CoachFacts f) {
  final m = f.mission;
  if (f.activeWorkout) {
    return tr(
      'Máš rozepsaný trénink. Dokonči ho, pak spolu projdeme, '
          'jak šel.',
      'You have a workout in progress. Finish it, then we will go through '
          'how it went.',
    );
  }
  if (f.day == null) {
    return tr(
      'Zatím nemáš zvolený program. Otevři Program a vyber si ho, '
          'nebo si sestav trénink z partií, které jsou odpočaté'
          '${f.ready.isEmpty ? '' : ' (${f.ready.take(3).join(', ')})'}.',
      'You have not chosen a program yet. Open Program and pick one, '
          'or build a workout from the muscle groups that are recovered'
          '${f.ready.isEmpty ? '' : ' (${f.ready.take(3).join(', ')})'}.',
    );
  }
  final plan = [for (final l in f.plan) _line(l)].join('\n');
  final head = switch (m.kind) {
    MissionKind.doneToday => tr(
      'Dnes máš odcvičeno, dobrá práce. Příště je na řadě ${_dayLabel(f)}:',
      'You have trained today, good work. Next up is ${_dayLabel(f)}:',
    ),
    MissionKind.weekDone => tr(
      'Týdenní cíl máš splněný (${m.done} z ${m.goal}). Trénink navíc je '
          'bonus, na řadě je ${_dayLabel(f)}:',
      'You have hit your weekly goal (${m.done} of ${m.goal}). An extra '
          'workout is a bonus; next up is ${_dayLabel(f)}:',
    ),
    MissionKind.rest => tr(
      'Včera byl trénink, dnes je dobré dát svalům pauzu. Když chceš '
          'jít, na řadě je ${_dayLabel(f)}:',
      'You trained yesterday, so today is a good day to let your muscles '
          'rest. If you want to go, next up is ${_dayLabel(f)}:',
    ),
    MissionKind.plannedRest => tr(
      'Dnes máš podle plánu volno. Až půjdeš, na řadě je ${_dayLabel(f)}:',
      'Today is a planned rest day. When you train again, next up is '
          '${_dayLabel(f)}:',
    ),
    MissionKind.catchUp => tr(
      'Dnes je potřeba jít, jinak týdenní cíl nevyjde. Na řadě je '
          '${_dayLabel(f)}:',
      'You need to train today or you will miss your weekly goal. '
          'Next up is ${_dayLabel(f)}:',
    ),
    MissionKind.trainToday => tr(
      'Dnes je na řadě ${_dayLabel(f)}:',
      'Today is ${_dayLabel(f)}:',
    ),
  };
  final tail = f.tired.isEmpty
      ? ''
      : tr(
          '\nJeště se zotavuje: ${f.tired.take(3).join(', ')}. Když něco '
              'bolí, uber váhu.',
          '\nStill recovering: ${f.tired.take(3).join(', ')}. If something '
              'hurts, lower the weight.',
        );
  return '$head\n$plan$tail';
}

/// Odpověď na „kde stagnuju“.
String stallAnswer(CoachFacts f) {
  if (f.stalls.isEmpty) {
    return tr(
      'Ve zapsaných trénincích stagnaci nevidím: hlavní cviky se '
          'posouvají nebo jich je zatím málo na srovnání. Zapisuj každou '
          'sérii a po 3 trénincích stejného cviku ti řeknu víc.',
      'I do not see a plateau in your logged workouts: your main lifts are '
          'moving up, or there are not enough of them yet to compare. Log '
          'every set and after 3 workouts of the same exercise I can tell you '
          'more.',
    );
  }
  final lines = [
    for (final s in f.stalls.take(3))
      tr(
        '• ${s.name}: držíš ${_kg(s.kg)} kg × ${s.reps}',
        '• ${s.name}: stuck at ${_kg(s.kg)} kg × ${s.reps}',
      ),
  ].join('\n');
  return tr(
    'Tady se poslední tréninky nehnuly:\n$lines\n'
        'Zkus jeden trénink s váhou o 10 % nižší a plnými opakováními, pak '
        'se vrať a přidávej po opakováních. Pomáhá i spánek a dost bílkovin.',
    'Your last workouts have not moved here:\n$lines\n'
        'Try one workout with 10 % less weight and full reps, then come back '
        'and build up by reps. Sleep and enough protein help too.',
  );
}

/// Odpověď na „kolik sérií týdně dávám“.
String volumeAnswer(CoachFacts f) {
  if (f.hardSets.isEmpty) {
    return tr(
      'Za posledních 7 dní nemáš zapsanou žádnou pracovní sérii. Pro '
          'růst stačí zhruba 10 až 20 těžkých sérií na partii týdně.',
      'You have no working sets logged in the last 7 days. For growth, '
          'about 10 to 20 hard sets per muscle group per week is enough.',
    );
  }
  final sorted = f.hardSets.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final lines = [for (final e in sorted.take(6)) '• ${e.key}: ${e.value}']
      .join('\n');
  final low = [
    for (final e in sorted)
      if (e.value < 10) e.key,
  ];
  return tr(
    'Těžké série za posledních 7 dní:\n$lines\n'
        'Cíl pro růst je zhruba 10 až 20 na partii týdně.'
        '${low.isEmpty ? '' : ' Málo zatím: ${low.take(3).join(', ')}.'}',
    'Hard sets in the last 7 days:\n$lines\n'
        'The goal for growth is about 10 to 20 per muscle group per week.'
        '${low.isEmpty ? '' : ' Low so far: ${low.take(3).join(', ')}.'}',
  );
}

/// Odpověď na „jak rozložit tréninky do konce týdne“.
String weekAnswer(CoachFacts f) {
  final m = f.mission;
  if (m.remaining == 0) {
    return tr(
      'Tento týden máš hotovo: ${m.done} z ${m.goal}. Zbytek týdne '
          'odpočívej, nebo dej lehký trénink navíc.',
      'You are done for this week: ${m.done} of ${m.goal}. Rest for the rest '
          'of the week, or do an extra light workout.',
    );
  }
  final days = f.trainingDaysLeft.isEmpty
      ? ''
      : tr(
          ' Tvoje dny do neděle: ${f.trainingDaysLeft.join(', ')}.',
          ' Your days until Sunday: ${f.trainingDaysLeft.join(', ')}.',
        );
  final tight = m.remaining >= m.daysLeft
      ? tr(
          ' Musíš jít každý zbývající den, klidně kratší tréninky.',
          ' You need to go every remaining day, even short workouts are fine.',
        )
      : tr(
          ' Mezi tréninky na stejné partie nech aspoň den volna.',
          ' Leave at least one day off between workouts for the same muscle '
              'group.',
        );
  return tr(
    'Tento týden máš ${m.done} z ${m.goal}. Zbývá ${_times(m.remaining)} '
        'a ${m.daysLeft == 1 ? 'dnešek' : '${m.daysLeft} dní včetně dneška'}.'
        '$days$tight',
    'This week you have ${m.done} of ${m.goal}. '
        '${_times(m.remaining)} left and '
        '${m.daysLeft == 1 ? 'today' : '${m.daysLeft} days including today'}.'
        '$days$tight',
  );
}

String get _substitute => tr(
  'Při bolesti kolene nejdřív ať se na to podívá lékař nebo fyzioterapeut. '
      'Do té doby zkus cviky, které koleno tolik neohýbají:\n'
      '• hip thrust nebo glute bridge\n'
      '• rumunský mrtvý tah\n'
      '• leg press v menším rozsahu, jen bez bolesti\n'
      'Když cvik bolí, přestaň.',
  'If your knee hurts, have a doctor or physiotherapist look at it first. '
      'Until then, try exercises that do not bend the knee as much:\n'
      '• hip thrust or glute bridge\n'
      '• Romanian deadlift\n'
      '• leg press through a smaller range, only if pain free\n'
      'If an exercise hurts, stop.',
);

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
      ? tr('Dobré ráno.', 'Good morning.')
      : h < 18
      ? tr('Ahoj.', 'Hello.')
      : tr('Dobrý večer.', 'Good evening.');
  final m = f.mission;
  final today = f.activeWorkout
      ? tr('Máš rozepsaný trénink.', 'You have a workout in progress.')
      : f.day == null
      ? tr(
          'Zatím nemáš program, pomůžu ti ho vybrat.',
          'You have no program yet, I will help you pick one.',
        )
      : switch (m.kind) {
          MissionKind.doneToday => tr(
            'Dnes máš odcvičeno.',
            'You have trained today.',
          ),
          MissionKind.plannedRest || MissionKind.rest => tr(
            'Dnes je den volna, příště ${f.day}.',
            'Today is a rest day, next up ${f.day}.',
          ),
          MissionKind.weekDone => tr(
            'Týden máš splněný, příště ${f.day}.',
            'You have hit your weekly goal, next up ${f.day}.',
          ),
          _ => tr(
            'Dnes je na řadě ${f.day}, ${f.plan.length} '
                '${f.plan.length == 1
                    ? 'cvik'
                    : f.plan.length < 5
                    ? 'cviky'
                    : 'cviků'}.',
            'Today is ${f.day}, ${f.plan.length} '
                '${f.plan.length == 1 ? 'exercise' : 'exercises'}.',
          ),
        };
  final week = tr(
    'Týden: ${m.done} z ${m.goal}.',
    'Week: ${m.done} of ${m.goal}.',
  );
  final rec = f.ready.isEmpty
      ? ''
      : tr(
          ' Odpočaté: ${f.ready.take(3).join(', ')}.',
          ' Recovered: ${f.ready.take(3).join(', ')}.',
        );
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
