/// Technika cviků z katalogu: tři kroky provedení a časté chyby.
/// Vlastní texty, žádné převzaté návody.
library;

import '../core/i18n.dart';

typedef Technique = ({List<String> steps, List<String> mistakes});

Technique? techniqueOf(String id) => techniques[id];

final Map<String, Technique> techniques = {
  'bench_press': (
    steps: [
      tr(
        'Lehni si, oči pod osou. Lopatky stáhni k sobě a dolů, chodidla pevně na zemi.',
        'Lie down with eyes under the bar. Pull shoulder blades together and down, feet planted firmly.',
      ),
      tr(
        'Spouštěj osu pod kontrolou na spodní část hrudníku, lokty asi 45° od těla.',
        'Lower the bar with control to your lower chest, elbows about 45° from your body.',
      ),
      tr(
        'Vytlač nahoru a mírně k obličeji, lopatky drž stažené celou sérii.',
        'Press up and slightly back toward your face, keep shoulder blades squeezed the whole set.',
      ),
    ],
    mistakes: [
      tr('Odrážení osy od hrudníku.', 'Bouncing the bar off your chest.'),
      tr(
        'Lokty roztažené do stran v pravém úhlu (zátěž ramen).',
        'Elbows flared out at 90° (stresses shoulders).',
      ),
    ],
  ),
  'incline_press': (
    steps: [
      tr(
        'Lavici nastav na 30–45°. Lopatky stažené, hrudník vytažený nahoru.',
        'Set the bench to 30–45°. Shoulder blades squeezed, chest lifted.',
      ),
      tr(
        'Spouštěj osu pod klíční kosti, předloktí svisle.',
        'Lower the bar below your collarbones, forearms vertical.',
      ),
      tr(
        'Tlač nahoru nad ramena, dole krátce zastav.',
        'Press up over your shoulders, pause briefly at the bottom.',
      ),
    ],
    mistakes: [
      tr(
        'Příliš strmá lavice: práci převezmou ramena.',
        'Bench too steep: shoulders take over.',
      ),
      tr('Zvedání zadku z lavice.', 'Hips lifting off the bench.'),
    ],
  ),
  'chest_press_machine': (
    steps: [
      tr(
        'Sedák nastav tak, aby madla byla ve výšce středu hrudníku.',
        'Set the seat so handles are at mid-chest height.',
      ),
      tr(
        'Lopatky opři o opěradlo, tlač madla dopředu bez zamčení loktů.',
        'Pin shoulder blades against the backrest, press handles forward without locking elbows.',
      ),
      tr(
        'Vracej pomalu, dokud necítíš protažení hrudníku.',
        'Return slowly until you feel a chest stretch.',
      ),
    ],
    mistakes: ['Ramena se zvedají k uším.', 'Rychlé pouštění závaží zpět.'],
  ),
  'pec_deck': (
    steps: [
      tr(
        'Madla ve výšce ramen, lokty lehce pokrčené a zamčené v té poloze.',
        'Handles at shoulder height, elbows slightly bent and locked in that position.',
      ),
      tr(
        'Stahuj paže před sebe obloukem, jako bys objímal strom.',
        'Bring arms together in an arc in front of you, like hugging a tree.',
      ),
      tr(
        'Vracej pomalu do protažení, ramena drž vzadu.',
        'Return slowly to a stretch, keep shoulders back.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání loktů, z cviku se stane tlak.',
        'Bending elbows, turning it into a press.',
      ),
      tr('Hrbení ramen dopředu.', 'Rounding shoulders forward.'),
    ],
  ),
  'cable_fly': (
    steps: [
      tr(
        'Kladky nahoře, krok dopředu, mírný předklon a pevný střed těla.',
        'Pulleys high, step forward, slight lean and a braced core.',
      ),
      tr(
        'Lokty lehce pokrčené, táhni ruce obloukem dolů před sebe.',
        'Elbows slightly bent, bring hands down in an arc in front of you.',
      ),
      tr(
        'Dole krátce stiskni hrudník a pomalu se vrať.',
        'Squeeze your chest briefly at the bottom and return slowly.',
      ),
    ],
    mistakes: ['Tahání pažemi místo hrudníku.', 'Příliš velká váha a houpání.'],
  ),
  'squat': (
    steps: [
      tr(
        'Osa na trapézech, chodidla na šířku ramen, špičky mírně ven.',
        'Bar on your traps, feet shoulder-width apart, toes slightly out.',
      ),
      tr(
        'Nadechni se, zpevni břicho a jdi dolů s koleny ve směru špiček.',
        'Breathe in, brace your core, and go down with knees tracking over toes.',
      ),
      tr(
        'Jdi aspoň do stehen rovnoběžně se zemí a vytlač se celým chodidlem.',
        'Go at least to parallel and drive up through your whole foot.',
      ),
    ],
    mistakes: [
      tr('Kolena padají dovnitř.', 'Knees caving inward.'),
      tr(
        'Paty se zvedají, váha jde na špičky.',
        'Heels lifting, weight shifting to toes.',
      ),
    ],
  ),
  'leg_press': (
    steps: [
      tr(
        'Chodidla doprostřed plošiny na šířku ramen, záda celá na opěradle.',
        'Feet in the middle of the platform shoulder-width apart, back flat on the pad.',
      ),
      tr(
        'Spouštěj plošinu, dokud se nezačne odlepovat spodek zad.',
        'Lower the platform until your lower back starts to lift off.',
      ),
      tr(
        'Vytlač patami, kolena na konci nezamykej.',
        'Press through your heels, don\'t lock your knees at the top.',
      ),
    ],
    mistakes: [
      tr('Zadek se zvedá ze sedáku.', 'Hips lifting off the seat.'),
      tr(
        'Moc krátký pohyb s velkou váhou.',
        'Too short a range with too much weight.',
      ),
    ],
  ),
  'hack_squat': (
    steps: [
      tr(
        'Záda na opěrce, ramena pod polštáři, chodidla na šířku ramen.',
        'Back against the pad, shoulders under the pads, feet shoulder-width apart.',
      ),
      tr(
        'Jdi pomalu dolů, kolena smí jít před špičky.',
        'Go down slowly, knees can travel past toes.',
      ),
      tr(
        'Vytlač celým chodidlem, nahoře nezamykej kolena.',
        'Drive through the whole foot, don\'t lock knees at the top.',
      ),
    ],
    mistakes: [
      tr('Paty odlepené od plošiny.', 'Heels coming off the platform.'),
      tr('Poskakování v dolní poloze.', 'Bouncing at the bottom.'),
    ],
  ),
  'leg_extension': (
    steps: [
      tr(
        'Kolena v ose otáčení stroje, polštář nad kotníky.',
        'Knees aligned with the machine pivot, pad above the ankles.',
      ),
      tr(
        'Propni nohy a nahoře na chvilku stáhni stehna.',
        'Extend your legs and squeeze your quads briefly at the top.',
      ),
      tr(
        'Spouštěj pomalu, závaží nenech dosednout.',
        'Lower slowly, don\'t let the stack slam down.',
      ),
    ],
    mistakes: [
      tr('Švihání a zvedání zadku.', 'Swinging and lifting hips off the seat.'),
      tr('Rychlé spouštění.', 'Dropping the weight quickly.'),
    ],
  ),
  'leg_curl': (
    steps: [
      tr(
        'Lehni si, kolena těsně za hranou lavice, polštář nad patami.',
        'Lie down with knees just off the pad edge, pad above your heels.',
      ),
      tr(
        'Přitáhni paty k zadku, boky drž na lavici.',
        'Curl your heels toward your glutes, keep hips on the bench.',
      ),
      tr(
        'Spouštěj pomalu až skoro do propnutí.',
        'Lower slowly until almost fully extended.',
      ),
    ],
    mistakes: [
      tr('Zvedání boků.', 'Hips rising off the bench.'),
      tr('Krátký pohyb jen v horní části.', 'Short range only at the top.'),
    ],
  ),
  'romanian_deadlift': (
    steps: [
      tr(
        'Stoj na šířku boků, osa u stehen, kolena lehce pokrčená.',
        'Stand hip-width apart, bar at your thighs, knees slightly bent.',
      ),
      tr(
        'Posílej boky dozadu, osa klouže po nohou, záda rovná.',
        'Push hips back, bar slides down your legs, back flat.',
      ),
      tr(
        'Jdi, dokud cítíš tah v zadních stehnech, a vrať se vytlačením boků.',
        'Go until you feel hamstring stretch, then drive hips forward to return.',
      ),
    ],
    mistakes: [
      tr('Kulatá záda.', 'Rounded back.'),
      tr(
        'Dřep místo předklonu: kolena se moc ohýbají.',
        'Squatting instead of hinging: knees bending too much.',
      ),
    ],
  ),
  'calf_raise': (
    steps: [
      tr(
        'Špičky na hraně, paty volně dolů, kolena téměř propnutá.',
        'Balls of feet on the edge, heels hanging down, knees almost straight.',
      ),
      tr(
        'Vytlač se co nejvýš na špičky a chvilku podrž.',
        'Press up as high as you can and hold briefly.',
      ),
      tr(
        'Spouštěj pomalu do protažení lýtek.',
        'Lower slowly into a calf stretch.',
      ),
    ],
    mistakes: [
      tr('Pérování bez zastavení.', 'Bouncing with no pause.'),
      tr('Malý rozsah pohybu.', 'Short range of motion.'),
    ],
  ),
  'deadlift': (
    steps: [
      tr(
        'Osa nad středem chodidla, uchop ji těsně vedle nohou.',
        'Bar over mid-foot, grip just outside your legs.',
      ),
      tr(
        'Boky dolů, hrudník nahoru, záda rovná, napni paže a vytáhni vůli z osy.',
        'Hips down, chest up, back flat, brace and pull the slack out of the bar.',
      ),
      tr(
        'Zvedej tlakem nohou do země, osa jde těsně po nohou, nahoře propni boky.',
        'Push the floor away, bar stays close to legs, lock hips at the top.',
      ),
    ],
    mistakes: [
      tr('Kulatá záda.', 'Rounded back.'),
      tr('Osa daleko od těla.', 'Bar drifting away from body.'),
    ],
  ),
  'lat_pulldown': (
    steps: [
      tr(
        'Úchop o něco širší než ramena, stehna pod polštáři.',
        'Grip slightly wider than shoulders, thighs under the pads.',
      ),
      tr(
        'Stáhni lopatky dolů a táhni osu k hornímu hrudníku, lokty k bokům.',
        'Pull shoulder blades down and bring the bar to upper chest, elbows to hips.',
      ),
      tr(
        'Vracej pomalu nahoru do plného natažení.',
        'Return slowly to a full stretch.',
      ),
    ],
    mistakes: [
      tr('Záklon a houpání trupem.', 'Leaning back and swinging.'),
      tr('Tahání za hlavu.', 'Pulling behind the neck.'),
    ],
  ),
  'seated_row': (
    steps: [
      tr(
        'Sedni si, kolena lehce pokrčená, záda rovná.',
        'Sit with knees slightly bent, back straight.',
      ),
      tr(
        'Táhni madlo k pupku, lopatky stáhni k sobě.',
        'Pull the handle to your navel, squeeze shoulder blades together.',
      ),
      tr(
        'Vracej pomalu a nech lopatky jít dopředu, záda zůstávají rovná.',
        'Return slowly and let shoulder blades spread, back stays straight.',
      ),
    ],
    mistakes: [
      tr('Houpání trupem dozadu.', 'Swinging torso back.'),
      tr('Ramena se zvedají k uším.', 'Shoulders shrugging up.'),
    ],
  ),
  'chest_supported_row': (
    steps: [
      tr(
        'Lehni si hrudníkem na šikmou lavici, činky volně dolů.',
        'Lie chest-down on an incline bench, dumbbells hanging.',
      ),
      tr(
        'Přitáhni činky k bokům, lopatky k sobě.',
        'Pull dumbbells to your hips, squeeze shoulder blades.',
      ),
      tr(
        'Spouštěj pomalu do natažení paží.',
        'Lower slowly to full arm extension.',
      ),
    ],
    mistakes: [
      tr('Zvedání hrudníku z lavice.', 'Lifting chest off the bench.'),
      tr('Tahání jen rukama.', 'Pulling with arms only.'),
    ],
  ),
  'pull_up': (
    steps: [
      tr(
        'Úchop nadhmatem o něco širší než ramena, plný vis.',
        'Overhand grip slightly wider than shoulders, full hang.',
      ),
      tr(
        'Stáhni lopatky dolů a přitáhni se, až je brada nad hrazdou.',
        'Pull shoulder blades down and pull until chin is over the bar.',
      ),
      tr(
        'Spouštěj se pomalu až do propnutých paží.',
        'Lower slowly to full arm extension.',
      ),
    ],
    mistakes: [
      tr('Kopání nohama.', 'Kipping legs.'),
      tr(
        'Poloviční opakování bez plného visu.',
        'Half reps without a full hang.',
      ),
    ],
  ),
  'shoulder_press': (
    steps: [
      tr(
        'Sedák nastav tak, aby madla byla ve výšce ramen.',
        'Set the seat so handles are at shoulder height.',
      ),
      tr(
        'Tlač nahoru bez zamčení loktů, záda opřená.',
        'Press up without locking elbows, back against the pad.',
      ),
      tr('Spouštěj pomalu k výšce uší.', 'Lower slowly to ear height.'),
    ],
    mistakes: ['Prohýbání v bedrech.', 'Moc krátký pohyb.'],
  ),
  'lateral_raise': (
    steps: [
      tr(
        'Stoj, činky u boků, lokty lehce pokrčené.',
        'Stand with dumbbells at your sides, elbows slightly bent.',
      ),
      tr(
        'Zvedej paže do stran do výšky ramen, malíček lehce nahoru.',
        'Raise arms out to the sides to shoulder height, pinky slightly up.',
      ),
      tr(
        'Spouštěj pomalu, nahoře nezvedej ramena.',
        'Lower slowly, don\'t shrug shoulders at the top.',
      ),
    ],
    mistakes: [
      tr('Švihání trupem.', 'Swinging the torso.'),
      tr(
        'Zvedání nad výšku ramen se zvednutými trapézy.',
        'Raising above shoulder height with shrugged traps.',
      ),
    ],
  ),
  'reverse_pec_deck': (
    steps: [
      tr(
        'Sedni si čelem ke stroji, madla ve výšce ramen.',
        'Sit facing the machine, handles at shoulder height.',
      ),
      tr(
        'Roztahuj paže obloukem dozadu, lokty lehce pokrčené.',
        'Open your arms in an arc backward, elbows slightly bent.',
      ),
      tr(
        'Vracej pomalu, hrudník opřený.',
        'Return slowly, chest against the pad.',
      ),
    ],
    mistakes: [
      tr(
        'Stahování lopatek místo práce zadních delt.',
        'Squeezing shoulder blades instead of working rear delts.',
      ),
      tr('Trhání závažím.', 'Jerking the weight.'),
    ],
  ),
  'biceps_curl': (
    steps: [
      tr(
        'Stoj, činky u stehen, dlaně dopředu, lokty u těla.',
        'Stand with dumbbells at your thighs, palms forward, elbows at your sides.',
      ),
      tr(
        'Ohni paže a zvedni činky k ramenům, lokty zůstávají na místě.',
        'Curl dumbbells up to your shoulders, elbows stay in place.',
      ),
      tr('Spouštěj pomalu až do propnutí.', 'Lower slowly to full extension.'),
    ],
    mistakes: ['Švihání trupem.', 'Lokty jdou dopředu.'],
  ),
  'preacher_curl': (
    steps: [
      tr(
        'Paže celé na opěrce, podpaží na její hraně.',
        'Arms fully on the pad, armpits at its edge.',
      ),
      tr(
        'Ohni paže a zvedni osu, nahoře stiskni biceps.',
        'Curl the bar up, squeeze biceps at the top.',
      ),
      tr(
        'Spouštěj pomalu skoro do propnutí.',
        'Lower slowly almost to full extension.',
      ),
    ],
    mistakes: ['Zvedání loktů z opěrky.', 'Pouštění dolů bez kontroly.'],
  ),
  'triceps_pushdown': (
    steps: [
      tr(
        'Kladka nahoře, lokty u boků, mírný předklon.',
        'Pulley high, elbows at your sides, slight lean forward.',
      ),
      tr(
        'Tlač dolů do propnutí loktů a dole stiskni triceps.',
        'Press down to full elbow extension and squeeze triceps at the bottom.',
      ),
      tr(
        'Vracej, dokud předloktí nejsou zhruba vodorovně.',
        'Return until forearms are roughly horizontal.',
      ),
    ],
    mistakes: ['Lokty se hýbou dopředu a dozadu.', 'Dotlačování vahou těla.'],
  ),
  'dips': (
    steps: [
      tr(
        'Opři se o bradla s propnutými pažemi, trup spíš svisle.',
        'Support yourself on parallel bars with arms extended, torso mostly upright.',
      ),
      tr(
        'Spouštěj se, až jsou ramena zhruba v úrovni loktů.',
        'Lower until shoulders are roughly at elbow level.',
      ),
      tr('Vytlač se nahoru do propnutí.', 'Press back up to full extension.'),
    ],
    mistakes: ['Moc hluboko s bolestí ramen.', 'Ramena se zvedají k uším.'],
  ),
  'ab_crunch': (
    steps: [
      tr(
        'Nastav sedák, madla drž u hrudníku.',
        'Set the seat, hold handles at your chest.',
      ),
      tr(
        'Stáhni žebra k pánvi, jako by ses stáčel do klubíčka.',
        'Pull ribs toward pelvis, like curling into a ball.',
      ),
      tr(
        'Vracej pomalu, závaží nenech dosednout.',
        'Return slowly, don\'t let the weight stack rest.',
      ),
    ],
    mistakes: ['Tahání rukama.', 'Ohýbání v bocích místo stočení páteře.'],
  ),
  'dumbbell_bench_press': (
    steps: [
      tr(
        'Lehni si s činkami nad hrudníkem, lopatky stažené.',
        'Lie down with dumbbells over your chest, shoulder blades squeezed.',
      ),
      tr(
        'Spouštěj činky po stranách hrudníku, lokty asi 45° od těla.',
        'Lower dumbbells along the sides of your chest, elbows about 45° from body.',
      ),
      tr(
        'Tlač nahoru k sobě, nahoře se činky nemusí dotknout.',
        'Press up and slightly together, dumbbells don\'t need to touch at the top.',
      ),
    ],
    mistakes: ['Moc rychlé spouštění.', 'Ztráta napětí v lopatkách.'],
  ),
  'incline_dumbbell_press': (
    steps: [
      tr(
        'Lavice na 30–45°, činky nad horním hrudníkem.',
        'Bench at 30–45°, dumbbells over upper chest.',
      ),
      tr(
        'Spouštěj činky k horní části hrudníku, lokty mírně pod rameny.',
        'Lower dumbbells to upper chest, elbows slightly below shoulders.',
      ),
      tr(
        'Tlač nahoru, dole krátce zastav.',
        'Press up, pause briefly at the bottom.',
      ),
    ],
    mistakes: ['Příliš strmá lavice.', 'Lokty roztažené do stran.'],
  ),
  'push_up': (
    steps: [
      tr(
        'Ruce o něco širší než ramena, tělo v jedné rovině od hlavy k patám.',
        'Hands slightly wider than shoulders, body in a straight line from head to heels.',
      ),
      tr(
        'Spouštěj hrudník k zemi, lokty asi 45° od těla.',
        'Lower your chest to the floor, elbows about 45° from body.',
      ),
      tr(
        'Vytlač se do propnutých paží, břicho drž zpevněné.',
        'Press up to straight arms, keep core braced.',
      ),
    ],
    mistakes: ['Propadlá nebo vystrčená pánev.', 'Poloviční rozsah.'],
  ),
  'front_squat': (
    steps: [
      tr(
        'Osa na předních deltech, lokty vysoko dopředu.',
        'Bar on front delts, elbows high in front.',
      ),
      tr(
        'Jdi dolů se vzpřímeným trupem, kolena ve směru špiček.',
        'Go down with an upright torso, knees tracking over toes.',
      ),
      tr(
        'Vytlač se nahoru, lokty pořád vysoko.',
        'Drive up, keep elbows high.',
      ),
    ],
    mistakes: ['Padající lokty a předklon.', 'Paty se zvedají.'],
  ),
  'goblet_squat': (
    steps: [
      tr(
        'Činku nebo kettlebell drž u hrudníku, chodidla na šířku ramen.',
        'Hold a dumbbell or kettlebell at your chest, feet shoulder-width apart.',
      ),
      tr(
        'Jdi do dřepu mezi kolena, trup vzpřímený.',
        'Squat down between your knees, torso upright.',
      ),
      tr('Vytlač se patami nahoru.', 'Drive up through your heels.'),
    ],
    mistakes: ['Kolena padají dovnitř.', 'Kulatá záda dole.'],
  ),
  'smith_squat': (
    steps: [
      tr(
        'Chodidla mírně před osou, osa na trapézech.',
        'Feet slightly in front of the bar, bar on your traps.',
      ),
      tr(
        'Jdi dolů pod kontrolou, kolena ve směru špiček.',
        'Go down under control, knees tracking over toes.',
      ),
      tr(
        'Vytlač se celým chodidlem nahoru.',
        'Drive up through your whole foot.',
      ),
    ],
    mistakes: ['Chodidla přímo pod osou: tlak na kolena.', 'Malý rozsah.'],
  ),
  'hip_thrust': (
    steps: [
      tr(
        'Lopatky na hraně lavice, osa v ohybu boků (s podložkou).',
        'Shoulder blades on the bench edge, bar in the hip crease (with padding).',
      ),
      tr(
        'Vytlač boky nahoru patami, brada u hrudníku.',
        'Drive hips up through your heels, chin tucked.',
      ),
      tr(
        'Nahoře stiskni hýždě a pomalu spouštěj.',
        'Squeeze glutes at the top and lower slowly.',
      ),
    ],
    mistakes: [
      tr(
        'Prohnutí v bedrech nahoře.',
        'Hyperextending the lower back at the top.',
      ),
      tr('Chodidla moc daleko nebo blízko.', 'Feet too far or too close.'),
    ],
  ),
  'bulgarian_split_squat': (
    steps: [
      tr(
        'Zadní noha nártem na lavici, přední chodidlo asi krok před ní.',
        'Back foot on the bench with laces down, front foot about a step ahead.',
      ),
      tr(
        'Jdi dolů svisle, přední koleno ve směru špičky.',
        'Lower straight down, front knee tracking over toes.',
      ),
      tr(
        'Vytlač se přední patou, pak vystřídej nohy.',
        'Drive up through the front heel, then switch legs.',
      ),
    ],
    mistakes: ['Přední chodidlo moc blízko lavice.', 'Kolíbání do stran.'],
  ),
  'walking_lunge': (
    steps: [
      tr(
        'Udělej dlouhý krok vpřed, trup vzpřímený.',
        'Take a long step forward, torso upright.',
      ),
      tr(
        'Zadní koleno spusť těsně nad zem.',
        'Lower your back knee just above the floor.',
      ),
      tr(
        'Odraz se přední patou a krokem pokračuj druhou nohou.',
        'Push off the front heel and continue stepping with the other leg.',
      ),
    ],
    mistakes: [
      tr(
        'Krátké kroky, koleno daleko před špičkou.',
        'Short steps, knee far past toes.',
      ),
      tr('Koleno padá dovnitř.', 'Knee caving inward.'),
    ],
  ),
  'seated_calf_raise': (
    steps: [
      tr(
        'Polštář na stehnech těsně nad koleny, špičky na hraně.',
        'Pad on thighs just above knees, balls of feet on the edge.',
      ),
      tr(
        'Zvedni paty co nejvýš a chvilku podrž.',
        'Raise heels as high as you can and hold briefly.',
      ),
      tr('Spouštěj pomalu do protažení.', 'Lower slowly into a stretch.'),
    ],
    mistakes: ['Pérování.', 'Malý rozsah.'],
  ),
  'barbell_row': (
    steps: [
      tr(
        'Předklon asi 45°, záda rovná, kolena lehce pokrčená.',
        'Hinge forward about 45°, back flat, knees slightly bent.',
      ),
      tr(
        'Přitáhni osu ke spodní části břicha, lokty podél těla.',
        'Pull the bar to your lower belly, elbows along your body.',
      ),
      tr(
        'Spouštěj pomalu do natažených paží.',
        'Lower slowly to straight arms.',
      ),
    ],
    mistakes: ['Zvedání trupu při každém opakování.', 'Kulatá záda.'],
  ),
  'dumbbell_row': (
    steps: [
      tr(
        'Ruka a koleno na lavici, záda rovná, činka visí dolů.',
        'Hand and knee on the bench, back flat, dumbbell hanging down.',
      ),
      tr(
        'Přitáhni činku k boku, loket podél těla.',
        'Pull the dumbbell to your hip, elbow along your body.',
      ),
      tr(
        'Spouštěj pomalu do protažení zad.',
        'Lower slowly into a lat stretch.',
      ),
    ],
    mistakes: ['Rotace trupu.', 'Tahání k rameni místo k boku.'],
  ),
  'close_grip_pulldown': (
    steps: [
      tr(
        'Úzké madlo, stehna pod polštáři, mírný záklon.',
        'Narrow handle, thighs under pads, slight lean back.',
      ),
      tr(
        'Stáhni lopatky a táhni madlo k hrudníku, lokty k bokům.',
        'Pull shoulder blades down and bring handle to chest, elbows to hips.',
      ),
      tr(
        'Vracej pomalu do plného natažení.',
        'Return slowly to a full stretch.',
      ),
    ],
    mistakes: ['Velký záklon a houpání.', 'Tahání jen rukama.'],
  ),
  'machine_row': (
    steps: [
      tr(
        'Hrudník opřený o polštář, madla na dosah.',
        'Chest against the pad, handles within reach.',
      ),
      tr(
        'Táhni madla k tělu, lopatky k sobě.',
        'Pull handles toward your body, shoulder blades together.',
      ),
      tr('Vracej pomalu do natažení.', 'Return slowly to a stretch.'),
    ],
    mistakes: ['Odlepování hrudníku.', 'Ramena se zvedají.'],
  ),
  'face_pull': (
    steps: [
      tr(
        'Lano na kladce ve výšce obličeje, úchop palci dozadu.',
        'Rope at face height, grip with thumbs pointing back.',
      ),
      tr(
        'Táhni lano k obličeji a roztáhni ruce do stran za uši.',
        'Pull rope to your face and spread hands to the sides behind ears.',
      ),
      tr(
        'Vracej pomalu, lokty drž vysoko.',
        'Return slowly, keep elbows high.',
      ),
    ],
    mistakes: ['Lokty padají dolů.', 'Záklon trupem.'],
  ),
  'overhead_press': (
    steps: [
      tr(
        'Osa na předních ramenech, úchop o něco širší než ramena.',
        'Bar on front shoulders, grip slightly wider than shoulders.',
      ),
      tr(
        'Zpevni břicho a hýždě a tlač osu nad hlavu, hlavu uhni dozadu.',
        'Brace core and glutes and press the bar overhead, move head back.',
      ),
      tr(
        'Nahoře hlavu vrať pod osu, spouštěj pomalu.',
        'Bring head back under the bar at top, lower slowly.',
      ),
    ],
    mistakes: ['Prohýbání v bedrech.', 'Osa jde před obličejem dopředu.'],
  ),
  'dumbbell_shoulder_press': (
    steps: [
      tr(
        'Sedni si se zády opřenými, činky u uší.',
        'Sit with back supported, dumbbells at ear height.',
      ),
      tr(
        'Tlač nahoru nad hlavu, nahoře se činky skoro dotknou.',
        'Press up overhead, dumbbells almost touch at top.',
      ),
      tr('Spouštěj pomalu do výšky uší.', 'Lower slowly to ear height.'),
    ],
    mistakes: ['Prohnutá záda.', 'Krátký pohyb.'],
  ),
  'cable_lateral_raise': (
    steps: [
      tr(
        'Kladka dole, madlo v ruce dál od kladky.',
        'Pulley low, handle in the hand farthest from the pulley.',
      ),
      tr(
        'Zvedej paži do strany do výšky ramen.',
        'Raise your arm out to the side to shoulder height.',
      ),
      tr(
        'Spouštěj pomalu, napětí kabelu drž celou dobu.',
        'Lower slowly, keep cable tension the whole time.',
      ),
    ],
    mistakes: ['Naklánění trupu.', 'Zvedání ramene k uchu.'],
  ),
  'rear_delt_fly': (
    steps: [
      tr(
        'Předklon skoro vodorovně, činky pod hrudníkem.',
        'Hinge almost horizontal, dumbbells under your chest.',
      ),
      tr(
        'Roztahuj paže do stran, lokty lehce pokrčené.',
        'Open arms out to the sides, elbows slightly bent.',
      ),
      tr(
        'Spouštěj pomalu, lopatky moc nestahuj.',
        'Lower slowly, don\'t over-squeeze shoulder blades.',
      ),
    ],
    mistakes: ['Švihání trupem.', 'Velká váha, práci převezmou záda.'],
  ),
  'barbell_curl': (
    steps: [
      tr(
        'Stoj, osa podhmatem na šířku ramen, lokty u těla.',
        'Stand, bar underhand at shoulder width, elbows at your sides.',
      ),
      tr(
        'Zvedni osu k ramenům bez pohybu loktů.',
        'Curl the bar to your shoulders without moving elbows.',
      ),
      tr('Spouštěj pomalu až do propnutí.', 'Lower slowly to full extension.'),
    ],
    mistakes: ['Záklon a švih.', 'Neúplné spouštění.'],
  ),
  'hammer_curl': (
    steps: [
      tr(
        'Činky u boků, dlaně k sobě.',
        'Dumbbells at your sides, palms facing each other.',
      ),
      tr(
        'Zvedej činky k ramenům, dlaně pořád k sobě.',
        'Curl dumbbells to shoulders, palms still facing each other.',
      ),
      tr(
        'Spouštěj pomalu, lokty zůstávají u těla.',
        'Lower slowly, elbows stay at your sides.',
      ),
    ],
    mistakes: ['Švihání.', 'Lokty jdou dopředu.'],
  ),
  'cable_curl': (
    steps: [
      tr(
        'Kladka dole, rovné madlo podhmatem, lokty u těla.',
        'Low pulley, straight bar underhand, elbows at your sides.',
      ),
      tr(
        'Zvedej madlo k ramenům, nahoře stiskni biceps.',
        'Curl handle to shoulders, squeeze biceps at the top.',
      ),
      tr(
        'Spouštěj pomalu, napětí drž dole.',
        'Lower slowly, keep tension at the bottom.',
      ),
    ],
    mistakes: ['Předklon a záklon trupu.', 'Lokty se posouvají.'],
  ),
  'overhead_triceps_extension': (
    steps: [
      tr(
        'Lano za hlavou, otoč se zády ke kladce, lokty u hlavy.',
        'Rope behind your head, face away from the pulley, elbows by your head.',
      ),
      tr('Propni paže dopředu nad hlavu.', 'Extend arms forward overhead.'),
      tr(
        'Vracej pomalu do protažení tricepsu.',
        'Return slowly into a triceps stretch.',
      ),
    ],
    mistakes: ['Lokty se rozjíždějí do stran.', 'Prohnutí v bedrech.'],
  ),
  'skull_crusher': (
    steps: [
      tr(
        'Lehni si s osou nad rameny, paže svisle.',
        'Lie down with the bar over your shoulders, arms vertical.',
      ),
      tr(
        'Spouštěj osu za čelo jen pohybem v loktech.',
        'Lower the bar behind your forehead using only elbow movement.',
      ),
      tr('Propni paže zpět nahoru.', 'Extend arms back up.'),
    ],
    mistakes: ['Lokty jdou do stran.', 'Pohyb v ramenou místo loktů.'],
  ),
  'cable_crunch': (
    steps: [
      tr(
        'Klekni si pod kladku, lano drž u hlavy.',
        'Kneel under the pulley, hold the rope at your head.',
      ),
      tr(
        'Stoč trup dolů, žebra k pánvi.',
        'Curl your torso down, ribs toward pelvis.',
      ),
      tr(
        'Vracej pomalu, boky drž na místě.',
        'Return slowly, keep hips in place.',
      ),
    ],
    mistakes: ['Sedání na paty.', 'Tahání rukama.'],
  ),
  'hanging_leg_raise': (
    steps: [
      tr(
        'Vis na hrazdě, ramena aktivní, nohy u sebe.',
        'Hang from the bar, shoulders active, legs together.',
      ),
      tr(
        'Zvedni nohy (nebo kolena) a podsaď pánev.',
        'Raise legs (or knees) and tilt pelvis up.',
      ),
      tr('Spouštěj pomalu bez houpání.', 'Lower slowly without swinging.'),
    ],
    mistakes: [
      tr('Houpání tělem.', 'Swinging the body.'),
      tr(
        'Zvedání jen do vodorovné bez podsazení pánve.',
        'Lifting only to horizontal without tilting pelvis.',
      ),
    ],
  ),
  'incline_dumbbell_curl': (
    steps: [
      tr(
        'Lavice na 45–60°, paže volně dolů za tělem.',
        'Bench at 45–60°, arms hanging down behind your body.',
      ),
      tr(
        'Zvedej činky, lokty zůstávají vzadu.',
        'Curl dumbbells up, elbows stay back.',
      ),
      tr(
        'Spouštěj pomalu do plného protažení.',
        'Lower slowly to a full stretch.',
      ),
    ],
    mistakes: ['Lokty jdou dopředu.', 'Zvedání ramen z opěradla.'],
  ),
  'low_to_high_cable_fly': (
    steps: [
      tr(
        'Kladky dole, krok dopředu, lokty lehce pokrčené.',
        'Pulleys low, step forward, elbows slightly bent.',
      ),
      tr(
        'Veď ruce obloukem nahoru před sebe do výšky brady.',
        'Bring hands up in an arc in front of you to chin height.',
      ),
      tr(
        'Vracej pomalu dolů do protažení.',
        'Return slowly down into a stretch.',
      ),
    ],
    mistakes: ['Ohýbání loktů.', 'Zvedání ramen.'],
  ),
  'shrug': (
    steps: [
      tr(
        'Stoj s osou nebo činkami u stehen.',
        'Stand with a bar or dumbbells at your thighs.',
      ),
      tr(
        'Zvedni ramena rovně nahoru k uším a chvilku podrž.',
        'Shrug shoulders straight up to your ears and hold briefly.',
      ),
      tr('Spouštěj pomalu.', 'Lower slowly.'),
    ],
    mistakes: ['Kroužení rameny.', 'Ohýbání loktů.'],
  ),
  'back_extension': (
    steps: [
      tr(
        'Boky na polštáři, paty zaklesnuté, ruce na hrudníku.',
        'Hips on the pad, heels hooked, hands on your chest.',
      ),
      tr('Předkloň se s rovnými zády.', 'Hinge forward with a flat back.'),
      tr(
        'Zvedni trup do roviny s nohama, nezaklánej se dál.',
        'Raise torso to line up with legs, don\'t hyperextend further.',
      ),
    ],
    mistakes: ['Přeprohnutí nahoře.', 'Trhavý pohyb.'],
  ),
  'calf_press': (
    steps: [
      tr(
        'Špičky na spodní hraně plošiny, nohy téměř propnuté.',
        'Balls of feet on the lower edge of the platform, legs almost straight.',
      ),
      tr(
        'Tlač špičkami co nejdál a chvilku podrž.',
        'Press through toes as far as you can and hold briefly.',
      ),
      tr(
        'Vracej pomalu do protažení lýtek.',
        'Return slowly into a calf stretch.',
      ),
    ],
    mistakes: ['Ohýbání kolen.', 'Pérování.'],
  ),
  'reverse_curl': (
    steps: [
      tr(
        'Osa nadhmatem na šířku ramen, lokty u těla.',
        'Bar overhand at shoulder width, elbows at your sides.',
      ),
      tr(
        'Zvedej osu k ramenům, zápěstí rovná.',
        'Curl the bar to your shoulders, wrists straight.',
      ),
      tr('Spouštěj pomalu.', 'Lower slowly.'),
    ],
    mistakes: ['Ohnutá zápěstí.', 'Švihání.'],
  ),
  'lying_leg_raise': (
    steps: [
      tr(
        'Lehni si na záda, ruce pod hýždě nebo vedle těla.',
        'Lie on your back, hands under hips or by your sides.',
      ),
      tr(
        'Zvedni nohy do svislé polohy, spodek zad tlač do podložky.',
        'Raise legs to vertical, press lower back into the floor.',
      ),
      tr(
        'Spouštěj pomalu těsně nad zem.',
        'Lower slowly just above the floor.',
      ),
    ],
    mistakes: ['Prohnutí v bedrech.', 'Spouštění volným pádem.'],
  ),
  'decline_bench_press': (
    steps: [
      tr(
        'Zaklesni nohy, lavice mírně dolů, lopatky stažené.',
        'Hook your feet, bench slightly declined, shoulder blades squeezed.',
      ),
      tr(
        'Spouštěj osu na spodní okraj hrudníku, lokty asi 45° od těla.',
        'Lower the bar to the lower edge of your chest, elbows about 45° from body.',
      ),
      tr(
        'Vytlač nahoru nad hrudník, dole bez odrazu.',
        'Press up over your chest, no bounce at the bottom.',
      ),
    ],
    mistakes: ['Moc strmý sklon a krev do hlavy.', 'Odrážení osy od hrudníku.'],
  ),
  'smith_bench_press': (
    steps: [
      tr(
        'Lavici posuň tak, aby osa dosedala na spodní část hrudníku.',
        'Position the bench so the bar lands on your lower chest.',
      ),
      tr(
        'Lopatky stažené, odjisti osu otočením zápěstí.',
        'Shoulder blades squeezed, unrack the bar by rotating wrists.',
      ),
      tr(
        'Spouštěj pod kontrolou a tlač nahoru, nahoře znovu zajisti.',
        'Lower with control and press up, rerack at the top.',
      ),
    ],
    mistakes: [
      tr(
        'Lavice posunutá, osa jde na krk.',
        'Bench misaligned, bar heading toward neck.',
      ),
      tr('Zamykání loktů s plnou silou.', 'Locking elbows hard.'),
    ],
  ),
  'smith_incline_press': (
    steps: [
      tr(
        'Šikmou lavici na 30° postav pod osu tak, aby šla pod klíční kosti.',
        'Set an incline bench at 30° under the bar so it lands below collarbones.',
      ),
      tr(
        'Lopatky stažené, odjisti osu.',
        'Shoulder blades squeezed, unrack the bar.',
      ),
      tr(
        'Spouštěj ke klíčním kostem, tlač nahoru a nahoře zajisti.',
        'Lower to collarbones, press up and rerack at the top.',
      ),
    ],
    mistakes: ['Lavice moc strmá, pracují ramena.', 'Zvedání zadku z lavice.'],
  ),
  'incline_chest_press_machine': (
    steps: [
      tr(
        'Sedák nastav, aby madla byla ve výšce horního hrudníku.',
        'Set the seat so handles are at upper-chest height.',
      ),
      tr(
        'Lopatky opři o opěradlo a tlač madla šikmo nahoru.',
        'Pin shoulder blades against the backrest and press handles up at an angle.',
      ),
      tr('Vracej pomalu do protažení.', 'Return slowly into a stretch.'),
    ],
    mistakes: ['Ramena se zvedají k uším.', 'Krátký rozsah bez protažení.'],
  ),
  'cable_chest_press': (
    steps: [
      tr(
        'Kladky ve výšce hrudníku, krok dopředu, stabilní postoj.',
        'Pulleys at chest height, step forward, stable stance.',
      ),
      tr(
        'Tlač madla před sebe, ruce se k sobě sbíhají.',
        'Press handles forward, hands converge toward each other.',
      ),
      tr(
        'Vracej pomalu, lokty mírně pod úrovní ramen.',
        'Return slowly, elbows slightly below shoulder level.',
      ),
    ],
    mistakes: [
      tr(
        'Prohnutá bedra a ztráta rovnováhy.',
        'Overarched lower back and loss of balance.',
      ),
      tr(
        'Tah rukama místo tlaku hrudníkem.',
        'Pulling with hands instead of pressing with chest.',
      ),
    ],
  ),
  'dumbbell_fly': (
    steps: [
      tr(
        'Lehni na rovnou lavici, činky nad hrudníkem, lokty lehce pokrčené.',
        'Lie on a flat bench, dumbbells over chest, elbows slightly bent.',
      ),
      tr(
        'Rozpažuj obloukem dolů, dokud necítíš protažení hrudníku.',
        'Open arms down in an arc until you feel a chest stretch.',
      ),
      tr(
        'Stejným obloukem stáhni ruce zpět nahoru.',
        'Bring hands back up along the same arc.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání loktů, cvik se mění v tlak.',
        'Bending elbows, turning it into a press.',
      ),
      tr('Příliš hluboko a bolest ramen.', 'Going too deep and shoulder pain.'),
    ],
  ),
  'incline_dumbbell_fly': (
    steps: [
      tr(
        'Lavice na 30°, činky nad horním hrudníkem.',
        'Bench at 30°, dumbbells over upper chest.',
      ),
      tr(
        'Rozpažuj obloukem s pevně pokrčenými lokty.',
        'Open arms in an arc with elbows fixed slightly bent.',
      ),
      tr(
        'Stáhni zpět nahoru, nahoře nezamykej.',
        'Bring back up, don\'t lock out at the top.',
      ),
    ],
    mistakes: ['Moc těžká váha a krátký rozsah.', 'Ramena dopředu.'],
  ),
  'chest_dips': (
    steps: [
      tr(
        'Opři se na bradlech, nakloň trup dopředu, lokty mírně od těla.',
        'Support yourself on parallel bars, lean torso forward, elbows slightly out.',
      ),
      tr(
        'Spouštěj se, dokud nejsou ramena těsně pod lokty.',
        'Lower until shoulders are just below elbows.',
      ),
      tr(
        'Vytlač se nahoru, trup drž v předklonu.',
        'Press up, keep torso leaning forward.',
      ),
    ],
    mistakes: [
      tr(
        'Příliš hluboký sed a bolest ramen.',
        'Going too deep and shoulder pain.',
      ),
      tr(
        'Rovný trup: práci přebírá triceps.',
        'Upright torso: triceps take over.',
      ),
    ],
  ),
  'dumbbell_pullover': (
    steps: [
      tr(
        'Lehni napříč nebo podél lavice, činku drž oběma rukama nad hrudníkem.',
        'Lie across or along a bench, hold a dumbbell with both hands over chest.',
      ),
      tr(
        'Lehce pokrčenými pažemi spouštěj činku obloukem za hlavu.',
        'With slightly bent arms, lower the dumbbell in an arc behind your head.',
      ),
      tr(
        'Vrať ji stejným obloukem nad hrudník.',
        'Return it along the same arc over your chest.',
      ),
    ],
    mistakes: ['Ohýbání loktů jako u francouzského tlaku.', 'Prohýbání beder.'],
  ),
  't_bar_row': (
    steps: [
      tr(
        'Hrudník na opěrku nebo předklon s rovnými zády, úchop madel.',
        'Chest on the pad or hinge with flat back, grip the handles.',
      ),
      tr(
        'Táhni madla k břichu, lopatky k sobě.',
        'Pull handles to your belly, shoulder blades together.',
      ),
      tr(
        'Spouštěj pomalu do natažení paží.',
        'Lower slowly to full arm extension.',
      ),
    ],
    mistakes: ['Kulatá záda.', 'Švihání trupem.'],
  ),
  'pendlay_row': (
    steps: [
      tr(
        'Předklon téměř do vodorovna, osa leží na zemi.',
        'Hinge almost horizontal, bar resting on the floor.',
      ),
      tr(
        'Výbušně přitáhni osu ke spodní části hrudníku.',
        'Explosively pull the bar to your lower chest.',
      ),
      tr(
        'Polož osu zpět na zem, každé opakování znovu.',
        'Set the bar back on the floor, reset each rep.',
      ),
    ],
    mistakes: ['Zvedání trupu při tahu.', 'Kulatá bedra.'],
  ),
  'machine_pulldown': (
    steps: [
      tr(
        'Kolena pod válce, úchop madel.',
        'Knees under the pads, grip the handles.',
      ),
      tr(
        'Stahuj madla k horní části hrudníku, lokty dolů.',
        'Pull handles to your upper chest, elbows down.',
      ),
      tr(
        'Vracej pomalu do plného natažení.',
        'Return slowly to a full stretch.',
      ),
    ],
    mistakes: ['Zaklánění trupu.', 'Krátký rozsah nahoře.'],
  ),
  'single_arm_pulldown': (
    steps: [
      tr(
        'Madlo nad hlavou, sedni nebo klekni bokem k ose kladky.',
        'Handle overhead, sit or kneel sideways to the pulley line.',
      ),
      tr(
        'Táhni loket dolů k boku, lopatka jde dolů.',
        'Pull elbow down to your hip, shoulder blade goes down.',
      ),
      tr('Pomalu vrať do natažení.', 'Slowly return to extension.'),
    ],
    mistakes: ['Rotace trupu místo práce zad.', 'Tah bicepsem.'],
  ),
  'straight_arm_pulldown': (
    steps: [
      tr(
        'Postav se ke kladce, ruce na tyči nebo laně, lehký předklon.',
        'Stand facing the pulley, hands on bar or rope, slight lean forward.',
      ),
      tr(
        'S téměř rovnými pažemi stahuj ke stehnům.',
        'With nearly straight arms, pull down to your thighs.',
      ),
      tr('Pomalu vracej do výšky hlavy.', 'Slowly return to head height.'),
    ],
    mistakes: ['Ohýbání loktů.', 'Pohyb trupem.'],
  ),
  'single_arm_cable_row': (
    steps: [
      tr(
        'Spodní kladka, madlo v jedné ruce, druhá ruka opřená.',
        'Low pulley, handle in one hand, other hand braced.',
      ),
      tr('Táhni loket podél těla dozadu.', 'Pull elbow back along your body.'),
      tr(
        'Pomalu vrať a nech lopatku jít dopředu.',
        'Slowly return and let shoulder blade protract.',
      ),
    ],
    mistakes: ['Rotace trupu.', 'Trhaný pohyb.'],
  ),
  'machine_high_row': (
    steps: [
      tr(
        'Hrudník na opěrce, úchop madel nad hlavou.',
        'Chest on the pad, grip handles overhead.',
      ),
      tr(
        'Táhni madla dolů a dozadu, lokty podél těla.',
        'Pull handles down and back, elbows along your body.',
      ),
      tr('Vracej pomalu do natažení.', 'Return slowly to a stretch.'),
    ],
    mistakes: ['Zvedání ramen k uším.', 'Odlepování hrudníku od opěrky.'],
  ),
  'chin_up': (
    steps: [
      tr(
        'Vis podhmatem na šířku ramen, lopatky stáhni dolů.',
        'Hang underhand at shoulder width, pull shoulder blades down.',
      ),
      tr(
        'Přitáhni se bradou nad hrazdu, lokty k tělu.',
        'Pull until chin is over the bar, elbows close to body.',
      ),
      tr('Spouštěj se pomalu do plného visu.', 'Lower slowly to a full hang.'),
    ],
    mistakes: ['Kopání nohama.', 'Polovičatý rozsah.'],
  ),
  'inverted_row': (
    steps: [
      tr(
        'Osa v multipressu nebo hrazda ve výšce pasu, lehni pod ni.',
        'Bar in a rack or bar at waist height, lie under it.',
      ),
      tr(
        'Tělo rovné jako prkno, přitáhni hrudník k ose.',
        'Body straight like a plank, pull chest to the bar.',
      ),
      tr('Pomalu se spusť do natažení paží.', 'Slowly lower to straight arms.'),
    ],
    mistakes: ['Propadlé boky.', 'Tah jen rukama bez lopatek.'],
  ),
  'rack_pull': (
    steps: [
      tr(
        'Osa na blocích kolem kolen, úchop na šířku ramen.',
        'Bar on blocks around knee height, grip at shoulder width.',
      ),
      tr(
        'Napni záda a vytáhni osu do stoje.',
        'Brace your back and pull the bar to standing.',
      ),
      tr(
        'Spouštěj zpět na bloky pod kontrolou.',
        'Lower back to the blocks with control.',
      ),
    ],
    mistakes: ['Kulatá záda.', 'Záklon nahoře.'],
  ),
  'barbell_shrug': (
    steps: [
      tr(
        'Stoj s osou u stehen, paže rovné.',
        'Stand with the bar at your thighs, arms straight.',
      ),
      tr(
        'Zvedni ramena přímo nahoru k uším.',
        'Shrug shoulders straight up to ears.',
      ),
      tr(
        'Nahoře krátce drž a pomalu spusť.',
        'Hold briefly at top and lower slowly.',
      ),
    ],
    mistakes: ['Krouživý pohyb rameny.', 'Ohýbání loktů.'],
  ),
  'hip_adduction': (
    steps: [
      tr(
        'Sedni do stroje, polštáře z vnitřní strany kolen.',
        'Sit in the machine, pads on the inside of your knees.',
      ),
      tr(
        'Stahuj nohy k sobě silou vnitřních stehen.',
        'Bring legs together using your inner thighs.',
      ),
      tr(
        'Pomalu povol do roztažení, které zvládneš bez bolesti.',
        'Slowly release to a stretch you can handle without pain.',
      ),
    ],
    mistakes: ['Trhání a pouštění váhy.', 'Moc široký start a bolest třísel.'],
  ),
  'hip_abduction': (
    steps: [
      tr(
        'Sedni do stroje, polštáře z vnější strany kolen.',
        'Sit in the machine, pads on the outside of your knees.',
      ),
      tr(
        'Roztahuj kolena od sebe, záda opřená.',
        'Push knees apart, back against the pad.',
      ),
      tr(
        'Pomalu vrať k sobě bez dopadu závaží.',
        'Slowly return without letting the weight slam.',
      ),
    ],
    mistakes: ['Švihání trupem.', 'Krátký rozsah.'],
  ),
  'cable_hip_adduction': (
    steps: [
      tr(
        'Manžeta na kotníku blíž ke kladce, drž se rámu.',
        'Ankle cuff on the leg closer to the pulley, hold the frame.',
      ),
      tr(
        'Táhni nohu přes střed těla před druhou nohu.',
        'Pull your leg across the midline in front of the other leg.',
      ),
      tr('Pomalu vrať zpět do strany.', 'Slowly return out to the side.'),
    ],
    mistakes: ['Rotace pánve.', 'Moc velká váha a švih.'],
  ),
  'cable_hip_abduction': (
    steps: [
      tr(
        'Manžeta na kotníku vzdálenější nohy, drž se rámu.',
        'Ankle cuff on the far leg, hold the frame.',
      ),
      tr(
        'Unož nohu do strany, špička míří dopředu.',
        'Move leg out to the side, toe pointing forward.',
      ),
      tr('Pomalu vrať k druhé noze.', 'Slowly return to the other leg.'),
    ],
    mistakes: ['Naklánění trupu.', 'Vytáčení špičky nahoru.'],
  ),
  'banded_lateral_walk': (
    steps: [
      tr(
        'Guma nad koleny nebo u kotníků, mírný podřep.',
        'Band above knees or at ankles, slight squat.',
      ),
      tr(
        'Krokuj do strany, kolena tlač ven.',
        'Step sideways, push knees out.',
      ),
      tr(
        'Druhou nohu přisouvej jen napůl, guma zůstane napnutá.',
        'Bring the other foot only halfway in, keep band tension.',
      ),
    ],
    mistakes: ['Kolena padají dovnitř.', 'Vzpřímený postoj bez podřepu.'],
  ),
  'sumo_squat': (
    steps: [
      tr(
        'Široký postoj, špičky ven, činku drž mezi nohama.',
        'Wide stance, toes out, hold the weight between your legs.',
      ),
      tr(
        'Jdi do dřepu, kolena míří nad špičky.',
        'Squat down, knees tracking over toes.',
      ),
      tr(
        'Vytlač se nahoru, nahoře zatni hýždě.',
        'Drive up, squeeze glutes at the top.',
      ),
    ],
    mistakes: ['Kolena padají dovnitř.', 'Předklon trupu.'],
  ),
  'sumo_deadlift': (
    steps: [
      tr(
        'Široký postoj, špičky ven, úchop mezi koleny.',
        'Wide stance, toes out, grip between knees.',
      ),
      tr(
        'Tlač kolena ven, napni záda a stoupni s osou.',
        'Push knees out, brace back and stand up with the bar.',
      ),
      tr(
        'Spouštěj osu po stehnech zpět na zem.',
        'Lower the bar down your thighs back to the floor.',
      ),
    ],
    mistakes: ['Boky vystřelí nahoru dřív než osa.', 'Kulatá záda.'],
  ),
  'trap_bar_deadlift': (
    steps: [
      tr(
        'Postav se doprostřed trap bar osy, úchop madel po stranách.',
        'Stand in the middle of the trap bar, grip the side handles.',
      ),
      tr(
        'Napni záda a tlač nohama do země až do stoje.',
        'Brace back and push through the floor to standing.',
      ),
      tr('Spusť pod kontrolou zpět.', 'Lower back down with control.'),
    ],
    mistakes: ['Kulatá záda.', 'Záklon nahoře.'],
  ),
  'good_morning': (
    steps: [
      tr(
        'Osa na trapézech, kolena lehce pokrčená.',
        'Bar on your traps, knees slightly bent.',
      ),
      tr(
        'Předkloň se v kyčlích s rovnými zády do vodorovna.',
        'Hinge at hips with a flat back until horizontal.',
      ),
      tr(
        'Zvedni se zpět silou hamstringů a hýždí.',
        'Come back up using hamstrings and glutes.',
      ),
    ],
    mistakes: ['Kulatá záda.', 'Moc velká váha.'],
  ),
  'dumbbell_rdl': (
    steps: [
      tr(
        'Stoj s činkami u stehen, kolena lehce pokrčená.',
        'Stand with dumbbells at your thighs, knees slightly bent.',
      ),
      tr(
        'Posílej boky dozadu, činky jedou těsně podél nohou.',
        'Push hips back, dumbbells travel close down your legs.',
      ),
      tr(
        'Ve chvíli protažení hamstringů se vrať do stoje.',
        'When you feel a hamstring stretch, return to standing.',
      ),
    ],
    mistakes: ['Kulatá záda.', 'Dřep místo předklonu.'],
  ),
  'kettlebell_swing': (
    steps: [
      tr(
        'Kettlebell před sebou, předklon v kyčlích, rovná záda.',
        'Kettlebell in front of you, hinge at hips, flat back.',
      ),
      tr(
        'Švihni ho mezi nohy a výbušně vystřel boky dopředu.',
        'Swing it between your legs and explosively drive hips forward.',
      ),
      tr(
        'Kettlebell vyletí do výšky hrudníku, paže jen vedou.',
        'Kettlebell floats to chest height, arms just guide it.',
      ),
    ],
    mistakes: ['Dřep místo hmitu v kyčlích.', 'Zvedání rukama.'],
  ),
  'cable_pull_through': (
    steps: [
      tr(
        'Spodní kladka s lanem mezi nohama, zády ke kladce.',
        'Low pulley with rope between legs, facing away from pulley.',
      ),
      tr(
        'Předkloň se v kyčlích, lano jde dozadu.',
        'Hinge at hips, rope goes back.',
      ),
      tr(
        'Vytlač boky dopředu a zatni hýždě.',
        'Drive hips forward and squeeze glutes.',
      ),
    ],
    mistakes: ['Tah rukama.', 'Kulatá záda.'],
  ),
  'seated_leg_curl': (
    steps: [
      tr(
        'Sedni do stroje, válec nad kotníky, stehna zajištěná.',
        'Sit in the machine, pad above ankles, thighs secured.',
      ),
      tr(
        'Zakopni nohy dolů a dozadu co nejdál.',
        'Curl legs down and back as far as you can.',
      ),
      tr('Pomalu vrať do natažení.', 'Slowly return to extension.'),
    ],
    mistakes: ['Zvedání zadku ze sedáku.', 'Rychlé pouštění váhy.'],
  ),
  'standing_leg_curl': (
    steps: [
      tr(
        'Postav se do stroje, válec za kotníkem.',
        'Stand in the machine, pad behind your ankle.',
      ),
      tr(
        'Zakopni patu k hýždi, stehno zůstává na místě.',
        'Curl heel to glute, thigh stays in place.',
      ),
      tr('Pomalu spusť dolů.', 'Slowly lower down.'),
    ],
    mistakes: ['Pohyb pánví.', 'Švih.'],
  ),
  'nordic_curl': (
    steps: [
      tr(
        'Klekni, paty zaklesnuté nebo držené partnerem.',
        'Kneel, heels hooked or held by a partner.',
      ),
      tr(
        'Pomalu padej dopředu s rovným tělem, brzdi hamstringy.',
        'Slowly fall forward with a straight body, brake with hamstrings.',
      ),
      tr(
        'Dole se zachyť rukama a odraz zpět nahoru.',
        'Catch yourself with hands at the bottom and push back up.',
      ),
    ],
    mistakes: ['Ohnutí v kyčlích.', 'Pád bez brzdění.'],
  ),
  'pendulum_squat': (
    steps: [
      tr(
        'Záda na opěrce, ramena pod polštáři, chodidla na šířku ramen.',
        'Back against the pad, shoulders under pads, feet shoulder-width apart.',
      ),
      tr('Jdi hluboko do dřepu pod kontrolou.', 'Squat deep under control.'),
      tr(
        'Vytlač se celým chodidlem nahoru.',
        'Drive up through your whole foot.',
      ),
    ],
    mistakes: ['Zvedání pat.', 'Zamykání kolen nahoře.'],
  ),
  'belt_squat': (
    steps: [
      tr(
        'Opasek kolem pasu, postav se na plošinu.',
        'Belt around your waist, stand on the platform.',
      ),
      tr(
        'Dřepni hluboko s rovným trupem.',
        'Squat deep with an upright torso.',
      ),
      tr(
        'Vytlač se nahoru, kolena míří nad špičky.',
        'Drive up, knees tracking over toes.',
      ),
    ],
    mistakes: ['Kolena padají dovnitř.', 'Polovičatý dřep.'],
  ),
  'air_squat': (
    steps: [
      tr(
        'Chodidla na šířku ramen, ruce před sebou.',
        'Feet shoulder-width apart, arms in front of you.',
      ),
      tr(
        'Jdi s boky dozadu a dolů pod úroveň kolen.',
        'Send hips back and down below knee level.',
      ),
      tr(
        'Vytlač se nahoru, nahoře zatni hýždě.',
        'Drive up, squeeze glutes at the top.',
      ),
    ],
    mistakes: ['Zvedání pat.', 'Kulatá záda dole.'],
  ),
  'barbell_lunge': (
    steps: [
      tr(
        'Osa na trapézech, stoj rozkročný.',
        'Bar on your traps, stand in a split stance.',
      ),
      tr(
        'Udělej krok dopředu a klesni, zadní koleno nad zem.',
        'Step forward and lower, back knee above the floor.',
      ),
      tr(
        'Odraz se přední nohou zpět.',
        'Push off the front foot back to start.',
      ),
    ],
    mistakes: ['Koleno přední nohy padá dovnitř.', 'Moc krátký krok.'],
  ),
  'reverse_lunge': (
    steps: [
      tr('Stoj s činkami v rukou.', 'Stand with dumbbells in your hands.'),
      tr(
        'Ukroč dozadu a klesni, zadní koleno nad zem.',
        'Step back and lower, back knee above the floor.',
      ),
      tr(
        'Vrať se přední nohou do stoje.',
        'Return to standing with the front leg.',
      ),
    ],
    mistakes: ['Předklon trupu.', 'Ztráta rovnováhy.'],
  ),
  'step_up': (
    steps: [
      tr(
        'Činky v rukou, bedna ve výšce kolene.',
        'Dumbbells in hands, box at knee height.',
      ),
      tr(
        'Celé chodidlo na bednu, vytlač se nahoru přední nohou.',
        'Whole foot on the box, drive up with the front leg.',
      ),
      tr('Pomalu sestup stejnou nohou.', 'Step down slowly with the same leg.'),
    ],
    mistakes: ['Odraz zadní nohou.', 'Koleno padá dovnitř.'],
  ),
  'glute_bridge': (
    steps: [
      tr(
        'Lehni na záda, osa v pánvi, chodidla blízko hýždí.',
        'Lie on your back, bar at hips, feet close to glutes.',
      ),
      tr(
        'Zvedni boky nahoru, nahoře zatni hýždě.',
        'Lift hips up, squeeze glutes at the top.',
      ),
      tr('Pomalu spusť skoro k zemi.', 'Lower slowly almost to the floor.'),
    ],
    mistakes: ['Prohýbání beder nahoře.', 'Tlak přes špičky.'],
  ),
  'hip_thrust_machine': (
    steps: [
      tr(
        'Opři horní záda, pás přes pánev, chodidla na šířku ramen.',
        'Brace upper back, belt across hips, feet shoulder-width apart.',
      ),
      tr(
        'Vytlač boky nahoru do roviny s trupem.',
        'Drive hips up in line with your torso.',
      ),
      tr(
        'Nahoře krátce drž a pomalu spusť.',
        'Hold briefly at top and lower slowly.',
      ),
    ],
    mistakes: ['Záklon hlavy a prohnutá bedra.', 'Moc daleko chodidla.'],
  ),
  'cable_kickback': (
    steps: [
      tr(
        'Manžeta na kotníku, předkloň se a drž se rámu.',
        'Ankle cuff on, hinge forward and hold the frame.',
      ),
      tr(
        'Zanož nohu dozadu a nahoru silou hýždě.',
        'Kick leg back and up using your glute.',
      ),
      tr('Pomalu vrať pod sebe.', 'Slowly return under your body.'),
    ],
    mistakes: ['Prohýbání beder.', 'Švih.'],
  ),
  'glute_kickback_machine': (
    steps: [
      tr(
        'Opři se o stroj, chodidlo na plošinu.',
        'Lean against the machine, foot on the platform.',
      ),
      tr(
        'Tlač nohu dozadu do natažení kyčle.',
        'Press leg back into hip extension.',
      ),
      tr('Pomalu vrať.', 'Slowly return.'),
    ],
    mistakes: ['Prohnutá bedra.', 'Krátký rozsah.'],
  ),
  'smith_calf_raise': (
    steps: [
      tr(
        'Osa na trapézech, špičky na vyvýšené podložce.',
        'Bar on your traps, balls of feet on a raised step.',
      ),
      tr(
        'Vyjdi na špičky co nejvýš.',
        'Rise onto your toes as high as you can.',
      ),
      tr(
        'Pomalu klesni do protažení lýtek.',
        'Slowly lower into a calf stretch.',
      ),
    ],
    mistakes: ['Pérování bez pauzy.', 'Ohýbání kolen.'],
  ),
  'single_leg_calf_raise': (
    steps: [
      tr(
        'Stoj na jedné noze na schodu, činka v ruce, druhou se drž.',
        'Stand on one foot on a step, dumbbell in hand, hold on with the other.',
      ),
      tr(
        'Vyjdi na špičku co nejvýš.',
        'Rise onto your toe as high as you can.',
      ),
      tr(
        'Klesni pod úroveň schodu do protažení.',
        'Lower below step level into a stretch.',
      ),
    ],
    mistakes: ['Malý rozsah.', 'Houpání tělem.'],
  ),
  'arnold_press': (
    steps: [
      tr(
        'Sedni, činky před obličejem dlaněmi k sobě.',
        'Sit, dumbbells in front of face with palms facing each other.',
      ),
      tr(
        'Tlač nahoru a při tom otáčej dlaně dopředu.',
        'Press up while rotating palms forward.',
      ),
      tr(
        'Spouštěj zpět s rotací do výchozí polohy.',
        'Lower back with rotation to the starting position.',
      ),
    ],
    mistakes: ['Prohýbání beder.', 'Rychlé a trhané rotace.'],
  ),
  'smith_shoulder_press': (
    steps: [
      tr(
        'Lavici se zády nastav pod osu, osa jde před obličejem.',
        'Set a back-support bench under the bar, bar travels in front of face.',
      ),
      tr(
        'Tlač osu nad hlavu, nezamykej lokty naplno.',
        'Press the bar overhead, don\'t fully lock elbows.',
      ),
      tr(
        'Spouštěj k bradě pod kontrolou.',
        'Lower to chin level with control.',
      ),
    ],
    mistakes: ['Osa jde za hlavu.', 'Prohnutá bedra.'],
  ),
  'push_press': (
    steps: [
      tr(
        'Osa na předních deltech, stoj na šířku boků.',
        'Bar on front delts, stand hip-width apart.',
      ),
      tr(
        'Krátký podřep a výbušně vytlač osu nad hlavu.',
        'Quick dip and explosively press the bar overhead.',
      ),
      tr('Pomalu spusť zpět na ramena.', 'Slowly lower back to shoulders.'),
    ],
    mistakes: ['Hluboký dřep místo krátkého podřepu.', 'Záklon trupu.'],
  ),
  'landmine_press': (
    steps: [
      tr(
        'Konec osy v rohu nebo landmine, druhý konec u ramene.',
        'One end of bar in a corner or landmine, other end at shoulder.',
      ),
      tr(
        'Tlač osu šikmo nahoru a dopředu.',
        'Press the bar up and forward at an angle.',
      ),
      tr('Pomalu vrať k rameni.', 'Slowly return to shoulder.'),
    ],
    mistakes: ['Prohnutá bedra.', 'Rotace trupu.'],
  ),
  'front_raise': (
    steps: [
      tr('Stoj, činky před stehny.', 'Stand, dumbbells in front of thighs.'),
      tr(
        'Zvedej paže před sebe do výšky ramen.',
        'Raise arms in front of you to shoulder height.',
      ),
      tr('Pomalu spusť dolů.', 'Slowly lower down.'),
    ],
    mistakes: ['Švih trupem.', 'Zvedání nad hlavu.'],
  ),
  'plate_front_raise': (
    steps: [
      tr(
        'Kotouč drž oběma rukama před stehny.',
        'Hold a plate with both hands in front of thighs.',
      ),
      tr(
        'Zvedni ho rovnými pažemi do výšky očí.',
        'Lift it with straight arms to eye level.',
      ),
      tr('Pomalu spusť.', 'Slowly lower down.'),
    ],
    mistakes: ['Záklon trupu.', 'Švih.'],
  ),
  'upright_row': (
    steps: [
      tr(
        'Osa nadhmatem, úchop o něco širší než ramena.',
        'Bar overhand, grip slightly wider than shoulders.',
      ),
      tr(
        'Táhni osu podél těla k hrudníku, lokty vedou.',
        'Pull the bar up along your body to chest, elbows lead.',
      ),
      tr('Pomalu spusť dolů.', 'Slowly lower down.'),
    ],
    mistakes: ['Úzký úchop a bolest ramen.', 'Tah nad úroveň ramen.'],
  ),
  'machine_lateral_raise': (
    steps: [
      tr(
        'Sedni, polštáře z vnější strany loktů.',
        'Sit, pads on the outside of elbows.',
      ),
      tr('Upažuj do výšky ramen.', 'Raise arms out to shoulder height.'),
      tr('Pomalu spusť dolů.', 'Slowly lower down.'),
    ],
    mistakes: ['Krčení ramen.', 'Rychlé pouštění.'],
  ),
  'cable_rear_delt_fly': (
    steps: [
      tr(
        'Kladky nahoře, lanka zkřížená, stoj mezi nimi.',
        'Pulleys high, cables crossed, stand between them.',
      ),
      tr(
        'Táhni ruce do stran a dozadu v úrovni ramen.',
        'Pull hands out to the sides and back at shoulder level.',
      ),
      tr('Pomalu vrať před sebe.', 'Slowly return in front of you.'),
    ],
    mistakes: ['Tah lopatkami místo zadních deltů.', 'Ohýbání loktů.'],
  ),
  'band_pull_apart': (
    steps: [
      tr(
        'Gumu drž před sebou v úrovni ramen.',
        'Hold a band in front of you at shoulder height.',
      ),
      tr(
        'Roztáhni ji do stran až k hrudníku.',
        'Pull it apart to the sides until it reaches your chest.',
      ),
      tr('Pomalu vrať.', 'Slowly return.'),
    ],
    mistakes: ['Krčení ramen.', 'Pokrčené lokty.'],
  ),
  'ez_bar_curl': (
    steps: [
      tr(
        'EZ osa podhmatem, lokty u těla.',
        'EZ bar underhand, elbows at your sides.',
      ),
      tr(
        'Zvedni osu k ramenům bez švihu.',
        'Curl the bar to shoulders without swinging.',
      ),
      tr('Pomalu spusť do natažení.', 'Lower slowly into a stretch.'),
    ],
    mistakes: ['Švih trupem.', 'Lokty jdou dopředu.'],
  ),
  'concentration_curl': (
    steps: [
      tr(
        'Sedni, loket opři o vnitřní stranu stehna.',
        'Sit, brace elbow against inner thigh.',
      ),
      tr('Zvedni činku k rameni.', 'Curl the dumbbell to your shoulder.'),
      tr('Pomalu spusť do plného natažení.', 'Lower slowly to a full stretch.'),
    ],
    mistakes: ['Pohyb trupem.', 'Krátký rozsah.'],
  ),
  'machine_preacher_curl': (
    steps: [
      tr(
        'Nastav sedák, paže celé na opěrce.',
        'Set the seat, arms fully on the pad.',
      ),
      tr('Zvedni madla k ramenům.', 'Curl handles to shoulders.'),
      tr(
        'Pomalu spusť skoro do natažení.',
        'Lower slowly almost to full extension.',
      ),
    ],
    mistakes: ['Zvedání zadku ze sedáku.', 'Pouštění váhy dolů.'],
  ),
  'bayesian_curl': (
    steps: [
      tr(
        'Stoj zády ke spodní kladce, madlo v ruce, paže za tělem.',
        'Stand facing away from low pulley, handle in hand, arm behind body.',
      ),
      tr(
        'Zvedni madlo k rameni, loket zůstává vzadu.',
        'Curl handle to shoulder, elbow stays back.',
      ),
      tr('Pomalu vrať do protažení.', 'Slowly return to a stretch.'),
    ],
    mistakes: ['Loket jde dopředu.', 'Rotace trupu.'],
  ),
  'cable_hammer_curl': (
    steps: [
      tr(
        'Lano na spodní kladce, dlaně proti sobě.',
        'Rope on low pulley, palms facing each other.',
      ),
      tr(
        'Zvedni lano k ramenům, lokty u těla.',
        'Curl rope to shoulders, elbows at your sides.',
      ),
      tr('Pomalu spusť.', 'Slowly lower down.'),
    ],
    mistakes: ['Švih.', 'Lokty odjíždějí.'],
  ),
  'close_grip_bench': (
    steps: [
      tr(
        'Osa na šířku ramen, lopatky stažené.',
        'Bar at shoulder width, shoulder blades squeezed.',
      ),
      tr(
        'Spouštěj na spodní hrudník, lokty u těla.',
        'Lower to lower chest, elbows at your sides.',
      ),
      tr('Vytlač nahoru silou tricepsu.', 'Press up using triceps.'),
    ],
    mistakes: ['Moc úzký úchop a bolest zápěstí.', 'Lokty do stran.'],
  ),
  'dumbbell_overhead_extension': (
    steps: [
      tr(
        'Sedni, činku drž oběma rukama nad hlavou.',
        'Sit, hold a dumbbell with both hands overhead.',
      ),
      tr(
        'Spouštěj ji za hlavu, lokty míří nahoru.',
        'Lower it behind your head, elbows pointing up.',
      ),
      tr('Vytlač zpět nahoru.', 'Press back up.'),
    ],
    mistakes: ['Lokty od sebe.', 'Prohnutá bedra.'],
  ),
  'triceps_kickback': (
    steps: [
      tr(
        'Předklon s oporou, nadloktí podél těla.',
        'Hinge forward with support, upper arm along your body.',
      ),
      tr(
        'Natáhni loket dozadu do propnutí.',
        'Extend elbow back to full lockout.',
      ),
      tr(
        'Pomalu vrať, nadloktí se nehýbe.',
        'Slowly return, upper arm stays still.',
      ),
    ],
    mistakes: ['Pohyb nadloktím.', 'Švih.'],
  ),
  'bench_dips': (
    steps: [
      tr(
        'Ruce na hraně lavice za sebou, nohy před sebou.',
        'Hands on the edge of a bench behind you, legs in front.',
      ),
      tr(
        'Spouštěj se, dokud nejsou lokty v pravém úhlu.',
        'Lower until elbows are at a right angle.',
      ),
      tr('Vytlač se nahoru.', 'Press back up.'),
    ],
    mistakes: ['Moc hluboko a bolest ramen.', 'Lokty do stran.'],
  ),
  'triceps_dip_machine': (
    steps: [
      tr('Sedni, madla vedle boků.', 'Sit, handles beside your hips.'),
      tr(
        'Tlač madla dolů do propnutí loktů.',
        'Press handles down to full elbow extension.',
      ),
      tr('Pomalu vrať nahoru.', 'Slowly return up.'),
    ],
    mistakes: ['Předklon a práce hrudníku.', 'Krčení ramen.'],
  ),
  'wrist_curl': (
    steps: [
      tr(
        'Sedni, předloktí na stehnech, osa podhmatem.',
        'Sit, forearms on thighs, bar underhand.',
      ),
      tr('Ohni zápěstí nahoru.', 'Curl wrists up.'),
      tr(
        'Pomalu spusť a nech osu sjet do prstů.',
        'Lower slowly and let the bar roll into your fingers.',
      ),
    ],
    mistakes: ['Pohyb předloktím.', 'Moc velká váha.'],
  ),
  'reverse_wrist_curl': (
    steps: [
      tr(
        'Předloktí na stehnu, činka nadhmatem.',
        'Forearm on thigh, dumbbell overhand.',
      ),
      tr('Zvedni hřbet ruky nahoru.', 'Raise the back of your hand up.'),
      tr('Pomalu spusť.', 'Slowly lower down.'),
    ],
    mistakes: ['Švih.', 'Moc velký rozsah do bolesti.'],
  ),
  'farmers_walk': (
    steps: [
      tr(
        'Zvedni těžké činky jako mrtvý tah.',
        'Pick up heavy dumbbells like a deadlift.',
      ),
      tr(
        'Jdi krátkými kroky, ramena dole, trup vzpřímený.',
        'Walk with short steps, shoulders down, torso upright.',
      ),
      tr(
        'Po dané vzdálenosti činky polož.',
        'Set the dumbbells down after the set distance.',
      ),
    ],
    mistakes: ['Kulatá záda při zvedání.', 'Naklánění do stran.'],
  ),
  'crunch': (
    steps: [
      tr(
        'Lehni na záda, kolena pokrčená, ruce u spánků.',
        'Lie on your back, knees bent, hands at temples.',
      ),
      tr(
        'Sroluj trup a zvedni lopatky od země.',
        'Curl your torso up and lift shoulder blades off the floor.',
      ),
      tr('Pomalu se vrať.', 'Slowly return.'),
    ],
    mistakes: ['Tahání hlavy rukama.', 'Švih.'],
  ),
  'decline_crunch': (
    steps: [
      tr(
        'Zaklesni nohy na šikmé lavici.',
        'Hook your feet on a decline bench.',
      ),
      tr(
        'Sroluj trup nahoru k kolenům.',
        'Curl your torso up toward your knees.',
      ),
      tr(
        'Pomalu se spusť, záda se nedotknou úplně.',
        'Lower slowly, back doesn\'t fully touch down.',
      ),
    ],
    mistakes: ['Švih.', 'Prohnutá bedra.'],
  ),
  'bicycle_crunch': (
    steps: [
      tr(
        'Lehni na záda, ruce u hlavy, nohy nad zemí.',
        'Lie on your back, hands by your head, legs off the floor.',
      ),
      tr('Přitahuj koleno k opačnému lokti.', 'Bring knee to opposite elbow.'),
      tr(
        'Střídej strany pomalu a pod kontrolou.',
        'Alternate sides slowly and with control.',
      ),
    ],
    mistakes: ['Tahání hlavy.', 'Rychlé šlapání bez rotace.'],
  ),
  'reverse_crunch': (
    steps: [
      tr(
        'Lehni na záda, kolena pokrčená nad boky.',
        'Lie on your back, knees bent over hips.',
      ),
      tr(
        'Sroluj pánev nahoru k hrudníku.',
        'Curl pelvis up toward your chest.',
      ),
      tr('Pomalu ji spusť zpět.', 'Slowly lower it back.'),
    ],
    mistakes: ['Švih nohama.', 'Bedra se odlepují s trhnutím.'],
  ),
  'hanging_knee_raise': (
    steps: [
      tr(
        'Vis na hrazdě, ramena aktivní.',
        'Hang from the bar, shoulders active.',
      ),
      tr(
        'Přitáhni kolena k hrudníku a podsaď pánev.',
        'Pull knees to chest and tilt pelvis up.',
      ),
      tr('Pomalu spusť bez houpání.', 'Lower slowly without swinging.'),
    ],
    mistakes: ['Houpání.', 'Jen zvedání nohou bez podsazení pánve.'],
  ),
  'captains_chair': (
    steps: [
      tr(
        'Opři předloktí, záda na opěrce.',
        'Rest forearms, back against the pad.',
      ),
      tr(
        'Zvedni kolena nebo rovné nohy nahoru.',
        'Raise knees or straight legs up.',
      ),
      tr('Pomalu spusť.', 'Slowly lower down.'),
    ],
    mistakes: ['Švih.', 'Prohnutá bedra.'],
  ),
  'ab_wheel': (
    steps: [
      tr('Klekni, kolečko pod rameny.', 'Kneel, wheel under your shoulders.'),
      tr(
        'Pomalu ho posílej dopředu s pevným břichem.',
        'Slowly roll it forward with a braced core.',
      ),
      tr('Vrať se zpět silou břicha.', 'Roll back using your abs.'),
    ],
    mistakes: ['Propadlá bedra.', 'Moc daleko na začátku.'],
  ),
  'russian_twist': (
    steps: [
      tr(
        'Sedni, záklon asi 45°, kotouč v rukou.',
        'Sit, lean back about 45°, plate in hands.',
      ),
      tr('Otáčej trup ze strany na stranu.', 'Rotate torso side to side.'),
      tr(
        'Pohyb jde z trupu, ne jen z rukou.',
        'Movement comes from torso, not just arms.',
      ),
    ],
    mistakes: ['Kulatá záda.', 'Pohyb jen rukama.'],
  ),
  'cable_woodchopper': (
    steps: [
      tr(
        'Kladka nahoře, stoj bokem, madlo oběma rukama.',
        'Pulley high, stand sideways, handle with both hands.',
      ),
      tr(
        'Táhni šikmo dolů přes tělo rotací trupu.',
        'Pull diagonally down across your body by rotating torso.',
      ),
      tr('Pomalu vrať nahoru.', 'Slowly return up.'),
    ],
    mistakes: ['Tah rukama.', 'Kroucení v bedrech bez pohybu boků.'],
  ),
  'torso_rotation_machine': (
    steps: [
      tr(
        'Sedni do stroje, nohy zajištěné.',
        'Sit in the machine, legs secured.',
      ),
      tr(
        'Otoč trup do strany pod kontrolou.',
        'Rotate torso to the side with control.',
      ),
      tr('Pomalu vrať a pak druhá strana.', 'Slowly return, then other side.'),
    ],
    mistakes: ['Moc velká váha.', 'Trhaný pohyb.'],
  ),
  'side_bend': (
    steps: [
      tr('Stoj, činka v jedné ruce.', 'Stand, dumbbell in one hand.'),
      tr(
        'Ukloň se k čince a pak zpět nad střed.',
        'Lean toward the dumbbell and back past center.',
      ),
      tr('Po sérii vyměň strany.', 'Switch sides after the set.'),
    ],
    mistakes: ['Předklon nebo záklon.', 'Činky v obou rukách.'],
  ),
  'cable_crossover_high': (
    steps: [
      tr(
        'Nastav výšku/postoj tak, aby ramena byla stabilní a lokty lehce pokrčené.',
        'Set height/stance so shoulders are stable and elbows slightly bent.',
      ),
      tr(
        'Veď paže v kontrolovaném oblouku, cítíš práci hrudníku.',
        'Move arms in a controlled arc, feel the chest working.',
      ),
      tr(
        'Vrať se pomalu do protažení bez ztráty kontroly ramen.',
        'Return slowly to a stretch without losing shoulder control.',
      ),
    ],
    mistakes: [
      tr('Příliš velká váha a trhání.', 'Too much weight and jerking.'),
      tr(
        'Ohýbání loktů mění cvik na tlak.',
        'Bending elbows turns the move into a press.',
      ),
    ],
  ),
  'incline_cable_press': (
    steps: [
      tr(
        'Nastav sed/lavici tak, aby úchop/držadla byly ve výšce středu hrudníku.',
        'Set the seat/bench so the grip/handles are at mid-chest height.',
      ),
      tr(
        'Spouštěj kontrolovaně do plného, bezbolestného rozsahu.',
        'Lower with control through a full, pain-free range.',
      ),
      tr(
        'Tlač zpět nahoru, lopatky drž stabilní a lokty nezamykej na doraz.',
        'Press back up, keep shoulder blades stable, and don\'t lock elbows hard.',
      ),
    ],
    mistakes: ['Příliš velká váha a zkrácený rozsah.', 'Ramena jedou k uším.'],
  ),
  'svend_press': (
    steps: [
      tr(
        'Nastav sed/lavici tak, aby úchop/držadla byly ve výšce středu hrudníku.',
        'Set the seat/bench so the grip/handles are at mid-chest height.',
      ),
      tr(
        'Spouštěj kontrolovaně do plného, bezbolestného rozsahu.',
        'Lower with control through a full, pain-free range.',
      ),
      tr(
        'Tlač zpět nahoru, lopatky drž stabilní a lokty nezamykej na doraz.',
        'Press back up, keep shoulder blades stable, and don\'t lock elbows hard.',
      ),
    ],
    mistakes: ['Příliš velká váha a zkrácený rozsah.', 'Ramena jedou k uším.'],
  ),
  'floor_press': (
    steps: [
      tr(
        'Nastav sed/lavici tak, aby úchop/držadla byly ve výšce středu hrudníku.',
        'Set the seat/bench so the grip/handles are at mid-chest height.',
      ),
      tr(
        'Spouštěj kontrolovaně do plného, bezbolestného rozsahu.',
        'Lower with control through a full, pain-free range.',
      ),
      tr(
        'Tlač zpět nahoru, lopatky drž stabilní a lokty nezamykej na doraz.',
        'Press back up, keep shoulder blades stable, and don\'t lock elbows hard.',
      ),
    ],
    mistakes: ['Příliš velká váha a zkrácený rozsah.', 'Ramena jedou k uším.'],
  ),
  'dumbbell_floor_press': (
    steps: [
      tr(
        'Nastav sed/lavici tak, aby úchop/držadla byly ve výšce středu hrudníku.',
        'Set the seat/bench so the grip/handles are at mid-chest height.',
      ),
      tr(
        'Spouštěj kontrolovaně do plného, bezbolestného rozsahu.',
        'Lower with control through a full, pain-free range.',
      ),
      tr(
        'Tlač zpět nahoru, lopatky drž stabilní a lokty nezamykej na doraz.',
        'Press back up, keep shoulder blades stable, and don\'t lock elbows hard.',
      ),
    ],
    mistakes: ['Příliš velká váha a zkrácený rozsah.', 'Ramena jedou k uším.'],
  ),
  'incline_push_up': (
    steps: [
      tr(
        'Opři ruce pod rameny, tělo v jedné přímce od hlavy k patám.',
        'Place hands under shoulders, body in a straight line from head to heels.',
      ),
      tr(
        'Spouštěj hrudník kontrolovaně dolů, lokty pod úhlem cca 45° od těla.',
        'Lower chest with control, elbows at about 45° from body.',
      ),
      tr(
        'Vytlač se zpět nahoru a drž pevný střed těla.',
        'Press back up and keep a braced core.',
      ),
    ],
    mistakes: ['Propadlé boky nebo zvednutý zadek.', 'Lokty příliš do stran.'],
  ),
  'decline_push_up': (
    steps: [
      tr(
        'Opři ruce pod rameny, tělo v jedné přímce od hlavy k patám.',
        'Place hands under shoulders, body in a straight line from head to heels.',
      ),
      tr(
        'Spouštěj hrudník kontrolovaně dolů, lokty pod úhlem cca 45° od těla.',
        'Lower chest with control, elbows at about 45° from body.',
      ),
      tr(
        'Vytlač se zpět nahoru a drž pevný střed těla.',
        'Press back up and keep a braced core.',
      ),
    ],
    mistakes: ['Propadlé boky nebo zvednutý zadek.', 'Lokty příliš do stran.'],
  ),
  'wide_grip_lat_pulldown': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'neutral_grip_lat_pulldown': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'half_kneeling_lat_pulldown': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'chest_supported_dumbbell_row': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'machine_lat_pulldown': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'dumbbell_deadlift': (
    steps: [
      tr(
        'Zaujmi stabilní postoj, páteř neutrální a střed těla zpevněný.',
        'Set a stable stance, neutral spine, and braced core.',
      ),
      tr(
        'Prováděj kontrolovaný pohyb v plném rozsahu.',
        'Perform a controlled movement through full range.',
      ),
      tr(
        'Vrať se pomalu do výchozí polohy bez trhání.',
        'Return slowly to the starting position without jerking.',
      ),
    ],
    mistakes: ['Trhání a ztráta kontroly trupu.', 'Příliš velká váha.'],
  ),
  'hammer_strength_row': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'hammer_strength_chest_press': (
    steps: [
      tr(
        'Nastav sed/lavici tak, aby úchop/držadla byly ve výšce středu hrudníku.',
        'Set the seat/bench so the grip/handles are at mid-chest height.',
      ),
      tr(
        'Spouštěj kontrolovaně do plného, bezbolestného rozsahu.',
        'Lower with control through a full, pain-free range.',
      ),
      tr(
        'Tlač zpět nahoru, lopatky drž stabilní a lokty nezamykej na doraz.',
        'Press back up, keep shoulder blades stable, and don\'t lock elbows hard.',
      ),
    ],
    mistakes: ['Příliš velká váha a zkrácený rozsah.', 'Ramena jedou k uším.'],
  ),
  'landmine_row': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'smith_machine_row': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'cable_shrug': (
    steps: [
      tr(
        'Chyť úchop, hrudník otevři a lopatky stáhni dolů.',
        'Grab the handle, open your chest, and pull shoulder blades down.',
      ),
      tr(
        'Táhni kontrolovaně k horní části hrudníku/požadované dráze.',
        'Pull with control to your upper chest/the intended path.',
      ),
      tr(
        'Vrať pomalu do protažení bez houpání trupu.',
        'Return slowly to a stretch without swinging your torso.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání tělem a tah za krk.',
        'Swinging the body and pulling behind the neck.',
      ),
      tr(
        'Příliš velká váha na úkor rozsahu.',
        'Too much weight at the cost of range.',
      ),
    ],
  ),
  'leg_press_narrow': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'leg_press_high': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'smith_lunge': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'single_leg_rdl': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'lying_leg_curl_machine': (
    steps: [
      tr(
        'Nastav stroj tak, aby osa odpovídala kolenu.',
        'Set the machine so the pivot aligns with your knee.',
      ),
      tr(
        'Ohýbej koleno kontrolovaně proti odporu.',
        'Bend your knee with control against resistance.',
      ),
      tr(
        'Vracej pomalu, závaží nenech dopadnout.',
        'Return slowly, don\'t let the weight drop.',
      ),
    ],
    mistakes: ['Zvedání boků/pánve ze sedáku.', 'Trhaný pohyb.'],
  ),
  'hip_extension_machine': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'adductor_machine': (
    steps: [
      tr(
        'Sedni stabilně, opěrky nastav na pohodlný rozsah.',
        'Sit stable, set the pads to a comfortable range.',
      ),
      tr(
        'Pohyb prováděj kontrolovaně v bezbolestném rozsahu.',
        'Move with control through a pain-free range.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Příliš velký rozsah za komfort.', 'Trhání a houpání trupu.'],
  ),
  'abductor_machine': (
    steps: [
      tr(
        'Sedni stabilně, opěrky nastav na pohodlný rozsah.',
        'Sit stable, set the pads to a comfortable range.',
      ),
      tr(
        'Pohyb prováděj kontrolovaně v bezbolestném rozsahu.',
        'Move with control through a pain-free range.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Příliš velký rozsah za komfort.', 'Trhání a houpání trupu.'],
  ),
  'leg_press_calf_raise': (
    steps: [
      tr(
        'Nastav chodidla stabilně, plný rozsah v kotníku.',
        'Set your feet stable, full range at the ankle.',
      ),
      tr(
        'Zvedni se na špičky a nahoře krátce podrž.',
        'Rise onto your toes and hold briefly at the top.',
      ),
      tr('Spouštěj pomalu do protažení.', 'Lower slowly into a stretch.'),
    ],
    mistakes: ['Odrážení a zkrácený rozsah.', 'Příliš rychlé tempo.'],
  ),
  'split_squat': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'cable_pull_through_glute': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'bodyweight_squat': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'wall_sit': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'glute_bridge_bodyweight': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'step_up_box': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'bodyweight_lunge': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'hip_thrust_bodyweight': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'barbell_glute_bridge': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'kettlebell_goblet_squat': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'smith_machine_squat': (
    steps: [
      tr(
        'Zaujmi stabilní postoj/sed, střed těla zpevněný.',
        'Set up a stable stance/seat with your core braced.',
      ),
      tr(
        'Prováděj pohyb kontrolovaně, kolena ve směru prstů.',
        'Move with control, keeping knees tracking over toes.',
      ),
      tr(
        'Vrať se pomalu a drž plnou kontrolu.',
        'Return slowly and keep full control.',
      ),
    ],
    mistakes: [
      tr(
        'Zkrácený rozsah a rychlé odrážení.',
        'Short range of motion and bouncing.',
      ),
      tr('Ztráta kontroly kolen nebo trupu.', 'Loss of knee or torso control.'),
    ],
  ),
  'leg_extension_single': (
    steps: [
      tr(
        'Kolena v ose stroje, opora nad kotníky.',
        'Knees aligned with the machine pivot, pad above ankles.',
      ),
      tr(
        'Propni nohy kontrolovaně a nahoře krátce stáhni.',
        'Extend legs with control and squeeze briefly at the top.',
      ),
      tr(
        'Spouštěj pomalu bez dosednutí závaží.',
        'Lower slowly without letting the weight stack rest.',
      ),
    ],
    mistakes: ['Příliš velká váha a kopání.', 'Zvedání sedáku od opěrky.'],
  ),
  'seated_calf_raise_machine': (
    steps: [
      tr(
        'Nastav chodidla stabilně, plný rozsah v kotníku.',
        'Set your feet stable, full range at the ankle.',
      ),
      tr(
        'Zvedni se na špičky a nahoře krátce podrž.',
        'Rise onto your toes and hold briefly at the top.',
      ),
      tr('Spouštěj pomalu do protažení.', 'Lower slowly into a stretch.'),
    ],
    mistakes: ['Odrážení a zkrácený rozsah.', 'Příliš rychlé tempo.'],
  ),
  'seated_dumbbell_press': (
    steps: [
      tr(
        'Zpevni trup a žebra stáhni dolů, zápěstí nad lokty.',
        'Brace your torso and pull ribs down, wrists over elbows.',
      ),
      tr(
        'Tlač kontrolovaně nahoru v bezbolestné dráze.',
        'Press up with control along a pain-free path.',
      ),
      tr(
        'Spouštěj pomalu do výchozí polohy.',
        'Lower slowly to the starting position.',
      ),
    ],
    mistakes: ['Prohnutí v bedrech.', 'Příliš velká váha a zkrácený rozsah.'],
  ),
  'standing_barbell_press': (
    steps: [
      tr(
        'Zpevni trup a žebra stáhni dolů, zápěstí nad lokty.',
        'Brace your torso and pull ribs down, wrists over elbows.',
      ),
      tr(
        'Tlač kontrolovaně nahoru v bezbolestné dráze.',
        'Press up with control along a pain-free path.',
      ),
      tr(
        'Spouštěj pomalu do výchozí polohy.',
        'Lower slowly to the starting position.',
      ),
    ],
    mistakes: ['Prohnutí v bedrech.', 'Příliš velká váha a zkrácený rozsah.'],
  ),
  'seated_barbell_press': (
    steps: [
      tr(
        'Zpevni trup a žebra stáhni dolů, zápěstí nad lokty.',
        'Brace your torso and pull ribs down, wrists over elbows.',
      ),
      tr(
        'Tlač kontrolovaně nahoru v bezbolestné dráze.',
        'Press up with control along a pain-free path.',
      ),
      tr(
        'Spouštěj pomalu do výchozí polohy.',
        'Lower slowly to the starting position.',
      ),
    ],
    mistakes: ['Prohnutí v bedrech.', 'Příliš velká váha a zkrácený rozsah.'],
  ),
  'cable_front_raise': (
    steps: [
      tr(
        'Stůj stabilně, lokty lehce pokrčené.',
        'Stand stable with elbows slightly bent.',
      ),
      tr(
        'Zvedej paže kontrolovaně do výšky ramen (nebo bez bolesti).',
        'Raise your arms with control to shoulder height (or pain-free).',
      ),
      tr(
        'Spouštěj pomalu, nehoupej trupem.',
        'Lower slowly, don\'t swing your torso.',
      ),
    ],
    mistakes: ['Houpání tělem.', 'Zvedání ramen k uším.'],
  ),
  'dumbbell_front_raise': (
    steps: [
      tr(
        'Stůj stabilně, lokty lehce pokrčené.',
        'Stand stable with elbows slightly bent.',
      ),
      tr(
        'Zvedej paže kontrolovaně do výšky ramen (nebo bez bolesti).',
        'Raise your arms with control to shoulder height (or pain-free).',
      ),
      tr(
        'Spouštěj pomalu, nehoupej trupem.',
        'Lower slowly, don\'t swing your torso.',
      ),
    ],
    mistakes: ['Houpání tělem.', 'Zvedání ramen k uším.'],
  ),
  'cable_upright_row': (
    steps: [
      tr(
        'Nastav stabilní pozici a drž ramena dole od uší.',
        'Set a stable position and keep shoulders down away from ears.',
      ),
      tr(
        'Prováděj kontrolovaný pohyb cíleného svalu.',
        'Perform a controlled movement of the target muscle.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Ztráta kontroly ramen.'],
  ),
  'single_arm_cable_lateral_raise': (
    steps: [
      tr(
        'Stůj stabilně, lokty lehce pokrčené.',
        'Stand stable with elbows slightly bent.',
      ),
      tr(
        'Zvedej paže kontrolovaně do výšky ramen (nebo bez bolesti).',
        'Raise your arms with control to shoulder height (or pain-free).',
      ),
      tr(
        'Spouštěj pomalu, nehoupej trupem.',
        'Lower slowly, don\'t swing your torso.',
      ),
    ],
    mistakes: ['Houpání tělem.', 'Zvedání ramen k uším.'],
  ),
  'machine_reverse_fly': (
    steps: [
      tr(
        'Nastav stabilní pozici a drž ramena dole od uší.',
        'Set a stable position and keep shoulders down away from ears.',
      ),
      tr(
        'Prováděj kontrolovaný pohyb cíleného svalu.',
        'Perform a controlled movement of the target muscle.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Ztráta kontroly ramen.'],
  ),
  'rope_face_pull': (
    steps: [
      tr(
        'Nastav stabilní pozici a drž ramena dole od uší.',
        'Set a stable position and keep shoulders down away from ears.',
      ),
      tr(
        'Prováděj kontrolovaný pohyb cíleného svalu.',
        'Perform a controlled movement of the target muscle.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Ztráta kontroly ramen.'],
  ),
  'pike_push_up': (
    steps: [
      tr(
        'Zpevni trup a žebra stáhni dolů, zápěstí nad lokty.',
        'Brace your torso and pull ribs down, wrists over elbows.',
      ),
      tr(
        'Tlač kontrolovaně nahoru v bezbolestné dráze.',
        'Press up with control along a pain-free path.',
      ),
      tr(
        'Spouštěj pomalu do výchozí polohy.',
        'Lower slowly to the starting position.',
      ),
    ],
    mistakes: ['Prohnutí v bedrech.', 'Příliš velká váha a zkrácený rozsah.'],
  ),
  'dumbbell_preacher_curl': (
    steps: [
      tr(
        'Lokty drž blízko těla a trup stabilní.',
        'Keep elbows close to your body and torso stable.',
      ),
      tr(
        'Ohýbej lokty kontrolovaně proti odporu.',
        'Curl with control against resistance.',
      ),
      tr(
        'Spouštěj pomalu do protažení bez houpání.',
        'Lower slowly into a stretch without swinging.',
      ),
    ],
    mistakes: ['Houpání trupem.', 'Zvedání loktů dopředu.'],
  ),
  'cross_body_hammer_curl': (
    steps: [
      tr(
        'Lokty drž blízko těla a trup stabilní.',
        'Keep elbows close to your body and torso stable.',
      ),
      tr(
        'Ohýbej lokty kontrolovaně proti odporu.',
        'Curl with control against resistance.',
      ),
      tr(
        'Spouštěj pomalu do protažení bez houpání.',
        'Lower slowly into a stretch without swinging.',
      ),
    ],
    mistakes: ['Houpání trupem.', 'Zvedání loktů dopředu.'],
  ),
  'cable_biceps_curl_bar': (
    steps: [
      tr(
        'Lokty drž blízko těla a trup stabilní.',
        'Keep elbows close to your body and torso stable.',
      ),
      tr(
        'Ohýbej lokty kontrolovaně proti odporu.',
        'Curl with control against resistance.',
      ),
      tr(
        'Spouštěj pomalu do protažení bez houpání.',
        'Lower slowly into a stretch without swinging.',
      ),
    ],
    mistakes: ['Houpání trupem.', 'Zvedání loktů dopředu.'],
  ),
  'ez_bar_preacher_curl': (
    steps: [
      tr(
        'Lokty drž blízko těla a trup stabilní.',
        'Keep elbows close to your body and torso stable.',
      ),
      tr(
        'Ohýbej lokty kontrolovaně proti odporu.',
        'Curl with control against resistance.',
      ),
      tr(
        'Spouštěj pomalu do protažení bez houpání.',
        'Lower slowly into a stretch without swinging.',
      ),
    ],
    mistakes: ['Houpání trupem.', 'Zvedání loktů dopředu.'],
  ),
  'overhead_rope_extension': (
    steps: [
      tr(
        'Lokty drž stabilně podle typu cviku.',
        'Keep elbows stable according to the exercise type.',
      ),
      tr(
        'Propínej/extenduj paže kontrolovaně.',
        'Extend your arms with control.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Pohyb v rameni místo lokte.'],
  ),
  'assisted_dip': (
    steps: [
      tr(
        'Lokty drž stabilně podle typu cviku.',
        'Keep elbows stable according to the exercise type.',
      ),
      tr(
        'Propínej/extenduj paže kontrolovaně.',
        'Extend your arms with control.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Pohyb v rameni místo lokte.'],
  ),
  'seated_dumbbell_triceps_extension': (
    steps: [
      tr(
        'Lokty drž stabilně podle typu cviku.',
        'Keep elbows stable according to the exercise type.',
      ),
      tr(
        'Propínej/extenduj paže kontrolovaně.',
        'Extend your arms with control.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Pohyb v rameni místo lokte.'],
  ),
  'cable_kickback_triceps': (
    steps: [
      tr(
        'Lokty drž stabilně podle typu cviku.',
        'Keep elbows stable according to the exercise type.',
      ),
      tr(
        'Propínej/extenduj paže kontrolovaně.',
        'Extend your arms with control.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Pohyb v rameni místo lokte.'],
  ),
  'seated_dumbbell_curl': (
    steps: [
      tr(
        'Lokty drž blízko těla a trup stabilní.',
        'Keep elbows close to your body and torso stable.',
      ),
      tr(
        'Ohýbej lokty kontrolovaně proti odporu.',
        'Curl with control against resistance.',
      ),
      tr(
        'Spouštěj pomalu do protažení bez houpání.',
        'Lower slowly into a stretch without swinging.',
      ),
    ],
    mistakes: ['Houpání trupem.', 'Zvedání loktů dopředu.'],
  ),
  'barbell_wrist_curl_seated': (
    steps: [
      tr(
        'Lokty drž blízko těla a trup stabilní.',
        'Keep elbows close to your body and torso stable.',
      ),
      tr(
        'Ohýbej lokty kontrolovaně proti odporu.',
        'Curl with control against resistance.',
      ),
      tr(
        'Spouštěj pomalu do protažení bez houpání.',
        'Lower slowly into a stretch without swinging.',
      ),
    ],
    mistakes: ['Houpání trupem.', 'Zvedání loktů dopředu.'],
  ),
  'diamond_push_up': (
    steps: [
      tr(
        'Lokty drž stabilně podle typu cviku.',
        'Keep elbows stable according to the exercise type.',
      ),
      tr(
        'Propínej/extenduj paže kontrolovaně.',
        'Extend your arms with control.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Pohyb v rameni místo lokte.'],
  ),
  'bench_dip': (
    steps: [
      tr(
        'Lokty drž stabilně podle typu cviku.',
        'Keep elbows stable according to the exercise type.',
      ),
      tr(
        'Propínej/extenduj paže kontrolovaně.',
        'Extend your arms with control.',
      ),
      tr(
        'Vrať pomalu do výchozí polohy.',
        'Return slowly to the starting position.',
      ),
    ],
    mistakes: ['Trhání a příliš velká váha.', 'Pohyb v rameni místo lokte.'],
  ),
  'dead_bug': (
    steps: [
      tr(
        'Zaujmi stabilní pozici a zpevni střed těla.',
        'Set up a stable position and brace your core.',
      ),
      tr(
        'Prováděj pohyb pomalu a kontrolovaně v plném rozsahu.',
        'Move slowly and with control through full range.',
      ),
      tr(
        'Vrať se do výchozí polohy bez trhání.',
        'Return to the starting position without jerking.',
      ),
    ],
    mistakes: [
      tr(
        'Trhaný pohyb a ztráta napětí.',
        'Jerky movement and loss of tension.',
      ),
      tr(
        'Příliš velký rozsah na úkor kontroly.',
        'Too much range at the cost of control.',
      ),
    ],
  ),
  'bird_dog': (
    steps: [
      tr(
        'Zaujmi stabilní pozici a zpevni střed těla.',
        'Set up a stable position and brace your core.',
      ),
      tr(
        'Prováděj pohyb pomalu a kontrolovaně v plném rozsahu.',
        'Move slowly and with control through full range.',
      ),
      tr(
        'Vrať se do výchozí polohy bez trhání.',
        'Return to the starting position without jerking.',
      ),
    ],
    mistakes: [
      tr(
        'Trhaný pohyb a ztráta napětí.',
        'Jerky movement and loss of tension.',
      ),
      tr(
        'Příliš velký rozsah na úkor kontroly.',
        'Too much range at the cost of control.',
      ),
    ],
  ),
  'mountain_climber': (
    steps: [
      tr(
        'Zaujmi stabilní pozici a zpevni střed těla.',
        'Set up a stable position and brace your core.',
      ),
      tr(
        'Prováděj pohyb pomalu a kontrolovaně v plném rozsahu.',
        'Move slowly and with control through full range.',
      ),
      tr(
        'Vrať se do výchozí polohy bez trhání.',
        'Return to the starting position without jerking.',
      ),
    ],
    mistakes: [
      tr(
        'Trhaný pohyb a ztráta napětí.',
        'Jerky movement and loss of tension.',
      ),
      tr(
        'Příliš velký rozsah na úkor kontroly.',
        'Too much range at the cost of control.',
      ),
    ],
  ),
  'toe_touch': (
    steps: [
      tr(
        'Zaujmi stabilní pozici a zpevni střed těla.',
        'Set up a stable position and brace your core.',
      ),
      tr(
        'Prováděj pohyb pomalu a kontrolovaně v plném rozsahu.',
        'Move slowly and with control through full range.',
      ),
      tr(
        'Vrať se do výchozí polohy bez trhání.',
        'Return to the starting position without jerking.',
      ),
    ],
    mistakes: [
      tr(
        'Trhaný pohyb a ztráta napětí.',
        'Jerky movement and loss of tension.',
      ),
      tr(
        'Příliš velký rozsah na úkor kontroly.',
        'Too much range at the cost of control.',
      ),
    ],
  ),
  'farmer_carry': (
    steps: [
      tr(
        'Zvedni váhu kontrolovaně, stůj vzpřímeně a zpevni střed těla.',
        'Lift the weight with control, stand tall, and brace your core.',
      ),
      tr(
        'Kráčej krátkými stabilními kroky, dýchej plynule.',
        'Walk with short stable steps, breathe steadily.',
      ),
      tr('Odlož váhu kontrolovaně.', 'Set the weight down with control.'),
    ],
    mistakes: [
      tr('Naklánění trupu na stranu.', 'Leaning the torso to the side.'),
      tr(
        'Příliš rychlá a nekontrolovaná chůze.',
        'Too fast and uncontrolled walking.',
      ),
    ],
  ),
  'suitcase_carry': (
    steps: [
      tr(
        'Zvedni váhu kontrolovaně, stůj vzpřímeně a zpevni střed těla.',
        'Lift the weight with control, stand tall, and brace your core.',
      ),
      tr(
        'Kráčej krátkými stabilními kroky, dýchej plynule.',
        'Walk with short stable steps, breathe steadily.',
      ),
      tr('Odlož váhu kontrolovaně.', 'Set the weight down with control.'),
    ],
    mistakes: [
      tr('Naklánění trupu na stranu.', 'Leaning the torso to the side.'),
      tr(
        'Příliš rychlá a nekontrolovaná chůze.',
        'Too fast and uncontrolled walking.',
      ),
    ],
  ),
  'cable_pallof_rotation': (
    steps: [
      tr(
        'Zaujmi stabilní pozici a zpevni střed těla.',
        'Set up a stable position and brace your core.',
      ),
      tr(
        'Prováděj pohyb pomalu a kontrolovaně v plném rozsahu.',
        'Move slowly and with control through full range.',
      ),
      tr(
        'Vrať se do výchozí polohy bez trhání.',
        'Return to the starting position without jerking.',
      ),
    ],
    mistakes: [
      tr(
        'Trhaný pohyb a ztráta napětí.',
        'Jerky movement and loss of tension.',
      ),
      tr(
        'Příliš velký rozsah na úkor kontroly.',
        'Too much range at the cost of control.',
      ),
    ],
  ),
  'ab_rollout_barbell': (
    steps: [
      tr(
        'Zaujmi stabilní pozici a zpevni střed těla.',
        'Set up a stable position and brace your core.',
      ),
      tr(
        'Prováděj pohyb pomalu a kontrolovaně v plném rozsahu.',
        'Move slowly and with control through full range.',
      ),
      tr(
        'Vrať se do výchozí polohy bez trhání.',
        'Return to the starting position without jerking.',
      ),
    ],
    mistakes: [
      tr(
        'Trhaný pohyb a ztráta napětí.',
        'Jerky movement and loss of tension.',
      ),
      tr(
        'Příliš velký rozsah na úkor kontroly.',
        'Too much range at the cost of control.',
      ),
    ],
  ),
  'russian_twist_bodyweight': (
    steps: [
      tr(
        'Zaujmi stabilní pozici a zpevni střed těla.',
        'Set up a stable position and brace your core.',
      ),
      tr(
        'Prováděj pohyb pomalu a kontrolovaně v plném rozsahu.',
        'Move slowly and with control through full range.',
      ),
      tr(
        'Vrať se do výchozí polohy bez trhání.',
        'Return to the starting position without jerking.',
      ),
    ],
    mistakes: [
      tr(
        'Trhaný pohyb a ztráta napětí.',
        'Jerky movement and loss of tension.',
      ),
      tr(
        'Příliš velký rozsah na úkor kontroly.',
        'Too much range at the cost of control.',
      ),
    ],
  ),
  'decline_dumbbell_press': (
    steps: [
      tr(
        'Zahákni nohy za polštáře, lehni si na negativní lavici, jednoručky u spodního hrudníku.',
        'Hook feet behind pads, lie on a decline bench, dumbbells at lower chest.',
      ),
      tr(
        'Spouštěj jednoručky pod kontrolou ke spodní části hrudníku, lokty asi 45° od těla.',
        'Lower dumbbells with control to lower chest, elbows about 45° from body.',
      ),
      tr(
        'Vytlač nahoru nad hrudník, lopatky drž stažené k sobě.',
        'Press up over your chest, keep shoulder blades squeezed.',
      ),
    ],
    mistakes: [
      tr(
        'Nezajištěné nohy a klouzání po lavici.',
        'Feet not secured and sliding on the bench.',
      ),
      tr(
        'Odrážení jednoruček od hrudníku.',
        'Bouncing dumbbells off your chest.',
      ),
    ],
  ),
  'dumbbell_squeeze_press': (
    steps: [
      tr(
        'Lehni si na lavici, jednoručky u hrudníku a mačkej je k sobě.',
        'Lie on a bench, dumbbells at chest and press them together.',
      ),
      tr(
        'Tlač jednoručky nahoru a po celou dobu je drž přitisknuté k sobě.',
        'Press dumbbells up while keeping them pressed together the whole time.',
      ),
      tr(
        'Spouštěj pomalu k hrudníku, tlak mezi jednoručkami nepovol.',
        'Lower slowly to chest, don\'t release the squeeze between dumbbells.',
      ),
    ],
    mistakes: [
      tr(
        'Povolení tlaku mezi jednoručkami.',
        'Releasing the squeeze between dumbbells.',
      ),
      tr(
        'Lokty roztažené do stran v pravém úhlu.',
        'Elbows flared out at 90°.',
      ),
    ],
  ),
  'weighted_dips': (
    steps: [
      tr(
        'Zavěs zátěž na opasek, uchop bradla a vytlač se do horní polohy.',
        'Attach weight to a belt, grab the bars and press up to top position.',
      ),
      tr(
        'Mírně se předkloň a spouštěj se, dokud nejsou ramena pod úrovní loktů.',
        'Lean slightly forward and lower until shoulders are below elbows.',
      ),
      tr(
        'Vytlač se nahoru, lopatky drž stažené a pohyb kontroluj.',
        'Press up, keep shoulder blades squeezed and control the movement.',
      ),
    ],
    mistakes: [
      tr(
        'Příliš hluboké spouštění na úkor ramen.',
        'Going too deep at the expense of shoulders.',
      ),
      tr(
        'Houpání zátěže a trhaný pohyb.',
        'Swinging the weight and jerky movement.',
      ),
    ],
  ),
  'machine_fly': (
    steps: [
      tr(
        'Sedák nastav tak, aby madla byla ve výšce hrudníku, záda opři o opěradlo.',
        'Set the seat so handles are at chest height, back against the pad.',
      ),
      tr(
        'Lokty lehce pokrčené, stahuj madla před sebe obloukem.',
        'Elbows slightly bent, bring handles together in front in an arc.',
      ),
      tr(
        'Uprostřed krátce stiskni hrudník a pomalu se vrať do protažení.',
        'Squeeze chest briefly in the middle and slowly return to a stretch.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání loktů, z cviku se stane tlak.',
        'Bending elbows, turning it into a press.',
      ),
      tr(
        'Trhání závaží a hrbení ramen.',
        'Jerking the weight and rounding shoulders.',
      ),
    ],
  ),
  'cable_crossover_low': (
    steps: [
      tr(
        'Kladky dole, uchop madla, krok dopředu a mírný předklon.',
        'Pulleys low, grab handles, step forward and lean slightly.',
      ),
      tr(
        'Lokty lehce pokrčené, táhni ruce obloukem nahoru před sebe.',
        'Elbows slightly bent, bring hands up in an arc in front of you.',
      ),
      tr(
        'Nahoře ruce spoj před horní částí hrudníku a pomalu se vrať.',
        'Bring hands together in front of upper chest and slowly return.',
      ),
    ],
    mistakes: [
      tr(
        'Tahání pažemi místo hrudníku.',
        'Pulling with arms instead of chest.',
      ),
      tr(
        'Příliš velká váha a houpání trupem.',
        'Too much weight and swinging the torso.',
      ),
    ],
  ),
  'meadows_row': (
    steps: [
      tr(
        'Postav se bokem k ose v landminu, uchop konec osy jednou rukou.',
        'Stand sideways to a landmine bar, grab the bar end with one hand.',
      ),
      tr(
        'Předkloň se s rovnými zády, osa visí pod hrudníkem.',
        'Hinge forward with a flat back, bar hanging under your chest.',
      ),
      tr(
        'Přitáhni konec osy k boku, loket těsně kolem těla, a pomalu spusť.',
        'Pull the bar end to your hip, elbow close to body, and lower slowly.',
      ),
    ],
    mistakes: ['Rotace trupu a vytáčení ramen.', 'Kulatá záda v předklonu.'],
  ),
  'seal_row': (
    steps: [
      tr(
        'Lehni si břichem na vyvýšenou lavici, osa leží pod ní.',
        'Lie face down on an elevated bench, bar underneath it.',
      ),
      tr(
        'Uchop osu širokým úchopem a přitáhni ji k spodku lavice.',
        'Grab the bar with a wide grip and pull it to the bottom of the bench.',
      ),
      tr(
        'Spouštěj pomalu až do propnutí paží, trup drž na lavici.',
        'Lower slowly to straight arms, keep torso on the bench.',
      ),
    ],
    mistakes: [
      tr(
        'Zvedání hrudníku z lavice a švihání.',
        'Lifting chest off the bench and swinging.',
      ),
      tr('Krátký pohyb jen v horní části.', 'Short movement only at the top.'),
    ],
  ),
  'kroc_row': (
    steps: [
      tr(
        'Opři se jednou rukou o lavici, v druhé drž těžkou jednoručku.',
        'Brace one hand on a bench, hold a heavy dumbbell in the other.',
      ),
      tr(
        'Záda rovná, přitáhni jednoručku k boku, loket jde kolem těla.',
        'Back flat, pull the dumbbell to your hip, elbow travels close to body.',
      ),
      tr(
        'Spouštěj pod kontrolou, vysoké opakování s klidným tempem.',
        'Lower with control, high reps with a calm tempo.',
      ),
    ],
    mistakes: ['Vytáčení trupu místo tahu zád.', 'Kulatá záda a trhání váhy.'],
  ),
  'cable_pullover': (
    steps: [
      tr(
        'Lehni si na lavici hlavou ke kladce, uchop madlo nad hlavou.',
        'Lie on a bench head toward the pulley, grab handle overhead.',
      ),
      tr(
        'Paže téměř propnuté, táhni madlo obloukem nad sebe směrem k bokům.',
        'Arms nearly straight, pull handle in an arc over you toward your hips.',
      ),
      tr(
        'U stehen krátce zastav a pomalu se vrať do protažení.',
        'Pause briefly at thighs and slowly return to a stretch.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání loktů, z cviku se stane stahování.',
        'Bending elbows, turning it into a pulldown.',
      ),
      tr(
        'Prohýbání beder a zvedání zadku z lavice.',
        'Overarching lower back and lifting hips off the bench.',
      ),
    ],
  ),
  'wide_grip_seated_row': (
    steps: [
      tr(
        'Sedni si, uchop madlo širokým úchopem, záda rovná a hrudník vytažený.',
        'Sit down, grab handle with a wide grip, back straight and chest up.',
      ),
      tr(
        'Táhni madlo k horní části břicha, lokty drž vysoko od těla.',
        'Pull handle to upper belly, keep elbows high away from body.',
      ),
      tr(
        'Vzadu stáhni lopatky k sobě a pomalu se vrať.',
        'Squeeze shoulder blades together at the back and slowly return.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání trupem a záklon při tahu.',
        'Swinging torso and leaning back during the pull.',
      ),
      tr(
        'Pokrčená záda a ramena u uší.',
        'Rounded back and shoulders by ears.',
      ),
    ],
  ),
  'assisted_pull_up': (
    steps: [
      tr(
        'Nastav dopomoc tak, aby šlo udělat 6–10 čistých opakování.',
        'Set assistance so you can do 6–10 clean reps.',
      ),
      tr(
        'Uchop hrazdu, vis s propnutými pažemi a přitáhni bradu nad hrazdu.',
        'Grab the bar, hang with straight arms and pull chin over the bar.',
      ),
      tr(
        'Spouštěj se pomalu až do úplného visu.',
        'Lower slowly to a full hang.',
      ),
    ],
    mistakes: [
      tr('Kopání nohama a švihání.', 'Kicking legs and swinging.'),
      tr(
        'Krátký pohyb bez úplného visu dole.',
        'Short movement without a full hang at the bottom.',
      ),
    ],
  ),
  'weighted_pull_up': (
    steps: [
      tr(
        'Zavěs zátěž na opasek, uchop hrazdu nadhmatem na šířku ramen.',
        'Attach weight to a belt, grab bar overhand at shoulder width.',
      ),
      tr(
        'Z visu přitáhni bradu nad hrazdu, hrudník táhni k hrazdě.',
        'From a hang pull chin over the bar, pull chest toward the bar.',
      ),
      tr(
        'Spouštěj se pod kontrolou až do propnutí paží.',
        'Lower with control until arms are straight.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání zátěže a kopání nohama.',
        'Swinging the weight and kicking legs.',
      ),
      tr('Nedotažení brady nad hrazdu.', 'Not getting chin over the bar.'),
    ],
  ),
  'neutral_grip_pull_up': (
    steps: [
      tr(
        'Uchop madla neutrálním úchopem, dlaně směřují k sobě.',
        'Grab handles with neutral grip, palms facing each other.',
      ),
      tr(
        'Z visu se přitáhni, lokty drž blízko těla, hrudník táhni k madlům.',
        'Pull yourself up from a hang, elbows close to body, chest toward handles.',
      ),
      tr(
        'Spouštěj se pomalu až do úplného visu.',
        'Lower slowly to a full hang.',
      ),
    ],
    mistakes: [
      tr('Kopání nohama a trhaný pohyb.', 'Kicking legs and jerky movement.'),
      tr(
        'Krátký pohyb bez protažení dole.',
        'Short movement without a stretch at the bottom.',
      ),
    ],
  ),
  'snatch_grip_deadlift': (
    steps: [
      tr(
        'Osa nad středem chodidla, uchop ji širokým trhačským úchopem.',
        'Bar over mid-foot, grab it with a wide snatch grip.',
      ),
      tr(
        'Boky jdi níž než u klasického mrtvého tahu, záda a horní část zad pevná.',
        'Set hips lower than a conventional deadlift, back and upper back tight.',
      ),
      tr(
        'Tlač zem nohama a táhni osu těsně kolem nohou až do stoje.',
        'Push the floor with your feet and pull the bar close to legs to standing.',
      ),
    ],
    mistakes: ['Kulatá záda při odlepení osy.', 'Osa se oddaluje od těla.'],
  ),
  'deficit_deadlift': (
    steps: [
      tr(
        'Postav se na nízký stupínek (2–5 cm), osa nad středem chodidla.',
        'Stand on a low platform (2–5 cm), bar over mid-foot.',
      ),
      tr(
        'Uchop osu, boky níž, záda rovná a střed těla zpevněný.',
        'Grab the bar, hips low, back flat and core braced.',
      ),
      tr(
        'Vytlač se z podložky, osa klouže těsně kolem nohou.',
        'Drive off the platform, bar slides close to legs.',
      ),
    ],
    mistakes: [
      tr(
        'Kulatá záda v hlubší výchozí poloze.',
        'Rounded back in the deeper starting position.',
      ),
      tr(
        'Příliš vysoký stupínek a ztráta rovných zad.',
        'Platform too high and loss of flat back.',
      ),
    ],
  ),
  'reverse_hyperextension': (
    steps: [
      tr(
        'Lehni si břichem na stroj, boky na hranu polštáře, uchop madla.',
        'Lie face down on the machine, hips on the pad edge, grab handles.',
      ),
      tr(
        'Zvedej nohy až do linie trupu, pohyb jde z hýždí.',
        'Raise legs until in line with torso, movement comes from glutes.',
      ),
      tr(
        'Spouštěj pomalu, bedra drž v neutrální poloze.',
        'Lower slowly, keep lower back neutral.',
      ),
    ],
    mistakes: [
      tr(
        'Prohýbání beder nad linii trupu.',
        'Hyperextending lower back above torso line.',
      ),
      tr(
        'Švihání nohama místo kontrolovaného tahu.',
        'Swinging legs instead of a controlled pull.',
      ),
    ],
  ),
  'sissy_squat': (
    steps: [
      tr(
        'Uchop se opory, postav se na špičky a zpevni střed těla.',
        'Hold a support, stand on your toes and brace your core.',
      ),
      tr(
        'Kolena tlač dopředu, trup zakláněj dozadu v jedné linii s nohama.',
        'Push knees forward, lean torso back in one line with legs.',
      ),
      tr(
        'Jdi dolů, dokud cítíš tah ve stehnech, a vrať se nahoru.',
        'Go down until you feel a quad stretch, then come back up.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání v bocích, trup jde dopředu.',
        'Bending at hips, torso going forward.',
      ),
      tr('Paty se pokládají na zem.', 'Heels touching the ground.'),
    ],
  ),
  'reverse_nordic': (
    steps: [
      tr(
        'Kleč, kotníky měj zafixované za oporu nebo pod lavicí.',
        'Kneel, ankles secured behind a support or under a bench.',
      ),
      tr(
        'Trup drž v jedné linii s koleny a pomalu se zakláněj dozadu.',
        'Keep torso in one line with thighs and slowly lean back.',
      ),
      tr(
        'Jdi, dokud udržíš napětí ve stehnech, a vrať se zpět.',
        'Go as far as you can keep quad tension, then return.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání v bocích a sedání si na paty.',
        'Bending at hips and sitting on heels.',
      ),
      tr('Příliš rychlé padání dozadu.', 'Falling back too fast.'),
    ],
  ),
  'box_squat': (
    steps: [
      tr(
        'Bednu nastav do hloubky dřepu, osa na trapézech, stoj o něco dál.',
        'Set the box at squat depth, bar on traps, stand slightly farther back.',
      ),
      tr(
        'Posílej boky dozadu a usedni na bednu bez houpání.',
        'Send hips back and sit on the box without bouncing.',
      ),
      tr(
        'Krátce zastav a vytlač se nahoru celým chodidlem.',
        'Pause briefly and drive up through your whole foot.',
      ),
    ],
    mistakes: ['Dosedání s rázem a uvolnění napětí.', 'Kolena padají dovnitř.'],
  ),
  'pause_squat': (
    steps: [
      tr(
        'Osa na trapézech, jdi dolů jako u běžného dřepu.',
        'Bar on traps, squat down like a normal squat.',
      ),
      tr(
        'Dole na 2–3 sekundy zastav, napětí v trupu nepovol.',
        'Pause for 2–3 seconds at the bottom, keep torso tension.',
      ),
      tr(
        'Vytlač se nahoru bez houpání a odrazu.',
        'Drive up without bouncing or rebounding.',
      ),
    ],
    mistakes: [
      tr(
        'Uvolnění břicha a zad v pauze.',
        'Losing core and back tension in the pause.',
      ),
      tr(
        'Odraz z dolní polohy místo tahu.',
        'Bouncing out of the bottom instead of driving up.',
      ),
    ],
  ),
  'safety_bar_squat': (
    steps: [
      tr(
        'Uchop madla bezpečnostní osy, osa leží na trapézech, tělo vzpřímené.',
        'Grab the safety bar handles, bar resting on traps, body upright.',
      ),
      tr(
        'Jdi dolů s koleny ve směru špiček, trup drž co nejvíc vzpřímený.',
        'Go down with knees tracking over toes, keep torso as upright as possible.',
      ),
      tr(
        'Vytlač se nahoru celým chodidlem, madla tlač dopředu.',
        'Drive up through whole foot, push handles forward.',
      ),
    ],
    mistakes: ['Nadměrné předklánění trupu.', 'Kolena padají dovnitř.'],
  ),
  'zercher_squat': (
    steps: [
      tr(
        'Osu uchop do ohbí loktů před tělem, lokty drž u těla.',
        'Hold the bar in the crook of your elbows in front of you, elbows close to body.',
      ),
      tr(
        'Zpevni břicho a jdi dolů s trupem vzpřímeným.',
        'Brace core and squat down with an upright torso.',
      ),
      tr(
        'Vytlač se nahoru, osu drž pevně v loktech celou sérii.',
        'Drive up, keep the bar secure in your elbows the whole set.',
      ),
    ],
    mistakes: ['Kulatá záda a povolený střed těla.', 'Osa se vyklání z loktů.'],
  ),
  'cossack_squat': (
    steps: [
      tr(
        'Stoj široko, špičky mírně ven, ruce před sebou.',
        'Stand wide, toes slightly out, arms in front of you.',
      ),
      tr(
        'Přenášej váhu na jednu nohu a jdi do hlubokého dřepu na ní.',
        'Shift weight to one leg and squat deep on it.',
      ),
      tr(
        'Druhá noha zůstává propnutá, pata na zemi, a vrať se do středu.',
        'Other leg stays straight, heel on the floor, then return to center.',
      ),
    ],
    mistakes: [
      tr('Zvedání paty propnuté nohy.', 'Lifting heel of the straight leg.'),
      tr(
        'Kulatá záda a padání kolen dovnitř.',
        'Rounded back and knees caving in.',
      ),
    ],
  ),
  'curtsy_lunge': (
    steps: [
      tr(
        'Uchop jednoručky, stůj vzpřímeně a zpevni střed těla.',
        'Hold dumbbells, stand upright and brace your core.',
      ),
      tr(
        'Kroč jednou nohou šikmo dozadu za druhou a jdi kolenem k zemi.',
        'Step one leg diagonally back behind the other and lower knee to the floor.',
      ),
      tr(
        'Vytlač se přední nohou zpět, koleno drž ve směru špičky.',
        'Push back up with the front leg, keep knee tracking over toes.',
      ),
    ],
    mistakes: [
      tr('Koleno přední nohy padá dovnitř.', 'Front knee caving inward.'),
      tr(
        'Předklánění trupu a ztráta rovnováhy.',
        'Leaning torso forward and losing balance.',
      ),
    ],
  ),
  'single_leg_press': (
    steps: [
      tr(
        'Nastav menší váhu, jednu nohu dej doprostřed plošiny.',
        'Set a lighter weight, place one foot in the middle of the platform.',
      ),
      tr(
        'Spouštěj plošinu pod kontrolou, koleno ve směru špičky.',
        'Lower the platform with control, knee tracking over toes.',
      ),
      tr(
        'Vytlač patou, koleno na konci nezamykej, boky drž na sedáku.',
        'Press through heel, don\'t lock knee at top, keep hips on the seat.',
      ),
    ],
    mistakes: [
      tr('Zvedání zadku ze sedáku.', 'Hips lifting off the seat.'),
      tr(
        'Příliš velká váha a koleno padající dovnitř.',
        'Too much weight and knee caving inward.',
      ),
    ],
  ),
  'glute_ham_raise': (
    steps: [
      tr(
        'Kleč na GHD stroj, kotníky zafixuj za polštáře.',
        'Kneel on the GHD, secure ankles behind pads.',
      ),
      tr(
        'Trup drž rovný a pomalu se spouštěj dopředu k zemi.',
        'Keep torso straight and slowly lower forward toward the floor.',
      ),
      tr(
        'Zadními stehny se vytáhni zpět do výchozí polohy.',
        'Pull yourself back up using hamstrings to the starting position.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání v bocích místo rovného trupu.',
        'Bending at hips instead of keeping torso straight.',
      ),
      tr('Příliš rychlé padání dopředu.', 'Falling forward too fast.'),
    ],
  ),
  'frog_pump': (
    steps: [
      tr(
        'Lehni si, chodidla spoj k sobě, kolena nech padnout do stran.',
        'Lie down, soles of feet together, let knees fall out to sides.',
      ),
      tr(
        'Jednoručku polož na boky a zvedej pánev krátkým pohybem.',
        'Place a dumbbell on your hips and lift pelvis with a short movement.',
      ),
      tr(
        'Nahoře stáhni hýždě a pomalu se vrať.',
        'Squeeze glutes at top and slowly return.',
      ),
    ],
    mistakes: [
      tr(
        'Prohýbání beder místo tahu hýždí.',
        'Overarching lower back instead of driving with glutes.',
      ),
      tr(
        'Příliš dlouhý pohyb a ztráta napětí.',
        'Movement too long and loss of tension.',
      ),
    ],
  ),
  'smith_hip_thrust': (
    steps: [
      tr(
        'Záda opři o lavici, osu multipresu s polštářem polož na boky.',
        'Back against the bench, place padded Smith bar on your hips.',
      ),
      tr(
        'Chodidla na šířku boků, vytlač pánev nahoru do linie trupu.',
        'Feet hip-width apart, drive hips up in line with torso.',
      ),
      tr(
        'Nahoře stáhni hýždě, bradu drž u hrudníku a pomalu se vrať.',
        'Squeeze glutes at top, keep chin tucked and slowly return.',
      ),
    ],
    mistakes: [
      tr(
        'Prohýbání beder v horní poloze.',
        'Overarching lower back at the top.',
      ),
      tr(
        'Zvedání patek a posouvání chodidel.',
        'Lifting heels and shifting feet.',
      ),
    ],
  ),
  'single_leg_hip_thrust': (
    steps: [
      tr(
        'Záda opři o lavici, jednu nohu dej na zem, druhou zvedni.',
        'Back against the bench, one foot on the floor, other leg raised.',
      ),
      tr(
        'Vytlač pánev nahoru do linie trupu, boky drž rovně.',
        'Drive hips up in line with torso, keep hips level.',
      ),
      tr(
        'Nahoře stáhni hýždě a pomalu se vrať, pak nohy vystřídej.',
        'Squeeze glutes at top and slowly return, then switch legs.',
      ),
    ],
    mistakes: [
      tr(
        'Klesání boků na stranu volné nohy.',
        'Hips dropping on the free-leg side.',
      ),
      tr(
        'Prohýbání beder místo tahu hýždí.',
        'Overarching lower back instead of driving with glutes.',
      ),
    ],
  ),
  'donkey_calf_raise': (
    steps: [
      tr(
        'Předkloň se v bocích, opři se o madla, zátěž na spodku zad.',
        'Hinge at hips, brace on handles, weight on lower back.',
      ),
      tr(
        'Špičky na hranu stupínku, kolena téměř propnutá.',
        'Balls of feet on step edge, knees almost straight.',
      ),
      tr(
        'Vytlač se co nejvýš na špičky a pomalu spusť paty do protažení.',
        'Press up onto toes as high as possible and slowly lower heels into a stretch.',
      ),
    ],
    mistakes: [
      tr(
        'Pérování bez zastavení nahoře.',
        'Bouncing without pausing at the top.',
      ),
      tr('Ohýbání kolen a malý rozsah.', 'Bending knees and short range.'),
    ],
  ),
  'sled_push': (
    steps: [
      tr(
        'Opři se do saní, trup v mírném předklonu, paže propnuté nebo pokrčené.',
        'Lean into the sled, torso slightly forward, arms straight or bent.',
      ),
      tr(
        'Tlač saně krátkými výbušnými kroky, celé chodidlo na zemi.',
        'Push the sled with short explosive steps, whole foot on the ground.',
      ),
      tr(
        'Dýchej plynule a drž napětí v trupu po celou dráhu.',
        'Breathe steadily and keep core tension the whole distance.',
      ),
    ],
    mistakes: [
      tr(
        'Zvedání patek a běh na špičkách.',
        'Lifting heels and running on toes.',
      ),
      tr(
        'Kulatá záda a ztráta tlaku do saní.',
        'Rounded back and loss of drive into the sled.',
      ),
    ],
  ),
  'y_raise': (
    steps: [
      tr(
        'Lehni si břichem na šikmou lavici, jednoručky pod rameny.',
        'Lie face down on an incline bench, dumbbells under shoulders.',
      ),
      tr(
        'Zvedej paže šikmo nahoru do tvaru Y, palce směřují vzhůru.',
        'Raise arms diagonally up into a Y shape, thumbs pointing up.',
      ),
      tr(
        'Nahoře krátce zastav a pomalu spusť, lopatky drž stažené dolů.',
        'Pause briefly at top and lower slowly, keep shoulder blades pulled down.',
      ),
    ],
    mistakes: ['Zvedání ramen k uším.', 'Švihání a prohýbání beder.'],
  ),
  'lean_away_lateral_raise': (
    steps: [
      tr(
        'Kladka dole, uchop madlo vzdálenější rukou a chyť se sloupku.',
        'Low pulley, grab handle with far hand and hold the post.',
      ),
      tr(
        'Zakloň se od sloupku a upažuj madlo do strany do výšky ramen.',
        'Lean away from the post and raise handle out to the side to shoulder height.',
      ),
      tr(
        'Spouštěj pomalu, trup drž v záklonu bez houpání.',
        'Lower slowly, keep torso leaning without swinging.',
      ),
    ],
    mistakes: [
      tr(
        'Houpání trupem a tahání zád.',
        'Swinging torso and pulling with back.',
      ),
      tr(
        'Pokrčené lokty a zkrácený rozsah.',
        'Bent elbows and shortened range.',
      ),
    ],
  ),
  'cable_y_raise': (
    steps: [
      tr(
        'Kladka dole, uchop madla oběma rukama před tělem.',
        'Low pulley, grab handles with both hands in front of body.',
      ),
      tr(
        'Zvedej paže šikmo nahoru do tvaru Y, palce vzhůru.',
        'Raise arms diagonally up into a Y shape, thumbs up.',
      ),
      tr(
        'Nahoře zastav a pomalu spusť, ramena drž dole.',
        'Pause at top and lower slowly, keep shoulders down.',
      ),
    ],
    mistakes: ['Zvedání ramen k uším.', 'Prohýbání beder a švihání.'],
  ),
  'behind_the_neck_press': (
    steps: [
      tr(
        'Osu spusť za hlavu na úroveň uší, lokty pod osou.',
        'Lower the bar behind your head to ear level, elbows under the bar.',
      ),
      tr(
        'Vytlač osu nahoru, hlavu drž neutrálně, pohyb bez trhání.',
        'Press the bar up, keep head neutral, move without jerking.',
      ),
      tr(
        'Spouštěj pomalu, cvik vynech při bolesti nebo ztuhlých ramenou.',
        'Lower slowly, skip this exercise if you have pain or stiff shoulders.',
      ),
    ],
    mistakes: [
      tr(
        'Příliš hluboké spouštění za hlavu.',
        'Lowering too deep behind the head.',
      ),
      tr(
        'Vysunutí hlavy dopředu a kulatá záda.',
        'Poking head forward and rounded back.',
      ),
    ],
  ),
  'z_press': (
    steps: [
      tr(
        'Sedni si na zem s propnutýma nohama, osu drž na ramenou.',
        'Sit on the floor with legs straight, hold bar on shoulders.',
      ),
      tr(
        'Zpevni břicho a vytlač osu nahoru bez záklonu trupu.',
        'Brace core and press the bar up without leaning back.',
      ),
      tr(
        'Spouštěj pomalu na ramena, trup drž kolmo k zemi.',
        'Lower slowly to shoulders, keep torso perpendicular to floor.',
      ),
    ],
    mistakes: [
      tr('Záklon trupu a pomoc nohou.', 'Leaning back and using legs.'),
      tr('Povolený střed těla a kulatá záda.', 'Loose core and rounded back.'),
    ],
  ),
  'dumbbell_upright_row': (
    steps: [
      tr(
        'Jednoručky před stehny, stůj vzpřímeně a zpevni střed těla.',
        'Dumbbells in front of thighs, stand upright and brace core.',
      ),
      tr(
        'Táhni jednoručky podél těla nahoru, lokty vedou pohyb.',
        'Pull dumbbells up along your body, elbows lead the movement.',
      ),
      tr(
        'Zvedej jen do výšky hrudníku a pomalu spusť.',
        'Lift only to chest height and lower slowly.',
      ),
    ],
    mistakes: [
      tr(
        'Tahání až k bradě a vysoko zvednuté lokty.',
        'Pulling up to chin and elbows raised too high.',
      ),
      tr(
        'Houpání trupem a trhaný pohyb.',
        'Swinging torso and jerky movement.',
      ),
    ],
  ),
  'machine_rear_delt_row': (
    steps: [
      tr(
        'Opři se hrudníkem o polštář, uchop madla širokým úchopem.',
        'Brace chest against the pad, grab handles with a wide grip.',
      ),
      tr(
        'Táhni lokty do stran ve výšce ramen, lopatky stáhni k sobě.',
        'Pull elbows out to the sides at shoulder height, squeeze shoulder blades together.',
      ),
      tr(
        'Vracej pomalu do protažení zadních delt.',
        'Return slowly into a rear-delt stretch.',
      ),
    ],
    mistakes: [
      tr(
        'Tahání loktů dolů k tělu místo do stran.',
        'Pulling elbows down to body instead of out to sides.',
      ),
      tr(
        'Zvedání ramen k uším a švihání.',
        'Shrugging shoulders to ears and swinging.',
      ),
    ],
  ),
  'spider_curl': (
    steps: [
      tr(
        'Lehni si břichem na šikmou lavici, paže visí kolmo k zemi.',
        'Lie face down on an incline bench, arms hanging straight down.',
      ),
      tr(
        'Zdvihni jednoručky bez pohnutí loktů, nahoře stáhni biceps.',
        'Curl dumbbells up without moving elbows, squeeze biceps at top.',
      ),
      tr('Spouštěj pomalu až do propnutí.', 'Lower slowly to full extension.'),
    ],
    mistakes: ['Zvedání loktů od lavice.', 'Švihání a zkrácený rozsah.'],
  ),
  'drag_curl': (
    steps: [
      tr(
        'Osu uchop na šířku boků, drž ji před stehny.',
        'Grab the bar at hip width, hold it in front of thighs.',
      ),
      tr(
        'Táhni osu těsně podél trupu nahoru, lokty posílej dozadu.',
        'Pull the bar close up along your body, drive elbows back.',
      ),
      tr(
        'Zvedej do spodní části hrudníku a pomalu spusť podél těla.',
        'Lift to lower chest and slowly lower along your body.',
      ),
    ],
    mistakes: [
      tr(
        'Vyklánění loktů dopředu jako u běžného zdvihu.',
        'Elbows drifting forward like a regular curl.',
      ),
      tr(
        'Houpání trupem a oddálení osy od těla.',
        'Swinging torso and bar drifting away from body.',
      ),
    ],
  ),
  'zottman_curl': (
    steps: [
      tr(
        'Zdvihni jednoručky podhmatem jako u běžného bicepsového zdvihu.',
        'Curl dumbbells up underhand like a regular biceps curl.',
      ),
      tr(
        'Nahoře otoč dlaně dolů a spouštěj pomalu nadhmatem.',
        'At top rotate palms down and lower slowly overhand.',
      ),
      tr(
        'Dole otoč dlaně zpět vzhůru a opakuj.',
        'At bottom rotate palms back up and repeat.',
      ),
    ],
    mistakes: [
      tr('Rychlé spouštění bez kontroly.', 'Lowering fast without control.'),
      tr(
        'Rotace předloktí už při zdvihu nahoru.',
        'Rotating forearms already on the way up.',
      ),
    ],
  ),
  'cable_preacher_curl': (
    steps: [
      tr(
        'Nastav Scottovu lavici ke kladce, paže opři o polštář.',
        'Set a preacher bench at the pulley, rest arms on the pad.',
      ),
      tr(
        'Zdvihni madlo bez zvedání loktů, nahoře stáhni biceps.',
        'Curl handle without lifting elbows, squeeze biceps at top.',
      ),
      tr(
        'Spouštěj pomalu, napětí kladky drž po celý rozsah.',
        'Lower slowly, keep cable tension through full range.',
      ),
    ],
    mistakes: ['Zvedání loktů z polštáře.', 'Odraz závaží v dolní poloze.'],
  ),
  'jm_press': (
    steps: [
      tr(
        'Lehni si, osu uchop úzkým úchopem nad hrudníkem.',
        'Lie down, grab the bar with a narrow grip over chest.',
      ),
      tr(
        'Spouštěj osu k bradě, lokty nech jít mírně dopředu.',
        'Lower the bar toward chin, let elbows drift slightly forward.',
      ),
      tr(
        'Vytlač osu zpět nahoru, pohyb je mezi tlakem a francouzským tlakem.',
        'Press the bar back up, movement is between a press and a skull crusher.',
      ),
    ],
    mistakes: [
      tr('Lokty roztažené do stran.', 'Elbows flared out to the sides.'),
      tr(
        'Spouštění osy na hrudník místo k bradě.',
        'Lowering bar to chest instead of toward chin.',
      ),
    ],
  ),
  'tate_press': (
    steps: [
      tr(
        'Lehni si na lavici, jednoručky drž nad hrudníkem, dlaně k sobě.',
        'Lie on a bench, hold dumbbells over chest, palms facing each other.',
      ),
      tr(
        'Lokty drž do stran a spouštěj jednoručky k hrudníku ohnutím loktů.',
        'Keep elbows out to sides and lower dumbbells to chest by bending elbows.',
      ),
      tr(
        'Propni lokty a vrať jednoručky nad hrudník.',
        'Extend elbows and return dumbbells over chest.',
      ),
    ],
    mistakes: [
      tr(
        'Spouštění jednoruček k bokům místo k hrudníku.',
        'Lowering dumbbells to sides instead of to chest.',
      ),
      tr(
        'Příliš velká váha a trhaný pohyb.',
        'Too much weight and jerky movement.',
      ),
    ],
  ),
  'ez_bar_overhead_extension': (
    steps: [
      tr(
        'Uchop EZ osu úzkým úchopem a zvedni ji nad hlavu.',
        'Grab EZ bar with a narrow grip and lift it overhead.',
      ),
      tr(
        'Lokty drž u hlavy a spouštěj osu za hlavu ohnutím loktů.',
        'Keep elbows by head and lower the bar behind head by bending elbows.',
      ),
      tr(
        'Propni lokty a vrať osu nad hlavu, horní část paží drž nehybně.',
        'Extend elbows and return bar overhead, keep upper arms still.',
      ),
    ],
    mistakes: ['Rozjíždění loktů do stran.', 'Prohýbání beder a pomoc trupem.'],
  ),
  'rope_pushdown': (
    steps: [
      tr(
        'Kladka nahoře, uchop lano, lokty drž u těla.',
        'Pulley high, grab rope, keep elbows at your sides.',
      ),
      tr(
        'Stahuj lano dolů a na konci ho roztáhni od sebe.',
        'Push rope down and spread it apart at the bottom.',
      ),
      tr(
        'Vracej pomalu, horní část paží drž nehybně.',
        'Return slowly, keep upper arms still.',
      ),
    ],
    mistakes: [
      tr(
        'Lokty se posouvají dopředu a dozadu.',
        'Elbows shifting forward and back.',
      ),
      tr(
        'Houpání trupem a trhaný pohyb.',
        'Swinging torso and jerky movement.',
      ),
    ],
  ),
  'single_arm_pushdown': (
    steps: [
      tr(
        'Kladka nahoře, uchop madlo jednou rukou, loket drž u těla.',
        'Pulley high, grab handle with one hand, keep elbow at your side.',
      ),
      tr(
        'Stahuj madlo dolů až do propnutí a krátce stáhni triceps.',
        'Push handle down to full extension and briefly squeeze triceps.',
      ),
      tr(
        'Vracej pomalu, trup drž bez houpání.',
        'Return slowly, keep torso still without swinging.',
      ),
    ],
    mistakes: ['Pomoc trupem a vytáčení ramen.', 'Loket se oddaluje od těla.'],
  ),
  'reverse_grip_pushdown': (
    steps: [
      tr(
        'Kladka nahoře, uchop madlo podhmatem, dlaně vzhůru.',
        'Pulley high, grab handle underhand, palms up.',
      ),
      tr(
        'Lokty drž u těla a stahuj madlo dolů až do propnutí.',
        'Keep elbows at your sides and push handle down to full extension.',
      ),
      tr(
        'Vracej pomalu, horní část paží drž nehybně.',
        'Return slowly, keep upper arms still.',
      ),
    ],
    mistakes: [
      tr(
        'Vytáčení loktů a pomoc trupem.',
        'Twisting elbows and using torso momentum.',
      ),
      tr(
        'Příliš velká váha a trhaný pohyb.',
        'Too much weight and jerky movement.',
      ),
    ],
  ),
  'sit_up': (
    steps: [
      tr(
        'Lehni si, kolena pokrčená, chodidla na zemi, ruce na hrudníku.',
        'Lie down, knees bent, feet on the floor, hands on chest.',
      ),
      tr(
        'Zvedej trup až k stehen, pohyb veď břichem, ne hlavou.',
        'Raise torso up to thighs, lead with abs, not head.',
      ),
      tr('Spouštěj se pomalu zpět na zem.', 'Lower slowly back to the floor.'),
    ],
    mistakes: ['Tahání hlavy rukama.', 'Trhaný pohyb a odraz od země.'],
  ),
  'decline_sit_up': (
    steps: [
      tr(
        'Zahákni nohy za polštáře a lehni si na negativní lavici.',
        'Hook feet behind pads and lie on a decline bench.',
      ),
      tr(
        'Zvedej trup až k stehen, ruce drž na hrudníku.',
        'Raise torso up to thighs, keep hands on chest.',
      ),
      tr(
        'Spouštěj se pomalu, hlavu drž v prodloužení páteře.',
        'Lower slowly, keep head in line with spine.',
      ),
    ],
    mistakes: [
      tr(
        'Tahání hlavy rukama za krkem.',
        'Pulling head with hands behind neck.',
      ),
      tr(
        'Trhaný pohyb a odraz od lavice.',
        'Jerky movement and bouncing off the bench.',
      ),
    ],
  ),
  'v_up': (
    steps: [
      tr(
        'Lehni si na záda, paže natáhni za hlavu, nohy propnuté.',
        'Lie on your back, arms extended behind head, legs straight.',
      ),
      tr(
        'Současně zvedej trup i nohy a dotkni se rukama špiček.',
        'Raise torso and legs simultaneously and touch your toes with hands.',
      ),
      tr(
        'Spouštěj obě části těla pomalu zpět, bedra drž na zemi.',
        'Lower both parts of body slowly back, keep lower back on the floor.',
      ),
    ],
    mistakes: [
      tr(
        'Ohýbání kolen a zkrácený rozsah.',
        'Bending knees and shortened range.',
      ),
      tr(
        'Trhaný pohyb a dopad beder na zem.',
        'Jerky movement and lower back slamming down.',
      ),
    ],
  ),
  'pallof_press': (
    steps: [
      tr(
        'Kladka ve výšce hrudníku, stůj bokem ke stroji, madlo u hrudníku.',
        'Pulley at chest height, stand sideways to the machine, handle at chest.',
      ),
      tr(
        'Vytlač madlo před sebe a odolávej rotaci trupu.',
        'Press handle forward and resist torso rotation.',
      ),
      tr(
        'Vydrž 2–3 sekundy a vrať madlo k hrudníku, pak strany vystřídej.',
        'Hold for 2–3 seconds and return handle to chest, then switch sides.',
      ),
    ],
    mistakes: [
      tr('Rotace trupu směrem ke kladce.', 'Torso rotating toward the pulley.'),
      tr(
        'Příliš velká váha a povolený střed těla.',
        'Too much weight and loose core.',
      ),
    ],
  ),
  'hanging_windshield_wiper': (
    steps: [
      tr(
        'Vis na hrazdě, nohy zvedni do výšky boků nebo výš.',
        'Hang from the bar, raise legs to hip height or higher.',
      ),
      tr(
        'Otáčej propnuté nohy ze strany na stranu jako stěrače.',
        'Rotate straight legs side to side like windshield wipers.',
      ),
      tr(
        'Pohyb veď břichem, trup drž stabilní a pomalu se vrať.',
        'Lead with abs, keep torso stable and return slowly.',
      ),
    ],
    mistakes: ['Houpání a rotace celého těla.', 'Pokrčené nohy a malý rozsah.'],
  ),
  'weighted_crunch': (
    steps: [
      tr(
        'Lehni si, talíř drž na hrudníku, kolena pokrčená.',
        'Lie down, hold a plate on your chest, knees bent.',
      ),
      tr(
        'Zvedej lopatky ze země výdechem, bedra drž na zemi.',
        'Lift shoulder blades off the floor as you exhale, keep lower back on the floor.',
      ),
      tr(
        'Spouštěj pomalu do protažení břicha.',
        'Lower slowly into an ab stretch.',
      ),
    ],
    mistakes: ['Tahání hlavy a krku.', 'Zvedání beder ze země.'],
  ),
};
