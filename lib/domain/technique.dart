/// Technika cviků z katalogu: tři kroky provedení a časté chyby.
/// Vlastní texty, žádné převzaté návody.
library;

typedef Technique = ({List<String> steps, List<String> mistakes});

/// Fotky cviku přibalené v aplikaci (free-exercise-db, public domain).
/// Má je jen původních 58 cviků; vlastní a nové cviky žádné.
List<String> exerciseImages(String id) => _photos.contains(id)
    ? ['assets/exercises/${id}_0.jpg', 'assets/exercises/${id}_1.jpg']
    : const [];

const _photos = {
  'bench_press',
  'incline_press',
  'chest_press_machine',
  'pec_deck',
  'cable_fly',
  'squat',
  'leg_press',
  'hack_squat',
  'leg_extension',
  'leg_curl',
  'romanian_deadlift',
  'calf_raise',
  'deadlift',
  'lat_pulldown',
  'seated_row',
  'chest_supported_row',
  'pull_up',
  'shoulder_press',
  'lateral_raise',
  'reverse_pec_deck',
  'biceps_curl',
  'preacher_curl',
  'triceps_pushdown',
  'dips',
  'ab_crunch',
  'dumbbell_bench_press',
  'incline_dumbbell_press',
  'push_up',
  'front_squat',
  'goblet_squat',
  'smith_squat',
  'hip_thrust',
  'bulgarian_split_squat',
  'walking_lunge',
  'seated_calf_raise',
  'barbell_row',
  'dumbbell_row',
  'close_grip_pulldown',
  'machine_row',
  'face_pull',
  'overhead_press',
  'dumbbell_shoulder_press',
  'cable_lateral_raise',
  'rear_delt_fly',
  'barbell_curl',
  'hammer_curl',
  'cable_curl',
  'overhead_triceps_extension',
  'skull_crusher',
  'cable_crunch',
  'hanging_leg_raise',
  'incline_dumbbell_curl',
  'low_to_high_cable_fly',
  'shrug',
  'back_extension',
  'calf_press',
  'reverse_curl',
  'lying_leg_raise',
};

Technique? techniqueOf(String id) => techniques[id];

