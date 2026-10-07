/// Malá tabulka běžných potravin pro odhad maker v návrzích jídel.
///
/// Hodnoty jsou orientační, na 100 g (u tekutin na 100 ml, hustota ≈ 1).
/// Zdroj: USDA FoodData Central (SR Legacy, Foundation Foods) a typické
/// hodnoty z obalů běžných českých výrobků; zaokrouhleno. Sacharidy jsou
/// využitelné (bez vlákniny tam, kde ji zdroj uvádí zvlášť).
/// Neslouží k přesnému počítání: v aplikaci se vždy zobrazí jako odhad.
library;

import 'nutrition.dart';

class FoodRef {
  final String name;

  /// Kmeny bez diakritiky, malými písmeny. Shoda = kmen je v názvu.
  final List<String> stems;
  final double kcal, protein, carbs, fat;

  /// Typická hmotnost jednoho kusu v gramech (jen jedlá část).
  final double? piece;

  /// Koření a podobné: bez množství se počítá jako nula.
  final bool trivial;

  const FoodRef(
    this.name,
    this.stems,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat, {
    this.piece,
    this.trivial = false,
  });

  /// Hodnoty na 100 g.
  Nutrition get per100 =>
      Nutrition(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
}

const foodTable = <FoodRef>[
  // Maso, ryby, vejce
  FoodRef(
    'kuřecí prsa',
    ['kureci prs', 'kureci maso', 'kure', 'kuřecí'],
    110,
    23,
    0,
    1.5,
  ),
  FoodRef(
    'kuřecí stehna',
    ['kureci steh', 'stehna', 'stehno'],
    121,
    19.7,
    0,
    4.1,
  ),
  FoodRef('krůtí prsa', ['kruti', 'krocan'], 105, 23, 0, 1.2),
  FoodRef(
    'hovězí mleté',
    ['hovezi mlet', 'mlete hovezi', 'mlete maso'],
    254,
    17,
    0,
    20,
  ),
  FoodRef('hovězí maso', ['hovezi', 'steak', 'rostenec'], 150, 22, 0, 7),
  FoodRef('vepřové mleté', ['veprove mlet', 'mlete veprove'], 263, 17, 0, 21),
  FoodRef('vepřová panenka', ['panenk'], 120, 21, 0, 3.5),
  FoodRef('vepřové maso', ['veprov', 'kotlet', 'krkovic'], 172, 20, 0, 10),
  FoodRef('šunka', ['sunk'], 110, 19, 1.5, 3),
  FoodRef('kuřecí šunka', ['kureci sunk'], 100, 18, 2, 2),
  FoodRef('slanina', ['slanin', 'anglicak'], 400, 13, 1, 39),
  FoodRef('párky', ['park', 'klobas', 'vurt'], 270, 12, 2, 24, piece: 50),
  FoodRef('salám', ['salam'], 400, 20, 1, 35),
  FoodRef('losos', ['losos'], 208, 20, 0, 13),
  FoodRef('tuňák v konzervě', ['tunak'], 116, 26, 0, 1, piece: 120),
  FoodRef('treska', ['tresk', 'filet', 'pangas'], 82, 18, 0, 0.7),
  FoodRef('sardinky', ['sardin'], 210, 24, 0, 12, piece: 90),
  FoodRef('uzená makrela', ['makrel'], 300, 19, 0, 25),
  FoodRef('krabí tyčinky', ['krabi'], 95, 8, 14, 0.6, piece: 17),
  FoodRef(
    'vejce',
    ['vejc', 'vajic', 'vajec', 'vajick'],
    143,
    12.6,
    0.7,
    9.5,
    piece: 50,
  ),
  FoodRef('tofu', ['tofu'], 130, 14, 2, 7.5),
  // Mléčné
  FoodRef('tvaroh polotučný', ['tvaroh'], 110, 13, 3.5, 4.5),
  FoodRef(
    'tvaroh netučný',
    ['tvaroh netucn', 'tvaroh odtucn', 'nizkotucny tvaroh'],
    65,
    12,
    3.8,
    0.3,
  ),
  FoodRef('cottage', ['cottage', 'kottage'], 100, 12, 2.5, 4.5),
  FoodRef('skyr', ['skyr'], 63, 11, 4, 0.2),
  FoodRef(
    'řecký jogurt',
    ['recky jogurt', 'jogurt recky', 'recky'],
    97,
    9,
    4,
    5,
  ),
  FoodRef('bílý jogurt', ['jogurt'], 66, 4.5, 5, 3),
  FoodRef('kefír', ['kefir', 'acidofil', 'podmasl'], 55, 3.5, 4.5, 2.5),
  FoodRef('mléko polotučné', ['mlek'], 47, 3.4, 4.8, 1.5),
  FoodRef(
    'mléko plnotučné',
    ['plnotucne mlek', 'mleko plnotucn'],
    64,
    3.3,
    4.7,
    3.6,
  ),
  FoodRef('ovesné mléko', ['ovesne mlek', 'ovesny napoj'], 46, 0.5, 7, 1.5),
  FoodRef('sójové mléko', ['sojove mlek', 'sojovy napoj'], 40, 3.3, 2, 1.8),
  FoodRef(
    'sýr eidam',
    ['syr', 'eidam', 'gouda', 'edam', 'emental'],
    263,
    28,
    0,
    16.5,
  ),
  FoodRef('mozzarella', ['mozzarel', 'mozarel'], 245, 18, 1.5, 18, piece: 125),
  FoodRef('parmazán', ['parmaz', 'grana', 'parmigian'], 400, 33, 0, 29),
  FoodRef('balkánský sýr', ['balkan', 'feta', 'akawi'], 265, 15, 1, 22),
  FoodRef('tavený sýr', ['taveny', 'tavenak'], 240, 11, 6, 19),
  FoodRef(
    'smetanový sýr',
    ['zerve', 'lucin', 'philadelph', 'smetanovy syr', 'cream cheese'],
    250,
    6,
    4,
    24,
  ),
  FoodRef('máslo', ['masl'], 740, 0.6, 0.6, 82),
  FoodRef('smetana na vaření', ['smetan', 'zakys'], 135, 3, 4, 12),
  FoodRef('šlehačka', ['slehack', 'smetana ke slehani'], 320, 2, 3, 33),
  FoodRef('protein (prášek)', ['protein', 'whey', 'syrovatk'], 380, 75, 8, 6),
  // Přílohy, pečivo, obiloviny
  FoodRef('rýže (suchá)', ['ryz'], 355, 7, 78, 0.7),
  FoodRef(
    'rýže vařená',
    ['varena ryz', 'ryze varen', 'uvarena ryz'],
    130,
    2.7,
    28,
    0.3,
  ),
  FoodRef(
    'těstoviny (suché)',
    ['testovin', 'spaget', 'penne', 'fusill', 'makaron'],
    355,
    12.5,
    72,
    1.5,
  ),
  FoodRef(
    'těstoviny vařené',
    ['varene testovin', 'testoviny varen', 'uvarene testovin'],
    158,
    5.8,
    31,
    0.9,
  ),
  FoodRef('ovesné vločky', ['vlock', 'oves', 'ovsen'], 370, 13, 60, 7),
  FoodRef('müsli', ['musli', 'granol'], 370, 9, 64, 7),
  FoodRef('cornflakes', ['cornflak', 'kukuricne lupin'], 370, 7, 84, 0.9),
  FoodRef('chléb', ['chleb', 'chlebic'], 240, 8, 48, 1.5),
  FoodRef('toustový chléb', ['toust'], 265, 8, 49, 3.5, piece: 25),
  FoodRef(
    'rohlík',
    ['rohlik', 'bageta', 'houska', 'pecivo'],
    290,
    9.5,
    56,
    3.5,
    piece: 43,
  ),
  FoodRef('tortilla', ['tortil', 'wrap', 'placka'], 300, 8, 50, 7, piece: 60),
  FoodRef('brambory', ['brambor'], 77, 2, 17, 0.1, piece: 150),
  FoodRef('batáty', ['batat', 'sladke brambor'], 86, 1.6, 20, 0.1, piece: 200),
  FoodRef('kuskus', ['kuskus', 'couscous'], 376, 12.8, 77, 0.6),
  FoodRef('bulgur', ['bulgur'], 342, 12.3, 76, 1.3),
  FoodRef('quinoa', ['quino', 'kinoa', 'merlik'], 368, 14, 64, 6),
  FoodRef('čočka (suchá)', ['cock'], 350, 24, 60, 1.5),
  FoodRef('fazole (konzerva)', ['fazol'], 100, 7, 14, 0.5),
  FoodRef('cizrna (konzerva)', ['cizrn'], 130, 7, 18, 2.6),
  FoodRef('mouka hladká', ['mouk'], 345, 10, 73, 1),
  // Ovoce
  FoodRef('banán', ['banan'], 89, 1.1, 23, 0.3, piece: 120),
  FoodRef('jablko', ['jablk', 'jabl'], 52, 0.3, 14, 0.2, piece: 150),
  FoodRef('hruška', ['hrusk'], 57, 0.4, 15, 0.1, piece: 170),
  FoodRef(
    'pomeranč',
    ['pomeranc', 'mandarin', 'klementin'],
    47,
    0.9,
    12,
    0.1,
    piece: 160,
  ),
  FoodRef('kiwi', ['kiwi'], 61, 1.1, 15, 0.5, piece: 75),
  FoodRef('jahody', ['jahod'], 32, 0.7, 7.7, 0.3),
  FoodRef('borůvky', ['boruvk', 'malin', 'lesni ovoce'], 57, 0.7, 14, 0.3),
  FoodRef('hroznové víno', ['hrozn'], 69, 0.7, 18, 0.2),
  FoodRef('avokádo', ['avokad'], 160, 2, 8.5, 15, piece: 150),
  FoodRef('citron', ['citron', 'limet'], 29, 1.1, 9, 0.3, piece: 100),
  // Zelenina
  FoodRef('rajče', ['rajc', 'rajat', 'cherry'], 18, 0.9, 3.9, 0.2, piece: 100),
  FoodRef('okurka', ['okurk'], 15, 0.7, 3.6, 0.1, piece: 300),
  FoodRef('paprika', ['paprik'], 31, 1, 6, 0.3, piece: 150),
  FoodRef('mrkev', ['mrkev', 'mrkv'], 41, 0.9, 10, 0.2, piece: 70),
  FoodRef(
    'cibule',
    ['cibul', 'salotk', 'porek', 'porik'],
    40,
    1.1,
    9.3,
    0.1,
    piece: 100,
  ),
  FoodRef('česnek', ['cesnek', 'strouz'], 149, 6.4, 33, 0.5, piece: 4),
  FoodRef('brokolice', ['brokolic'], 34, 2.8, 7, 0.4),
  FoodRef('květák', ['kvetak'], 25, 1.9, 5, 0.3),
  FoodRef('špenát', ['spenat', 'rukol', 'polnicek'], 23, 2.9, 3.6, 0.4),
  FoodRef('salát', ['salat', 'ledovy'], 14, 0.9, 3, 0.1, piece: 500),
  FoodRef('zelí', ['zeli', 'kapust'], 25, 1.3, 5.8, 0.1),
  FoodRef('kysané zelí', ['kysane zeli'], 19, 0.9, 4.3, 0.1),
  FoodRef('cuketa', ['cuket'], 17, 1.2, 3.1, 0.3, piece: 250),
  FoodRef('lilek', ['lilek', 'lilk'], 25, 1, 6, 0.2, piece: 300),
  FoodRef('žampiony', ['zampion', 'houb'], 22, 3.1, 3.3, 0.3),
  FoodRef('kukuřice (konzerva)', ['kukuric'], 81, 2.9, 15, 1.2),
  FoodRef('hrášek', ['hrase', 'hrach'], 81, 5.4, 14, 0.4),
  FoodRef('zelené fazolky', ['fazolk'], 31, 1.8, 7, 0.2),
  FoodRef('ředkvičky', ['redkv'], 16, 0.7, 3.4, 0.1),
  FoodRef('dýně', ['dyne', 'hokaid'], 26, 1, 6.5, 0.1),
  FoodRef(
    'rajčata v konzervě',
    ['loupana rajc', 'pasirovan', 'passat', 'rajcata v konzerv'],
    26,
    1.3,
    4.5,
    0.2,
  ),
  FoodRef('rajčatový protlak', ['protlak'], 82, 4.3, 19, 0.5),
  FoodRef('olivy', ['oliv'], 115, 0.8, 6, 11),
  // Tuky, omáčky, ostatní
  FoodRef('olej', ['olej', 'olivovy olej', 'repkovy olej'], 884, 0, 0, 100),
  FoodRef(
    'arašídové máslo',
    ['arasidove masl', 'arasidovy krem', 'burak'],
    590,
    25,
    16,
    50,
  ),
  FoodRef('ořechy', ['orech', 'mandl', 'kesu', 'arasid'], 620, 18, 10, 55),
  FoodRef('kečup', ['kecup'], 102, 1.2, 23, 0.1),
  FoodRef('majonéza', ['majonez', 'tatarsk'], 680, 1, 1.5, 75),
  FoodRef('hořčice', ['horcic'], 90, 5, 6, 5),
  FoodRef('hummus', ['humus', 'hummus'], 166, 8, 14, 10),
  FoodRef('pesto', ['pesto'], 450, 5, 6, 45),
  FoodRef('med', ['med'], 304, 0.3, 82, 0),
  FoodRef('cukr', ['cukr'], 400, 0, 100, 0),
  FoodRef('hořká čokoláda', ['cokolad'], 580, 8, 36, 42),
  FoodRef('pomerančový džus', ['dzus'], 45, 0.7, 10, 0.2),
  // Základy, které se nepočítají
  FoodRef('sůl', ['sul'], 0, 0, 0, 0, trivial: true),
  FoodRef('pepř', ['pepr'], 0, 0, 0, 0, trivial: true),
  FoodRef(
    'koření',
    [
      'koren',
      'bylink',
      'oregan',
      'bazalk',
      'petrzel',
      'pazitk',
      'kmin',
      'skorice',
    ],
    0,
    0,
    0,
    0,
    trivial: true,
  ),
  FoodRef('voda', ['voda', 'vody'], 0, 0, 0, 0, trivial: true),
  FoodRef('ocet', ['ocet', 'octa'], 0, 0, 0, 0, trivial: true),
];

const _from = 'áčďéěíňóřšťúůýž';
const _to = 'acdeeinorstuuyz';

/// Malá písmena bez diakritiky a bez nadbytečných mezer.
String normalizeFoodName(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    final i = _from.indexOf(ch);
    out.write(i < 0 ? ch : _to[i]);
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Položka tabulky pro název; vyhrává nejdelší shodný kmen. `null` = neznáme.
FoodRef? findFood(String name) {
  final n = normalizeFoodName(name);
  FoodRef? best;
  var bestLen = 0;
  for (final f in foodTable) {
    for (final stem in f.stems) {
      final s = normalizeFoodName(stem);
      if (s.length > bestLen && _containsWord(n, s)) {
        best = f;
        bestLen = s.length;
      }
    }
  }
  return best;
}

/// Kmen musí začínat na začátku slova („med“ nesmí trefit „medvěd“ uprostřed
/// slova, ale „med“ ve „medem“ ano).
bool _containsWord(String text, String stem) {
  var from = 0;
  while (true) {
    final i = text.indexOf(stem, from);
    if (i < 0) return false;
    if (i == 0 || text[i - 1] == ' ') return true;
    from = i + 1;
  }
}

/// Hmotnost v gramech; `null`, když ji nejde určit.
double? gramsOf(FoodRef ref, double? amount, String? unit) {
  if (amount == null || amount <= 0) return null;
  return switch (unit) {
    'g' || 'ml' => amount,
    'ks' => ref.piece == null ? null : amount * ref.piece!,
    _ => null,
  };
}

/// Ingredience k odhadu (název, množství, jednotka g/ml/ks).
typedef IngredientAmount = ({String name, double? amount, String? unit});

/// Součet hodnot podle tabulky. `null`, když některou ingredienci neznáme
/// nebo nejde určit její hmotnost (pak se použije odhad AI).
Nutrition? tableEstimate(List<IngredientAmount> ingredients) {
  if (ingredients.isEmpty) return null;
  var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
  for (final i in ingredients) {
    final ref = findFood(i.name);
    if (ref == null) return null;
    if (ref.trivial) continue;
    final grams = gramsOf(ref, i.amount, i.unit);
    if (grams == null) return null;
    kcal += ref.kcal * grams / 100;
    protein += ref.protein * grams / 100;
    carbs += ref.carbs * grams / 100;
    fat += ref.fat * grams / 100;
  }
  return Nutrition(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
}
