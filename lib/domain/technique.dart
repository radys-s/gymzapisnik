/// Technika cviků z katalogu: tři kroky provedení a časté chyby.
/// Vlastní texty, žádné převzaté návody.
library;

typedef Technique = ({List<String> steps, List<String> mistakes});

/// Fotky cviku přibalené v aplikaci (free-exercise-db, public domain).
/// Vlastní cviky žádné nemají.
List<String> exerciseImages(String id) => techniques.containsKey(id)
    ? ['assets/exercises/${id}_0.jpg', 'assets/exercises/${id}_1.jpg']
    : const [];

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
};