const Map<String, Technique> techniques = {
  'bench_press': (
    steps: [
      'Lehni si, oči pod osou. Lopatky stáhni k sobě a dolů, chodidla pevně na zemi.',
      'Spouštěj osu pod kontrolou na spodní část hrudníku, lokty asi 45° od těla.',
      'Vytlač nahoru a mírně k obličeji, lopatky drž stažené celou sérii.',
    ],
    mistakes: [
      'Odrážení osy od hrudníku.',
      'Lokty roztažené do stran v pravém úhlu (zátěž ramen).',
    ],
  ),
  'incline_press': (
    steps: [
      'Lavici nastav na 30–45°. Lopatky stažené, hrudník vytažený nahoru.',
      'Spouštěj osu pod klíční kosti, předloktí svisle.',
      'Tlač nahoru nad ramena, dole krátce zastav.',
    ],
    mistakes: [
      'Příliš strmá lavice: práci převezmou ramena.',
      'Zvedání zadku z lavice.',
    ],
  ),
  'chest_press_machine': (
    steps: [
      'Sedák nastav tak, aby madla byla ve výšce středu hrudníku.',
      'Lopatky opři o opěradlo, tlač madla dopředu bez zamčení loktů.',
      'Vracej pomalu, dokud necítíš protažení hrudníku.',
    ],
    mistakes: ['Ramena se zvedají k uším.', 'Rychlé pouštění závaží zpět.'],
  ),
  'pec_deck': (
    steps: [
      'Madla ve výšce ramen, lokty lehce pokrčené a zamčené v té poloze.',
      'Stahuj paže před sebe obloukem, jako bys objímal strom.',
      'Vracej pomalu do protažení, ramena drž vzadu.',
    ],
    mistakes: [
      'Ohýbání loktů, z cviku se stane tlak.',
      'Hrbení ramen dopředu.',
    ],
  ),
  'cable_fly': (
    steps: [
      'Kladky nahoře, krok dopředu, mírný předklon a pevný střed těla.',
      'Lokty lehce pokrčené, táhni ruce obloukem dolů před sebe.',
      'Dole krátce stiskni hrudník a pomalu se vrať.',
    ],
    mistakes: ['Tahání pažemi místo hrudníku.', 'Příliš velká váha a houpání.'],
  ),
  'squat': (
    steps: [
      'Osa na trapézech, chodidla na šířku ramen, špičky mírně ven.',
      'Nadechni se, zpevni břicho a jdi dolů s koleny ve směru špiček.',
      'Jdi aspoň do stehen rovnoběžně se zemí a vytlač se celým chodidlem.',
    ],
    mistakes: [
      'Kolena padají dovnitř.',
      'Paty se zvedají, váha jde na špičky.',
    ],
  ),
  'leg_press': (
    steps: [
      'Chodidla doprostřed plošiny na šířku ramen, záda celá na opěradle.',
      'Spouštěj plošinu, dokud se nezačne odlepovat spodek zad.',
      'Vytlač patami, kolena na konci nezamykej.',
    ],
    mistakes: ['Zadek se zvedá ze sedáku.', 'Moc krátký pohyb s velkou váhou.'],
  ),
  'hack_squat': (
    steps: [
      'Záda na opěrce, ramena pod polštáři, chodidla na šířku ramen.',
      'Jdi pomalu dolů, kolena smí jít před špičky.',
      'Vytlač celým chodidlem, nahoře nezamykej kolena.',
    ],
    mistakes: ['Paty odlepené od plošiny.', 'Poskakování v dolní poloze.'],
  ),
  'leg_extension': (
    steps: [
      'Kolena v ose otáčení stroje, polštář nad kotníky.',
      'Propni nohy a nahoře na chvilku stáhni stehna.',
      'Spouštěj pomalu, závaží nenech dosednout.',
    ],
    mistakes: ['Švihání a zvedání zadku.', 'Rychlé spouštění.'],
  ),
  'leg_curl': (
    steps: [
      'Lehni si, kolena těsně za hranou lavice, polštář nad patami.',
      'Přitáhni paty k zadku, boky drž na lavici.',
      'Spouštěj pomalu až skoro do propnutí.',
    ],
    mistakes: ['Zvedání boků.', 'Krátký pohyb jen v horní části.'],
  ),
  'romanian_deadlift': (
    steps: [
      'Stoj na šířku boků, osa u stehen, kolena lehce pokrčená.',
      'Posílej boky dozadu, osa klouže po nohou, záda rovná.',
      'Jdi, dokud cítíš tah v zadních stehnech, a vrať se vytlačením boků.',
    ],
    mistakes: ['Kulatá záda.', 'Dřep místo předklonu: kolena se moc ohýbají.'],
  ),
  'calf_raise': (
    steps: [
      'Špičky na hraně, paty volně dolů, kolena téměř propnutá.',
      'Vytlač se co nejvýš na špičky a chvilku podrž.',
      'Spouštěj pomalu do protažení lýtek.',
    ],
    mistakes: ['Pérování bez zastavení.', 'Malý rozsah pohybu.'],
  ),
  'deadlift': (
    steps: [
      'Osa nad středem chodidla, uchop ji těsně vedle nohou.',
      'Boky dolů, hrudník nahoru, záda rovná, napni paže a vytáhni vůli z osy.',
      'Zvedej tlakem nohou do země, osa jde těsně po nohou, nahoře propni boky.',
    ],
    mistakes: ['Kulatá záda.', 'Osa daleko od těla.'],
  ),
  'lat_pulldown': (
    steps: [
      'Úchop o něco širší než ramena, stehna pod polštáři.',
      'Stáhni lopatky dolů a táhni osu k hornímu hrudníku, lokty k bokům.',
      'Vracej pomalu nahoru do plného natažení.',
    ],
    mistakes: ['Záklon a houpání trupem.', 'Tahání za hlavu.'],
  ),
  'seated_row': (
    steps: [
      'Sedni si, kolena lehce pokrčená, záda rovná.',
      'Táhni madlo k pupku, lopatky stáhni k sobě.',
      'Vracej pomalu a nech lopatky jít dopředu, záda zůstávají rovná.',
    ],
    mistakes: ['Houpání trupem dozadu.', 'Ramena se zvedají k uším.'],
  ),
  'chest_supported_row': (
    steps: [
      'Lehni si hrudníkem na šikmou lavici, činky volně dolů.',
      'Přitáhni činky k bokům, lopatky k sobě.',
      'Spouštěj pomalu do natažení paží.',
    ],
    mistakes: ['Zvedání hrudníku z lavice.', 'Tahání jen rukama.'],
  ),
  'pull_up': (
    steps: [
      'Úchop nadhmatem o něco širší než ramena, plný vis.',
      'Stáhni lopatky dolů a přitáhni se, až je brada nad hrazdou.',
      'Spouštěj se pomalu až do propnutých paží.',
    ],
    mistakes: ['Kopání nohama.', 'Poloviční opakování bez plného visu.'],
  ),
  'shoulder_press': (
    steps: [
      'Sedák nastav tak, aby madla byla ve výšce ramen.',
      'Tlač nahoru bez zamčení loktů, záda opřená.',
      'Spouštěj pomalu k výšce uší.',
    ],
    mistakes: ['Prohýbání v bedrech.', 'Moc krátký pohyb.'],
  ),
  'lateral_raise': (
    steps: [
      'Stoj, činky u boků, lokty lehce pokrčené.',
      'Zvedej paže do stran do výšky ramen, malíček lehce nahoru.',
      'Spouštěj pomalu, nahoře nezvedej ramena.',
    ],
    mistakes: [
      'Švihání trupem.',
      'Zvedání nad výšku ramen se zvednutými trapézy.',
    ],
  ),
  'reverse_pec_deck': (
    steps: [
      'Sedni si čelem ke stroji, madla ve výšce ramen.',
      'Roztahuj paže obloukem dozadu, lokty lehce pokrčené.',
      'Vracej pomalu, hrudník opřený.',
    ],
    mistakes: [
      'Stahování lopatek místo práce zadních delt.',
      'Trhání závažím.',
    ],
  ),
  'biceps_curl': (
    steps: [
      'Stoj, činky u stehen, dlaně dopředu, lokty u těla.',
      'Ohni paže a zvedni činky k ramenům, lokty zůstávají na místě.',
      'Spouštěj pomalu až do propnutí.',
    ],
    mistakes: ['Švihání trupem.', 'Lokty jdou dopředu.'],
  ),
  'preacher_curl': (
    steps: [
      'Paže celé na opěrce, podpaží na její hraně.',
      'Ohni paže a zvedni osu, nahoře stiskni biceps.',
      'Spouštěj pomalu skoro do propnutí.',
    ],
    mistakes: ['Zvedání loktů z opěrky.', 'Pouštění dolů bez kontroly.'],
  ),
  'triceps_pushdown': (
    steps: [
      'Kladka nahoře, lokty u boků, mírný předklon.',
      'Tlač dolů do propnutí loktů a dole stiskni triceps.',
      'Vracej, dokud předloktí nejsou zhruba vodorovně.',
    ],
    mistakes: ['Lokty se hýbou dopředu a dozadu.', 'Dotlačování vahou těla.'],
  ),
  'dips': (
    steps: [
      'Opři se o bradla s propnutými pažemi, trup spíš svisle.',
      'Spouštěj se, až jsou ramena zhruba v úrovni loktů.',
      'Vytlač se nahoru do propnutí.',
    ],
    mistakes: ['Moc hluboko s bolestí ramen.', 'Ramena se zvedají k uším.'],
  ),
  'ab_crunch': (
    steps: [
      'Nastav sedák, madla drž u hrudníku.',
      'Stáhni žebra k pánvi, jako by ses stáčel do klubíčka.',
      'Vracej pomalu, závaží nenech dosednout.',
    ],
    mistakes: ['Tahání rukama.', 'Ohýbání v bocích místo stočení páteře.'],
  ),
  'dumbbell_bench_press': (
    steps: [
      'Lehni si s činkami nad hrudníkem, lopatky stažené.',
      'Spouštěj činky po stranách hrudníku, lokty asi 45° od těla.',
      'Tlač nahoru k sobě, nahoře se činky nemusí dotknout.',
    ],
    mistakes: ['Moc rychlé spouštění.', 'Ztráta napětí v lopatkách.'],
  ),
  'incline_dumbbell_press': (
    steps: [
      'Lavice na 30–45°, činky nad horním hrudníkem.',
      'Spouštěj činky k horní části hrudníku, lokty mírně pod rameny.',
      'Tlač nahoru, dole krátce zastav.',
    ],
    mistakes: ['Příliš strmá lavice.', 'Lokty roztažené do stran.'],
  ),
  'push_up': (
    steps: [
      'Ruce o něco širší než ramena, tělo v jedné rovině od hlavy k patám.',
      'Spouštěj hrudník k zemi, lokty asi 45° od těla.',
      'Vytlač se do propnutých paží, břicho drž zpevněné.',
    ],
    mistakes: ['Propadlá nebo vystrčená pánev.', 'Poloviční rozsah.'],
  ),
  'front_squat': (
    steps: [
      'Osa na předních deltech, lokty vysoko dopředu.',
      'Jdi dolů se vzpřímeným trupem, kolena ve směru špiček.',
      'Vytlač se nahoru, lokty pořád vysoko.',
    ],
    mistakes: ['Padající lokty a předklon.', 'Paty se zvedají.'],
  ),
  'goblet_squat': (
    steps: [
      'Činku nebo kettlebell drž u hrudníku, chodidla na šířku ramen.',
      'Jdi do dřepu mezi kolena, trup vzpřímený.',
      'Vytlač se patami nahoru.',
    ],
    mistakes: ['Kolena padají dovnitř.', 'Kulatá záda dole.'],
  ),
  'smith_squat': (
    steps: [
      'Chodidla mírně před osou, osa na trapézech.',
      'Jdi dolů pod kontrolou, kolena ve směru špiček.',
      'Vytlač se celým chodidlem nahoru.',
    ],
    mistakes: ['Chodidla přímo pod osou: tlak na kolena.', 'Malý rozsah.'],
  ),
  'hip_thrust': (
    steps: [
      'Lopatky na hraně lavice, osa v ohybu boků (s podložkou).',
      'Vytlač boky nahoru patami, brada u hrudníku.',
      'Nahoře stiskni hýždě a pomalu spouštěj.',
    ],
    mistakes: [
      'Prohnutí v bedrech nahoře.',
      'Chodidla moc daleko nebo blízko.',
    ],
  ),
  'bulgarian_split_squat': (
    steps: [
      'Zadní noha nártem na lavici, přední chodidlo asi krok před ní.',
      'Jdi dolů svisle, přední koleno ve směru špičky.',
      'Vytlač se přední patou, pak vystřídej nohy.',
    ],
    mistakes: ['Přední chodidlo moc blízko lavice.', 'Kolíbání do stran.'],
  ),
  'walking_lunge': (
    steps: [
      'Udělej dlouhý krok vpřed, trup vzpřímený.',
      'Zadní koleno spusť těsně nad zem.',
      'Odraz se přední patou a krokem pokračuj druhou nohou.',
    ],
    mistakes: [
      'Krátké kroky, koleno daleko před špičkou.',
      'Koleno padá dovnitř.',
    ],
  ),
  'seated_calf_raise': (
    steps: [
      'Polštář na stehnech těsně nad koleny, špičky na hraně.',
      'Zvedni paty co nejvýš a chvilku podrž.',
      'Spouštěj pomalu do protažení.',
    ],
    mistakes: ['Pérování.', 'Malý rozsah.'],
  ),
  'barbell_row': (
    steps: [
      'Předklon asi 45°, záda rovná, kolena lehce pokrčená.',
      'Přitáhni osu ke spodní části břicha, lokty podél těla.',
      'Spouštěj pomalu do natažených paží.',
    ],
    mistakes: ['Zvedání trupu při každém opakování.', 'Kulatá záda.'],
  ),
  'dumbbell_row': (
    steps: [
      'Ruka a koleno na lavici, záda rovná, činka visí dolů.',
      'Přitáhni činku k boku, loket podél těla.',
      'Spouštěj pomalu do protažení zad.',
    ],
    mistakes: ['Rotace trupu.', 'Tahání k rameni místo k boku.'],
  ),
  'close_grip_pulldown': (
    steps: [
      'Úzké madlo, stehna pod polštáři, mírný záklon.',
      'Stáhni lopatky a táhni madlo k hrudníku, lokty k bokům.',
      'Vracej pomalu do plného natažení.',
    ],
    mistakes: ['Velký záklon a houpání.', 'Tahání jen rukama.'],
  ),
  'machine_row': (
    steps: [
      'Hrudník opřený o polštář, madla na dosah.',
      'Táhni madla k tělu, lopatky k sobě.',
      'Vracej pomalu do natažení.',
    ],
    mistakes: ['Odlepování hrudníku.', 'Ramena se zvedají.'],
  ),
  'face_pull': (
    steps: [
      'Lano na kladce ve výšce obličeje, úchop palci dozadu.',
      'Táhni lano k obličeji a roztáhni ruce do stran za uši.',
      'Vracej pomalu, lokty drž vysoko.',
    ],
    mistakes: ['Lokty padají dolů.', 'Záklon trupem.'],
  ),
  'overhead_press': (
    steps: [
      'Osa na předních ramenech, úchop o něco širší než ramena.',
      'Zpevni břicho a hýždě a tlač osu nad hlavu, hlavu uhni dozadu.',
      'Nahoře hlavu vrať pod osu, spouštěj pomalu.',
    ],
    mistakes: ['Prohýbání v bedrech.', 'Osa jde před obličejem dopředu.'],
  ),
  'dumbbell_shoulder_press': (
    steps: [
      'Sedni si se zády opřenými, činky u uší.',
      'Tlač nahoru nad hlavu, nahoře se činky skoro dotknou.',
      'Spouštěj pomalu do výšky uší.',
    ],
    mistakes: ['Prohnutá záda.', 'Krátký pohyb.'],
  ),
  'cable_lateral_raise': (
    steps: [
      'Kladka dole, madlo v ruce dál od kladky.',
      'Zvedej paži do strany do výšky ramen.',
      'Spouštěj pomalu, napětí kabelu drž celou dobu.',
    ],
    mistakes: ['Naklánění trupu.', 'Zvedání ramene k uchu.'],
  ),
  'rear_delt_fly': (
    steps: [
      'Předklon skoro vodorovně, činky pod hrudníkem.',
      'Roztahuj paže do stran, lokty lehce pokrčené.',
      'Spouštěj pomalu, lopatky moc nestahuj.',
    ],
    mistakes: ['Švihání trupem.', 'Velká váha, práci převezmou záda.'],
  ),
  'barbell_curl': (
    steps: [
      'Stoj, osa podhmatem na šířku ramen, lokty u těla.',
      'Zvedni osu k ramenům bez pohybu loktů.',
      'Spouštěj pomalu až do propnutí.',
    ],
    mistakes: ['Záklon a švih.', 'Neúplné spouštění.'],
  ),
  'hammer_curl': (
    steps: [
      'Činky u boků, dlaně k sobě.',
      'Zvedej činky k ramenům, dlaně pořád k sobě.',
      'Spouštěj pomalu, lokty zůstávají u těla.',
    ],
    mistakes: ['Švihání.', 'Lokty jdou dopředu.'],
  ),
  'cable_curl': (
    steps: [
      'Kladka dole, rovné madlo podhmatem, lokty u těla.',
      'Zvedej madlo k ramenům, nahoře stiskni biceps.',
      'Spouštěj pomalu, napětí drž dole.',
    ],
    mistakes: ['Předklon a záklon trupu.', 'Lokty se posouvají.'],
  ),
  'overhead_triceps_extension': (
    steps: [
      'Lano za hlavou, otoč se zády ke kladce, lokty u hlavy.',
      'Propni paže dopředu nad hlavu.',
      'Vracej pomalu do protažení tricepsu.',
    ],
    mistakes: ['Lokty se rozjíždějí do stran.', 'Prohnutí v bedrech.'],
  ),
  'skull_crusher': (
    steps: [
      'Lehni si s osou nad rameny, paže svisle.',
      'Spouštěj osu za čelo jen pohybem v loktech.',
      'Propni paže zpět nahoru.',
    ],
    mistakes: ['Lokty jdou do stran.', 'Pohyb v ramenou místo loktů.'],
  ),
  'cable_crunch': (
    steps: [
      'Klekni si pod kladku, lano drž u hlavy.',
      'Stoč trup dolů, žebra k pánvi.',
      'Vracej pomalu, boky drž na místě.',
    ],
    mistakes: ['Sedání na paty.', 'Tahání rukama.'],
  ),
  'hanging_leg_raise': (
    steps: [
      'Vis na hrazdě, ramena aktivní, nohy u sebe.',
      'Zvedni nohy (nebo kolena) a podsaď pánev.',
      'Spouštěj pomalu bez houpání.',
    ],
    mistakes: [
      'Houpání tělem.',
      'Zvedání jen do vodorovné bez podsazení pánve.',
    ],
  ),
  'incline_dumbbell_curl': (
    steps: [
      'Lavice na 45–60°, paže volně dolů za tělem.',
      'Zvedej činky, lokty zůstávají vzadu.',
      'Spouštěj pomalu do plného protažení.',
    ],
    mistakes: ['Lokty jdou dopředu.', 'Zvedání ramen z opěradla.'],
  ),
  'low_to_high_cable_fly': (
    steps: [
      'Kladky dole, krok dopředu, lokty lehce pokrčené.',
      'Veď ruce obloukem nahoru před sebe do výšky brady.',
      'Vracej pomalu dolů do protažení.',
    ],
    mistakes: ['Ohýbání loktů.', 'Zvedání ramen.'],
  ),
  'shrug': (
    steps: [
      'Stoj s osou nebo činkami u stehen.',
      'Zvedni ramena rovně nahoru k uším a chvilku podrž.',
      'Spouštěj pomalu.',
    ],
    mistakes: ['Kroužení rameny.', 'Ohýbání loktů.'],
  ),
  'back_extension': (
    steps: [
      'Boky na polštáři, paty zaklesnuté, ruce na hrudníku.',
      'Předkloň se s rovnými zády.',
      'Zvedni trup do roviny s nohama, nezaklánej se dál.',
    ],
    mistakes: ['Přeprohnutí nahoře.', 'Trhavý pohyb.'],
  ),
  'calf_press': (
    steps: [
      'Špičky na spodní hraně plošiny, nohy téměř propnuté.',
      'Tlač špičkami co nejdál a chvilku podrž.',
      'Vracej pomalu do protažení lýtek.',
    ],
    mistakes: ['Ohýbání kolen.', 'Pérování.'],
  ),
  'reverse_curl': (
    steps: [
      'Osa nadhmatem na šířku ramen, lokty u těla.',
      'Zvedej osu k ramenům, zápěstí rovná.',
      'Spouštěj pomalu.',
    ],
    mistakes: ['Ohnutá zápěstí.', 'Švihání.'],
  ),
  'lying_leg_raise': (
    steps: [
      'Lehni si na záda, ruce pod hýždě nebo vedle těla.',
      'Zvedni nohy do svislé polohy, spodek zad tlač do podložky.',
      'Spouštěj pomalu těsně nad zem.',
    ],
    mistakes: ['Prohnutí v bedrech.', 'Spouštění volným pádem.'],
  ),
  'decline_bench_press': (
    steps: [
      'Zaklesni nohy, lavice mírně dolů, lopatky stažené.',
      'Spouštěj osu na spodní okraj hrudníku, lokty asi 45° od těla.',
      'Vytlač nahoru nad hrudník, dole bez odrazu.',
    ],
    mistakes: ['Moc strmý sklon a krev do hlavy.', 'Odrážení osy od hrudníku.'],
  ),
  'smith_bench_press': (
    steps: [
      'Lavici posuň tak, aby osa dosedala na spodní část hrudníku.',
      'Lopatky stažené, odjisti osu otočením zápěstí.',
      'Spouštěj pod kontrolou a tlač nahoru, nahoře znovu zajisti.',
    ],
    mistakes: [
      'Lavice posunutá, osa jde na krk.',
      'Zamykání loktů s plnou silou.',
    ],
  ),
  'smith_incline_press': (
    steps: [
      'Šikmou lavici na 30° postav pod osu tak, aby šla pod klíční kosti.',
      'Lopatky stažené, odjisti osu.',
      'Spouštěj ke klíčním kostem, tlač nahoru a nahoře zajisti.',
    ],
    mistakes: ['Lavice moc strmá, pracují ramena.', 'Zvedání zadku z lavice.'],
  ),
  'incline_chest_press_machine': (
    steps: [
      'Sedák nastav, aby madla byla ve výšce horního hrudníku.',
      'Lopatky opři o opěradlo a tlač madla šikmo nahoru.',
      'Vracej pomalu do protažení.',
    ],
    mistakes: ['Ramena se zvedají k uším.', 'Krátký rozsah bez protažení.'],
  ),
  'cable_chest_press': (
    steps: [
      'Kladky ve výšce hrudníku, krok dopředu, stabilní postoj.',
      'Tlač madla před sebe, ruce se k sobě sbíhají.',
      'Vracej pomalu, lokty mírně pod úrovní ramen.',
    ],
    mistakes: [
      'Prohnutá bedra a ztráta rovnováhy.',
      'Tah rukama místo tlaku hrudníkem.',
    ],
  ),
  'dumbbell_fly': (
    steps: [
      'Lehni na rovnou lavici, činky nad hrudníkem, lokty lehce pokrčené.',
      'Rozpažuj obloukem dolů, dokud necítíš protažení hrudníku.',
      'Stejným obloukem stáhni ruce zpět nahoru.',
    ],
    mistakes: [
      'Ohýbání loktů, cvik se mění v tlak.',
      'Příliš hluboko a bolest ramen.',
    ],
  ),
  'incline_dumbbell_fly': (
    steps: [
      'Lavice na 30°, činky nad horním hrudníkem.',
      'Rozpažuj obloukem s pevně pokrčenými lokty.',
      'Stáhni zpět nahoru, nahoře nezamykej.',
    ],
    mistakes: ['Moc těžká váha a krátký rozsah.', 'Ramena dopředu.'],
  ),
  'chest_dips': (
    steps: [
      'Opři se na bradlech, nakloň trup dopředu, lokty mírně od těla.',
      'Spouštěj se, dokud nejsou ramena těsně pod lokty.',
      'Vytlač se nahoru, trup drž v předklonu.',
    ],
    mistakes: [
      'Příliš hluboký sed a bolest ramen.',
      'Rovný trup: práci přebírá triceps.',
    ],
  ),
  'dumbbell_pullover': (
    steps: [
      'Lehni napříč nebo podél lavice, činku drž oběma rukama nad hrudníkem.',
      'Lehce pokrčenými pažemi spouštěj činku obloukem za hlavu.',
      'Vrať ji stejným obloukem nad hrudník.',
    ],
    mistakes: ['Ohýbání loktů jako u francouzského tlaku.', 'Prohýbání beder.'],
  ),
  't_bar_row': (
    steps: [
      'Hrudník na opěrku nebo předklon s rovnými zády, úchop madel.',
      'Táhni madla k břichu, lopatky k sobě.',
      'Spouštěj pomalu do natažení paží.',
    ],
    mistakes: ['Kulatá záda.', 'Švihání trupem.'],
  ),
  'pendlay_row': (
    steps: [
      'Předklon téměř do vodorovna, osa leží na zemi.',
      'Výbušně přitáhni osu ke spodní části hrudníku.',
      'Polož osu zpět na zem, každé opakování znovu.',
    ],
    mistakes: ['Zvedání trupu při tahu.', 'Kulatá bedra.'],
  ),
  'machine_pulldown': (
    steps: [
      'Kolena pod válce, úchop madel.',
      'Stahuj madla k horní části hrudníku, lokty dolů.',
      'Vracej pomalu do plného natažení.',
    ],
    mistakes: ['Zaklánění trupu.', 'Krátký rozsah nahoře.'],
  ),
  'single_arm_pulldown': (
    steps: [
      'Madlo nad hlavou, sedni nebo klekni bokem k ose kladky.',
      'Táhni loket dolů k boku, lopatka jde dolů.',
      'Pomalu vrať do natažení.',
    ],
    mistakes: ['Rotace trupu místo práce zad.', 'Tah bicepsem.'],
  ),
  'straight_arm_pulldown': (
    steps: [
      'Postav se ke kladce, ruce na tyči nebo laně, lehký předklon.',
      'S téměř rovnými pažemi stahuj ke stehnům.',
      'Pomalu vracej do výšky hlavy.',
    ],
    mistakes: ['Ohýbání loktů.', 'Pohyb trupem.'],
  ),
  'single_arm_cable_row': (
    steps: [
      'Spodní kladka, madlo v jedné ruce, druhá ruka opřená.',
      'Táhni loket podél těla dozadu.',
      'Pomalu vrať a nech lopatku jít dopředu.',
    ],
    mistakes: ['Rotace trupu.', 'Trhaný pohyb.'],
  ),
  'machine_high_row': (
    steps: [
      'Hrudník na opěrce, úchop madel nad hlavou.',
      'Táhni madla dolů a dozadu, lokty podél těla.',
      'Vracej pomalu do natažení.',
    ],
    mistakes: ['Zvedání ramen k uším.', 'Odlepování hrudníku od opěrky.'],
  ),
  'chin_up': (
    steps: [
      'Vis podhmatem na šířku ramen, lopatky stáhni dolů.',
      'Přitáhni se bradou nad hrazdu, lokty k tělu.',
      'Spouštěj se pomalu do plného visu.',
    ],
    mistakes: ['Kopání nohama.', 'Polovičatý rozsah.'],
  ),
  'inverted_row': (
    steps: [
      'Osa v multipressu nebo hrazda ve výšce pasu, lehni pod ni.',
      'Tělo rovné jako prkno, přitáhni hrudník k ose.',
      'Pomalu se spusť do natažení paží.',
    ],
    mistakes: ['Propadlé boky.', 'Tah jen rukama bez lopatek.'],
  ),
  'rack_pull': (
    steps: [
      'Osa na blocích kolem kolen, úchop na šířku ramen.',
      'Napni záda a vytáhni osu do stoje.',
      'Spouštěj zpět na bloky pod kontrolou.',
    ],
    mistakes: ['Kulatá záda.', 'Záklon nahoře.'],
  ),
  'barbell_shrug': (
    steps: [
      'Stoj s osou u stehen, paže rovné.',
      'Zvedni ramena přímo nahoru k uším.',
      'Nahoře krátce drž a pomalu spusť.',
    ],
    mistakes: ['Krouživý pohyb rameny.', 'Ohýbání loktů.'],
  ),
  'hip_adduction': (
    steps: [
      'Sedni do stroje, polštáře z vnitřní strany kolen.',
      'Stahuj nohy k sobě silou vnitřních stehen.',
      'Pomalu povol do roztažení, které zvládneš bez bolesti.',
    ],
    mistakes: ['Trhání a pouštění váhy.', 'Moc široký start a bolest třísel.'],
  ),
  'hip_abduction': (
    steps: [
      'Sedni do stroje, polštáře z vnější strany kolen.',
      'Roztahuj kolena od sebe, záda opřená.',
      'Pomalu vrať k sobě bez dopadu závaží.',
    ],
    mistakes: ['Švihání trupem.', 'Krátký rozsah.'],
  ),
  'cable_hip_adduction': (
    steps: [
      'Manžeta na kotníku blíž ke kladce, drž se rámu.',
      'Táhni nohu přes střed těla před druhou nohu.',
      'Pomalu vrať zpět do strany.',
    ],
    mistakes: ['Rotace pánve.', 'Moc velká váha a švih.'],
  ),
  'cable_hip_abduction': (
    steps: [
      'Manžeta na kotníku vzdálenější nohy, drž se rámu.',
      'Unož nohu do strany, špička míří dopředu.',
      'Pomalu vrať k druhé noze.',
    ],
    mistakes: ['Naklánění trupu.', 'Vytáčení špičky nahoru.'],
  ),
  'banded_lateral_walk': (
    steps: [
      'Guma nad koleny nebo u kotníků, mírný podřep.',
      'Krokuj do strany, kolena tlač ven.',
      'Druhou nohu přisouvej jen napůl, guma zůstane napnutá.',
    ],
    mistakes: ['Kolena padají dovnitř.', 'Vzpřímený postoj bez podřepu.'],
  ),
  'sumo_squat': (
    steps: [
      'Široký postoj, špičky ven, činku drž mezi nohama.',
      'Jdi do dřepu, kolena míří nad špičky.',
      'Vytlač se nahoru, nahoře zatni hýždě.',
    ],
    mistakes: ['Kolena padají dovnitř.', 'Předklon trupu.'],
  ),
  'sumo_deadlift': (
    steps: [
      'Široký postoj, špičky ven, úchop mezi koleny.',
      'Tlač kolena ven, napni záda a stoupni s osou.',
      'Spouštěj osu po stehnech zpět na zem.',
    ],
    mistakes: ['Boky vystřelí nahoru dřív než osa.', 'Kulatá záda.'],
  ),
  'trap_bar_deadlift': (
    steps: [
      'Postav se doprostřed trap bar osy, úchop madel po stranách.',
      'Napni záda a tlač nohama do země až do stoje.',
      'Spusť pod kontrolou zpět.',
    ],
    mistakes: ['Kulatá záda.', 'Záklon nahoře.'],
  ),
  'good_morning': (
    steps: [
      'Osa na trapézech, kolena lehce pokrčená.',
      'Předkloň se v kyčlích s rovnými zády do vodorovna.',
      'Zvedni se zpět silou hamstringů a hýždí.',
    ],
    mistakes: ['Kulatá záda.', 'Moc velká váha.'],
  ),
  'dumbbell_rdl': (
    steps: [
      'Stoj s činkami u stehen, kolena lehce pokrčená.',
      'Posílej boky dozadu, činky jedou těsně podél nohou.',
      'Ve chvíli protažení hamstringů se vrať do stoje.',
    ],
    mistakes: ['Kulatá záda.', 'Dřep místo předklonu.'],
  ),
  'kettlebell_swing': (
    steps: [
      'Kettlebell před sebou, předklon v kyčlích, rovná záda.',
      'Švihni ho mezi nohy a výbušně vystřel boky dopředu.',
      'Kettlebell vyletí do výšky hrudníku, paže jen vedou.',
    ],
    mistakes: ['Dřep místo hmitu v kyčlích.', 'Zvedání rukama.'],
  ),
  'cable_pull_through': (
    steps: [
      'Spodní kladka s lanem mezi nohama, zády ke kladce.',
      'Předkloň se v kyčlích, lano jde dozadu.',
      'Vytlač boky dopředu a zatni hýždě.',
    ],
    mistakes: ['Tah rukama.', 'Kulatá záda.'],
  ),
  'seated_leg_curl': (
    steps: [
      'Sedni do stroje, válec nad kotníky, stehna zajištěná.',
      'Zakopni nohy dolů a dozadu co nejdál.',
      'Pomalu vrať do natažení.',
    ],
    mistakes: ['Zvedání zadku ze sedáku.', 'Rychlé pouštění váhy.'],
  ),
  'standing_leg_curl': (
    steps: [
      'Postav se do stroje, válec za kotníkem.',
      'Zakopni patu k hýždi, stehno zůstává na místě.',
      'Pomalu spusť dolů.',
    ],
    mistakes: ['Pohyb pánví.', 'Švih.'],
  ),
  'nordic_curl': (
    steps: [
      'Klekni, paty zaklesnuté nebo držené partnerem.',
      'Pomalu padej dopředu s rovným tělem, brzdi hamstringy.',
      'Dole se zachyť rukama a odraz zpět nahoru.',
    ],
    mistakes: ['Ohnutí v kyčlích.', 'Pád bez brzdění.'],
  ),
  'pendulum_squat': (
    steps: [
      'Záda na opěrce, ramena pod polštáři, chodidla na šířku ramen.',
      'Jdi hluboko do dřepu pod kontrolou.',
      'Vytlač se celým chodidlem nahoru.',
    ],
    mistakes: ['Zvedání pat.', 'Zamykání kolen nahoře.'],
  ),
  'belt_squat': (
    steps: [
      'Opasek kolem pasu, postav se na plošinu.',
      'Dřepni hluboko s rovným trupem.',
      'Vytlač se nahoru, kolena míří nad špičky.',
    ],
    mistakes: ['Kolena padají dovnitř.', 'Polovičatý dřep.'],
  ),
  'air_squat': (
    steps: [
      'Chodidla na šířku ramen, ruce před sebou.',
      'Jdi s boky dozadu a dolů pod úroveň kolen.',
      'Vytlač se nahoru, nahoře zatni hýždě.',
    ],
    mistakes: ['Zvedání pat.', 'Kulatá záda dole.'],
  ),
  'barbell_lunge': (
    steps: [
      'Osa na trapézech, stoj rozkročný.',
      'Udělej krok dopředu a klesni, zadní koleno nad zem.',
      'Odraz se přední nohou zpět.',
    ],
    mistakes: ['Koleno přední nohy padá dovnitř.', 'Moc krátký krok.'],
  ),
  'reverse_lunge': (
    steps: [
      'Stoj s činkami v rukou.',
      'Ukroč dozadu a klesni, zadní koleno nad zem.',
      'Vrať se přední nohou do stoje.',
    ],
    mistakes: ['Předklon trupu.', 'Ztráta rovnováhy.'],
  ),
  'step_up': (
    steps: [
      'Činky v rukou, bedna ve výšce kolene.',
      'Celé chodidlo na bednu, vytlač se nahoru přední nohou.',
      'Pomalu sestup stejnou nohou.',
    ],
    mistakes: ['Odraz zadní nohou.', 'Koleno padá dovnitř.'],
  ),
  'glute_bridge': (
    steps: [
      'Lehni na záda, osa v pánvi, chodidla blízko hýždí.',
      'Zvedni boky nahoru, nahoře zatni hýždě.',
      'Pomalu spusť skoro k zemi.',
    ],
    mistakes: ['Prohýbání beder nahoře.', 'Tlak přes špičky.'],
  ),
  'hip_thrust_machine': (
    steps: [
      'Opři horní záda, pás přes pánev, chodidla na šířku ramen.',
      'Vytlač boky nahoru do roviny s trupem.',
      'Nahoře krátce drž a pomalu spusť.',
    ],
    mistakes: ['Záklon hlavy a prohnutá bedra.', 'Moc daleko chodidla.'],
  ),
  'cable_kickback': (
    steps: [
      'Manžeta na kotníku, předkloň se a drž se rámu.',
      'Zanož nohu dozadu a nahoru silou hýždě.',
      'Pomalu vrať pod sebe.',
    ],
    mistakes: ['Prohýbání beder.', 'Švih.'],
  ),
  'glute_kickback_machine': (
    steps: [
      'Opři se o stroj, chodidlo na plošinu.',
      'Tlač nohu dozadu do natažení kyčle.',
      'Pomalu vrať.',
    ],
    mistakes: ['Prohnutá bedra.', 'Krátký rozsah.'],
  ),
  'smith_calf_raise': (
    steps: [
      'Osa na trapézech, špičky na vyvýšené podložce.',
      'Vyjdi na špičky co nejvýš.',
      'Pomalu klesni do protažení lýtek.',
    ],
    mistakes: ['Pérování bez pauzy.', 'Ohýbání kolen.'],
  ),
  'single_leg_calf_raise': (
    steps: [
      'Stoj na jedné noze na schodu, činka v ruce, druhou se drž.',
      'Vyjdi na špičku co nejvýš.',
      'Klesni pod úroveň schodu do protažení.',
    ],
    mistakes: ['Malý rozsah.', 'Houpání tělem.'],
  ),
  'arnold_press': (
    steps: [
      'Sedni, činky před obličejem dlaněmi k sobě.',
      'Tlač nahoru a při tom otáčej dlaně dopředu.',
      'Spouštěj zpět s rotací do výchozí polohy.',
    ],
    mistakes: ['Prohýbání beder.', 'Rychlé a trhané rotace.'],
  ),
  'smith_shoulder_press': (
    steps: [
      'Lavici se zády nastav pod osu, osa jde před obličejem.',
      'Tlač osu nad hlavu, nezamykej lokty naplno.',
      'Spouštěj k bradě pod kontrolou.',
    ],
    mistakes: ['Osa jde za hlavu.', 'Prohnutá bedra.'],
  ),
  'push_press': (
    steps: [
      'Osa na předních deltech, stoj na šířku boků.',
      'Krátký podřep a výbušně vytlač osu nad hlavu.',
      'Pomalu spusť zpět na ramena.',
    ],
    mistakes: ['Hluboký dřep místo krátkého podřepu.', 'Záklon trupu.'],
  ),
  'landmine_press': (
    steps: [
      'Konec osy v rohu nebo landmine, druhý konec u ramene.',
      'Tlač osu šikmo nahoru a dopředu.',
      'Pomalu vrať k rameni.',
    ],
    mistakes: ['Prohnutá bedra.', 'Rotace trupu.'],
  ),
  'front_raise': (
    steps: [
      'Stoj, činky před stehny.',
      'Zvedej paže před sebe do výšky ramen.',
      'Pomalu spusť dolů.',
    ],
    mistakes: ['Švih trupem.', 'Zvedání nad hlavu.'],
  ),
  'plate_front_raise': (
    steps: [
      'Kotouč drž oběma rukama před stehny.',
      'Zvedni ho rovnými pažemi do výšky očí.',
      'Pomalu spusť.',
    ],
    mistakes: ['Záklon trupu.', 'Švih.'],
  ),
  'upright_row': (
    steps: [
      'Osa nadhmatem, úchop o něco širší než ramena.',
      'Táhni osu podél těla k hrudníku, lokty vedou.',
      'Pomalu spusť dolů.',
    ],
    mistakes: ['Úzký úchop a bolest ramen.', 'Tah nad úroveň ramen.'],
  ),
  'machine_lateral_raise': (
    steps: [
      'Sedni, polštáře z vnější strany loktů.',
      'Upažuj do výšky ramen.',
      'Pomalu spusť dolů.',
    ],
    mistakes: ['Krčení ramen.', 'Rychlé pouštění.'],
  ),
  'cable_rear_delt_fly': (
    steps: [
      'Kladky nahoře, lanka zkřížená, stoj mezi nimi.',
      'Táhni ruce do stran a dozadu v úrovni ramen.',
      'Pomalu vrať před sebe.',
    ],
    mistakes: ['Tah lopatkami místo zadních deltů.', 'Ohýbání loktů.'],
  ),
  'band_pull_apart': (
    steps: [
      'Gumu drž před sebou v úrovni ramen.',
      'Roztáhni ji do stran až k hrudníku.',
      'Pomalu vrať.',
    ],
    mistakes: ['Krčení ramen.', 'Pokrčené lokty.'],
  ),
  'ez_bar_curl': (
    steps: [
      'EZ osa podhmatem, lokty u těla.',
      'Zvedni osu k ramenům bez švihu.',
      'Pomalu spusť do natažení.',
    ],
    mistakes: ['Švih trupem.', 'Lokty jdou dopředu.'],
  ),
  'concentration_curl': (
    steps: [
      'Sedni, loket opři o vnitřní stranu stehna.',
      'Zvedni činku k rameni.',
      'Pomalu spusť do plného natažení.',
    ],
    mistakes: ['Pohyb trupem.', 'Krátký rozsah.'],
  ),
  'machine_preacher_curl': (
    steps: [
      'Nastav sedák, paže celé na opěrce.',
      'Zvedni madla k ramenům.',
      'Pomalu spusť skoro do natažení.',
    ],
    mistakes: ['Zvedání zadku ze sedáku.', 'Pouštění váhy dolů.'],
  ),
  'bayesian_curl': (
    steps: [
      'Stoj zády ke spodní kladce, madlo v ruce, paže za tělem.',
      'Zvedni madlo k rameni, loket zůstává vzadu.',
      'Pomalu vrať do protažení.',
    ],
    mistakes: ['Loket jde dopředu.', 'Rotace trupu.'],
  ),
  'cable_hammer_curl': (
    steps: [
      'Lano na spodní kladce, dlaně proti sobě.',
      'Zvedni lano k ramenům, lokty u těla.',
      'Pomalu spusť.',
    ],
    mistakes: ['Švih.', 'Lokty odjíždějí.'],
  ),
  'close_grip_bench': (
    steps: [
      'Osa na šířku ramen, lopatky stažené.',
      'Spouštěj na spodní hrudník, lokty u těla.',
      'Vytlač nahoru silou tricepsu.',
    ],
    mistakes: ['Moc úzký úchop a bolest zápěstí.', 'Lokty do stran.'],
  ),
  'dumbbell_overhead_extension': (
    steps: [
      'Sedni, činku drž oběma rukama nad hlavou.',
      'Spouštěj ji za hlavu, lokty míří nahoru.',
      'Vytlač zpět nahoru.',
    ],
    mistakes: ['Lokty od sebe.', 'Prohnutá bedra.'],
  ),
  'triceps_kickback': (
    steps: [
      'Předklon s oporou, nadloktí podél těla.',
      'Natáhni loket dozadu do propnutí.',
      'Pomalu vrať, nadloktí se nehýbe.',
    ],
    mistakes: ['Pohyb nadloktím.', 'Švih.'],
  ),
  'bench_dips': (
    steps: [
      'Ruce na hraně lavice za sebou, nohy před sebou.',
      'Spouštěj se, dokud nejsou lokty v pravém úhlu.',
      'Vytlač se nahoru.',
    ],
    mistakes: ['Moc hluboko a bolest ramen.', 'Lokty do stran.'],
  ),
  'triceps_dip_machine': (
    steps: [
      'Sedni, madla vedle boků.',
      'Tlač madla dolů do propnutí loktů.',
      'Pomalu vrať nahoru.',
    ],
    mistakes: ['Předklon a práce hrudníku.', 'Krčení ramen.'],
  ),
  'wrist_curl': (
    steps: [
      'Sedni, předloktí na stehnech, osa podhmatem.',
      'Ohni zápěstí nahoru.',
      'Pomalu spusť a nech osu sjet do prstů.',
    ],
    mistakes: ['Pohyb předloktím.', 'Moc velká váha.'],
  ),
  'reverse_wrist_curl': (
    steps: [
      'Předloktí na stehnu, činka nadhmatem.',
      'Zvedni hřbet ruky nahoru.',
      'Pomalu spusť.',
    ],
    mistakes: ['Švih.', 'Moc velký rozsah do bolesti.'],
  ),
  'farmers_walk': (
    steps: [
      'Zvedni těžké činky jako mrtvý tah.',
      'Jdi krátkými kroky, ramena dole, trup vzpřímený.',
      'Po dané vzdálenosti činky polož.',
    ],
    mistakes: ['Kulatá záda při zvedání.', 'Naklánění do stran.'],
  ),
  'crunch': (
    steps: [
      'Lehni na záda, kolena pokrčená, ruce u spánků.',
      'Sroluj trup a zvedni lopatky od země.',
      'Pomalu se vrať.',
    ],
    mistakes: ['Tahání hlavy rukama.', 'Švih.'],
  ),
  'decline_crunch': (
    steps: [
      'Zaklesni nohy na šikmé lavici.',
      'Sroluj trup nahoru k kolenům.',
      'Pomalu se spusť, záda se nedotknou úplně.',
    ],
    mistakes: ['Švih.', 'Prohnutá bedra.'],
  ),
  'bicycle_crunch': (
    steps: [
      'Lehni na záda, ruce u hlavy, nohy nad zemí.',
      'Přitahuj koleno k opačnému lokti.',
      'Střídej strany pomalu a pod kontrolou.',
    ],
    mistakes: ['Tahání hlavy.', 'Rychlé šlapání bez rotace.'],
  ),
  'reverse_crunch': (
    steps: [
      'Lehni na záda, kolena pokrčená nad boky.',
      'Sroluj pánev nahoru k hrudníku.',
      'Pomalu ji spusť zpět.',
    ],
    mistakes: ['Švih nohama.', 'Bedra se odlepují s trhnutím.'],
  ),
  'hanging_knee_raise': (
    steps: [
      'Vis na hrazdě, ramena aktivní.',
      'Přitáhni kolena k hrudníku a podsaď pánev.',
      'Pomalu spusť bez houpání.',
    ],
    mistakes: ['Houpání.', 'Jen zvedání nohou bez podsazení pánve.'],
  ),
  'captains_chair': (
    steps: [
      'Opři předloktí, záda na opěrce.',
      'Zvedni kolena nebo rovné nohy nahoru.',
      'Pomalu spusť.',
    ],
    mistakes: ['Švih.', 'Prohnutá bedra.'],
  ),
  'ab_wheel': (
    steps: [
      'Klekni, kolečko pod rameny.',
      'Pomalu ho posílej dopředu s pevným břichem.',
      'Vrať se zpět silou břicha.',
    ],
    mistakes: ['Propadlá bedra.', 'Moc daleko na začátku.'],
  ),
  'russian_twist': (
    steps: [
      'Sedni, záklon asi 45°, kotouč v rukou.',
      'Otáčej trup ze strany na stranu.',
      'Pohyb jde z trupu, ne jen z rukou.',
    ],
    mistakes: ['Kulatá záda.', 'Pohyb jen rukama.'],
  ),
  'cable_woodchopper': (
    steps: [
      'Kladka nahoře, stoj bokem, madlo oběma rukama.',
      'Táhni šikmo dolů přes tělo rotací trupu.',
      'Pomalu vrať nahoru.',
    ],
    mistakes: ['Tah rukama.', 'Kroucení v bedrech bez pohybu boků.'],
  ),
  'torso_rotation_machine': (
    steps: [
      'Sedni do stroje, nohy zajištěné.',
      'Otoč trup do strany pod kontrolou.',
      'Pomalu vrať a pak druhá strana.',
    ],
    mistakes: ['Moc velká váha.', 'Trhaný pohyb.'],
  ),
  'side_bend': (
    steps: [
      'Stoj, činka v jedné ruce.',
      'Ukloň se k čince a pak zpět nad střed.',
      'Po sérii vyměň strany.',
    ],
    mistakes: ['Předklon nebo záklon.', 'Činky v obou rukách.'],
  ),
};
