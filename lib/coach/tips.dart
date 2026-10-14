/// Krátké rady a motivační věty pro načítací obrazovku a týdenní objem
/// podle partií. Čistý Dart bez Flutteru. Texty jsou vlastní, bez citátů.
library;

import '../domain/anatomy.dart';
import '../domain/models.dart';
import 'splits.dart';

class Tip {
  /// Nadpis nad textem („Rada“ / „Motivace“).
  final String kind;
  final String text;
  const Tip(this.kind, this.text);
}

const trainingTips = <String>[
  'Každou partii procvič aspoň 2× týdně. Obvykle to funguje líp než '
      'jeden velký trénink.',
  'Většině lidí stačí 10–20 těžkých sérií na partii za týden. Začni u '
      'spodní hranice.',
  'Pracovní série ukonči 0–3 opakování před selháním. Lehké série svaly '
      'nerozhýbou.',
  'Svaly rostou při 6 i 30 opakováních, když jdeš blízko selhání. Vyber, '
      'co ti sedí.',
  'Nejdřív přidej opakování, pak váhu. Tak funguje postupné přetížení.',
  'U těžkých cviků si dej pauzu 2–3 minuty. Další série bude silnější.',
  'Plný rozsah pohybu, hlavně v protažení svalu, buduje víc než '
      'polovičatá opakování.',
  'Spi 7–9 hodin. Sval roste při odpočinku, ne při tréninku.',
  'Když se výkon několik týdnů nehýbe, dej si lehčí týden a pak pokračuj.',
  'Spouštěj váhu pod kontrolou, zhruba 2–3 sekundy dolů.',
  'Před první těžkou sérií dej 2–3 lehčí rozcvičovací.',
  'Mysli na všechny hlavy svalu: triceps nad hlavou, biceps na šikmé '
      'lavici, boční delt zvlášť.',
  'Těžké vícekloubové cviky dej na začátek tréninku, dokud máš sílu.',
  'Zapisuj každou sérii. Co měříš, to můžeš zlepšovat.',
];

/// Rady jen pro dospělé (dávkování bílkovin).
const adultTips = <String>[
  'Bílkoviny zhruba 1,6–2,2 g na kilo tělesné váhy denně, rozdělené do '
      '3–5 jídel.',
];

const motivationLines = <String>[
  'Nemusíš mít motivaci. Stačí přijít.',
  'Nejlepší trénink je ten, který odcvičíš.',
  'Pravidelnost porazí jeden hrdinský trénink.',
  'Tvůj soupeř je tvoje minulá série.',
  'Půl kila navíc každý týden je za rok úplně jiná váha.',
  'Disciplína je rozhodnutí, ne pocit.',
  'Malé kroky, každý týden. Tak vypadá pokrok.',
  'Dnešní série ti už nikdo nevezme.',
  'Únava přejde. Odcvičený trénink zůstane.',
  'Začni lehce, ale začni.',
];

/// Rada nebo motivační věta podle čísla (např. náhodného). Mladší než 18
/// nedostanou rady s dávkováním jídla.
Tip tipAt(int n, {bool adult = false}) {
  final tips = [...trainingTips, if (adult) ...adultTips];
  final total = tips.length + motivationLines.length;
  final i = n.abs() % total;
  return i < tips.length
      ? Tip('Rada', tips[i])
      : Tip('Motivace', motivationLines[i - tips.length]);
}

/// Doporučený počet těžkých sérií na partii za týden.
const weeklySetsMin = 10;
const weeklySetsMax = 20;

/// Partie, kam patří hlava svalu (`focusHeads` ze splits).
String? focusOfHead(String headId) {
  for (final entry in focusHeads.entries) {
    if (entry.value.contains(headId)) return entry.key;
  }
  return null;
}

/// Partie pro vlastní cvik podle jeho skupiny v katalogu. U „Paže“ nejde
/// poznat biceps od tricepsu, takže se nepočítá.
const _groupFocus = {
  'Hrudník': 'chest',
  'Záda': 'back',
  'Nohy': 'legs',
  'Ramena': 'shoulders',
  'Střed těla': 'core',
};

/// Těžké (pracovní, potvrzené) série za posledních 7 dní podle partie.
/// Série se počítá jednou, partii hlavní hlavy cviku (mrtvý tah = záda),
/// aby se týdenní součet nenafukoval.
Map<String, int> weeklyHardSets(
  Iterable<Workout> workouts,
  DateTime now,
  String Function(String exerciseId) muscleOf,
) {
  final from = now.subtract(const Duration(days: 7));
  final result = <String, int>{};
  for (final w in workouts) {
    if (!w.finished || w.date.isBefore(from) || w.date.isAfter(now)) continue;
    for (final e in w.exercises) {
      final sets = e.sets.where((s) => s.done && !s.warmup).length;
      if (sets == 0) continue;
      final anatomy = anatomyOf(e.exerciseId);
      final focus = anatomy == null
          ? _groupFocus[muscleOf(e.exerciseId)]
          : focusOfHead(anatomy.primary.first);
      if (focus == null) continue;
      result[focus] = (result[focus] ?? 0) + sets;
    }
  }
  return result;
}
