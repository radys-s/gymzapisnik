/// Short tips and motivation lines for loading screens and weekly muscle-group
/// volume. Pure Dart without Flutter. Original texts, no quotes.
library;

import '../core/i18n.dart';
import '../domain/anatomy.dart';
import '../domain/models.dart';
import 'splits.dart';

class Tip {
  /// Heading above the text ("Tip" / "Motivation").
  final String kind;
  final String text;
  const Tip(this.kind, this.text);
}

List<String> trainingTips() => [
  tr(
    'Každou partii procvič aspoň 2× týdně. Obvykle to funguje líp než '
        'jeden velký trénink.',
    'Train each muscle group at least twice a week. It usually works better '
        'than one big session.',
  ),
  tr(
    'Většině lidí stačí 10–20 těžkých sérií na partii za týden. Začni u '
        'spodní hranice.',
    'Most people do well with 10–20 hard sets per muscle group per week. '
        'Start at the lower end.',
  ),
  tr(
    'Pracovní série ukonči 0–3 opakování před selháním. Lehké série svaly '
        'nerozhýbou.',
    'End working sets 0–3 reps before failure. Easy sets won\'t move the '
        'needle much.',
  ),
  tr(
    'Svaly rostou při 6 i 30 opakováních, když jdeš blízko selhání. Vyber, '
        'co ti sedí.',
    'Muscles grow with 6 reps or 30, as long as you get close to failure. '
        'Pick what fits you.',
  ),
  tr(
    'Nejdřív přidej opakování, pak váhu. Tak funguje postupné přetížení.',
    'Add reps first, then weight. That\'s progressive overload in practice.',
  ),
  tr(
    'U těžkých cviků si dej pauzu 2–3 minuty. Další série bude silnější.',
    'Rest 2–3 minutes on heavy lifts. Your next set will be stronger.',
  ),
  tr(
    'Plný rozsah pohybu, hlavně v protažení svalu, buduje víc než '
        'polovičatá opakování.',
    'A full range of motion, especially in the stretched position, builds '
        'more than half reps.',
  ),
  tr(
    'Spi 7–9 hodin. Sval roste při odpočinku, ne při tréninku.',
    'Sleep 7–9 hours. Muscle grows during recovery, not during the workout.',
  ),
  tr(
    'Když se výkon několik týdnů nehýbe, dej si lehčí týden a pak pokračuj.',
    'If performance stalls for a few weeks, take a lighter week and then '
        'push again.',
  ),
  tr(
    'Spouštěj váhu pod kontrolou, zhruba 2–3 sekundy dolů.',
    'Lower the weight under control, roughly 2–3 seconds down.',
  ),
  tr(
    'Před první těžkou sérií dej 2–3 lehčí rozcvičovací.',
    'Do 2–3 lighter warm-up sets before your first heavy set.',
  ),
  tr(
    'Mysli na všechny hlavy svalu: triceps nad hlavou, biceps na šikmé '
        'lavici, boční delt zvlášť.',
    'Hit every head of a muscle: overhead for triceps, incline for biceps, '
        'side delt on its own.',
  ),
  tr(
    'Těžké vícekloubové cviky dej na začátek tréninku, dokud máš sílu.',
    'Put heavy compound lifts at the start of the workout while you\'re fresh.',
  ),
  tr(
    'Zapisuj každou sérii. Co měříš, to můžeš zlepšovat.',
    'Log every set. What you measure, you can improve.',
  ),
];

/// Tips only for adults (protein dosing).
List<String> adultTips() => [
  tr(
    'Bílkoviny zhruba 1,6–2,2 g na kilo tělesné váhy denně, rozdělené do '
        '3–5 jídel.',
    'Aim for roughly 1.6–2.2 g of protein per kg of body weight daily, split '
        'across 3–5 meals.',
  ),
];

List<String> motivationLines() => [
  tr(
    'Nemusíš mít motivaci. Stačí přijít.',
    'You don\'t need motivation. Just show up.',
  ),
  tr(
    'Nejlepší trénink je ten, který odcvičíš.',
    'The best workout is the one you do.',
  ),
  tr(
    'Pravidelnost porazí jeden hrdinský trénink.',
    'Consistency beats one heroic workout.',
  ),
  tr('Tvůj soupeř je tvoje minulá série.', 'Your opponent is your last set.'),
  tr(
    'Půl kila navíc každý týden je za rok úplně jiná váha.',
    'Half a kilo more each week is a completely different weight in a year.',
  ),
  tr(
    'Disciplína je rozhodnutí, ne pocit.',
    'Discipline is a decision, not a feeling.',
  ),
  tr(
    'Malé kroky, každý týden. Tak vypadá pokrok.',
    'Small steps, every week. That\'s progress.',
  ),
  tr(
    'Dnešní série ti už nikdo nevezme.',
    'Nobody can take today\'s sets away from you.',
  ),
  tr(
    'Únava přejde. Odcvičený trénink zůstane.',
    'Fatigue fades. The workout stays done.',
  ),
  tr('Začni lehce, ale začni.', 'Start light, but start.'),
];

/// Tip or motivation line by number (e.g. random). Under-18 users do not get
/// food-dosing tips.
Tip tipAt(int n, {bool adult = false}) {
  final tips = [...trainingTips(), if (adult) ...adultTips()];
  final motivation = motivationLines();
  final total = tips.length + motivation.length;
  final i = n.abs() % total;
  return i < tips.length
      ? Tip(tr('Rada', 'Tip'), tips[i])
      : Tip(tr('Motivace', 'Motivation'), motivation[i - tips.length]);
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

/// Partie vlastního cviku podle jeho skupiny (`null` = nejde poznat).
String? focusOfMuscle(String muscle) => _groupFocus[muscle];

/// Těžké (pracovní, potvrzené) série za posledních [days] dní podle partie.
/// Série se počítá jednou, partii hlavní hlavy cviku (mrtvý tah = záda),
/// aby se týdenní součet nenafukoval.
Map<String, int> weeklyHardSets(
  Iterable<Workout> workouts,
  DateTime now,
  String Function(String exerciseId) muscleOf, {
  int days = 7,
}) {
  final from = now.subtract(Duration(days: days));
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
