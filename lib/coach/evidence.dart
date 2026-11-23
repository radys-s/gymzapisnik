/// Research behind the science-based plans: why an exercise is chosen and
/// the principles the plan follows. Short claims in our own words, each
/// with the study it rests on. Pure Dart.
library;

import '../core/i18n.dart';

class Evidence {
  final String cs;
  final String en;

  /// Authors, year, journal.
  final String source;
  const Evidence(this.cs, this.en, this.source);

  String get text => tr(cs, en);
}

const _overhead = Evidence(
  'S pažemi nad hlavou je dlouhá hlava tricepsu protažená. V pokusu '
      'rostl triceps výrazně víc než při stahování kladky s pažemi u těla.',
  'With the arms overhead the long head of the triceps is stretched. In a '
      'trial the triceps grew clearly more than with pushdowns at the side.',
  'Maeo et al., 2023, European Journal of Sport Science',
);

const _seatedCurl = Evidence(
  'V sedě je hamstring protažený přes kyčel. Zákopy vsedě přinesly '
      'větší růst hamstringů než zákopy vleže.',
  'Seated, the hamstrings are stretched at the hip. Seated leg curls grew '
      'the hamstrings more than lying leg curls.',
  'Maeo et al., 2021, Medicine & Science in Sports & Exercise',
);

const _lengthened = Evidence(
  'Zátěž v protažené poloze svalu vede k podobnému nebo většímu růstu '
      'než v zkrácené. Proto cvik s plným rozsahem a pomalým spouštěním.',
  'Load at long muscle lengths gives similar or more growth than at short '
      'lengths. Hence full range of motion and a slow lowering phase.',
  'Wolf et al., 2023, International Journal of Strength and Conditioning',
);

/// Exercises of the science-based plans and why they are there.
const exerciseEvidence = <String, Evidence>{
  'overhead_triceps_extension': _overhead,
  'overhead_rope_extension': _overhead,
  'dumbbell_overhead_extension': _overhead,
  'seated_dumbbell_triceps_extension': _overhead,
  'seated_leg_curl': _seatedCurl,
  'leg_extension': Evidence(
    'Extenze v hlubší, protažené části pohybu přinesly větší růst '
        'stehen než v horní části.',
    'Leg extensions in the deeper, stretched part of the range grew the '
        'quads more than in the top part.',
    'Pedrosa et al., 2022, European Journal of Sport Science',
  ),
  'squat': Evidence(
    'Hluboký dřep zvětšil hýždě a přitahovače víc než poloviční.',
    'Deep squats grew the glutes and adductors more than half squats.',
    'Kubo et al., 2019, European Journal of Applied Physiology',
  ),
  'calf_raise': Evidence(
    'Lýtka rostla nejvíc při práci ve spodní, protažené části pohybu. '
        'Dole vždy krátce zastav.',
    'Calves grew most when working the bottom, stretched part of the '
        'range. Pause briefly at the bottom.',
    'Kassiano et al., 2023, Journal of Strength and Conditioning Research',
  ),
  'romanian_deadlift': _lengthened,
  'incline_dumbbell_curl': _lengthened,
  'bayesian_curl': _lengthened,
  'incline_dumbbell_press': _lengthened,
  'cable_fly': _lengthened,
  'cable_lateral_raise': _lengthened,
};

Evidence? evidenceFor(String exerciseId) => exerciseEvidence[exerciseId];

/// Principles the science-based plans follow.
const planPrinciples = <Evidence>[
  Evidence(
    'Každý sval aspoň 2× týdně. Častější trénink rozloží objem a vychází '
        'líp než jednou týdně.',
    'Every muscle at least twice a week. Spreading the volume beats '
        'training it once a week.',
    'Schoenfeld, Ogborn & Krieger, 2016, Sports Medicine',
  ),
  Evidence(
    'Zhruba 10–20 těžkých sérií na sval týdně. Víc sérií roste se svaly, '
        'ale s klesajícím přínosem.',
    'Roughly 10–20 hard sets per muscle a week. More sets mean more growth, '
        'with diminishing returns.',
    'Schoenfeld, Ogborn & Krieger, 2017, Journal of Sports Sciences',
  ),
  Evidence(
    'Série končí 0–2 opakování před selháním. Blízkost selhání je '
        'důležitější než konkrétní váha.',
    'Sets end 0–2 reps short of failure. Closeness to failure matters more '
        'than the exact weight.',
    'Robinson et al., 2024, Sports Medicine',
  ),
];
