# Progress log

## Časová osa

| Datum čas | Okno/branch | Krok |
|---|---|---|
| 2026-10-27 | bidnej / bidnej/black-october | Bezpečnostní update závislostí po „Black October“ |
| 2026-10-27 | bidnej / bidnej/beta8 | Audit beta.7 + nápady 6, 9, 4, 15 (1RM, trend váhy, řazení cviků, oblíbená jídla) |
| 2026-10-27 | bidnej / bidnej/beta8 | Nápady 13 a 10: sdílení odznaku, porovnání dvou tréninků |
| 2026-10-28 | bidnej / bidnej/beta8 | 18 konceptů úvodní obrazovky „životní dashboard“ (gym, strava, běh) |
| 2026-10-28 | bidnej / bidnej/beta8 | Koncepty v2: 20 brandových směrů s animacemi |
| 2026-10-28 | bidnej / bidnej/beta8 | Vzhled „Závod“ podle hlasování testerů (F1 + telemetrie), nový výchozí |
| 2026-10-28 | bidnej / bidnej/beta8 | Finalisté 01–03: vlastní rozhraní pro priority, trénink, zápis série a stravu |
| 2026-10-30 | tomas / tomas/finaliste | Finále pro testery: mobilní verze, vítěz, zpětný odkaz, hlasování, publikováno |
| 2026-10-30 | tomas / tomas/finaliste | Finále veřejně bez přihlášení: Cloudflare Pages + hlasy v KV |

## 2026-10-27 — Bezpečnostní update závislostí (Black October)

**Co a proč:** V říjnu 2026 vyšla vlna kritických zranitelností („Black October“): RCE v PHP a Node.js,
otrávený LiteLLM 1.107.0 na PyPI, kompromitované mezilehlé CA eMudhra (řeší certifi 2026.10.19+),
RCE v Next.js. Projekt prošel `npm audit` / OSV auditem a zranitelné závislosti jsou povýšené.

**Změny:** worker: vitest 3 → 5 (kritické RCE v tinypool, path traversal v @vitest/mocker), wrangler → 4.152, override undici 7.30.1 (miniflare má pevně 7.28.0 s DoS/SRI chybami), sharp.

**Ověření:** 36/36 testů, typecheck, `wrangler deploy --dry-run` i `wrangler dev` OK, npm audit 0. Branch vychází z `cviceni`.

**Co zůstává:** lokální Node 24.18.0 a PHP 8.5.8 na PC jsou zranitelné — aktualizovat na Node 24.22.1+ a PHP 8.5.12+.

## 2026-10-27 — beta.8, první dávka: audit a čtyři nápady (bidnej)

**Co a proč:** Z beta.7 nepřišla zpětná vazba z telefonu, tak jsem udělal vlastní audit jako tester
a vybral malé nápady, které běží jen lokálně (bez serveru). Branch `bidnej/beta8` z `cviceni`.

**Nové funkce:**
- **Kalkulačka 1RM** (nápad 6): na detailu cviku tabulka 3–12 opakování z nejlepší série.
  `weightForReps` je obrácený Epley (1RM / (1 + reps/30)), zaokrouhlený dolů na 2,5 kg —
  dolů proto, aby odhad nikdy nebyl těžší než realita. Příklad: 100 kg 1RM na 10 opak. = 100 / 1,333 = 75 kg.
- **Trend tělesné váhy** (nápad 9): klouzavý průměr za 7 dní. Jednotlivá vážení jsou slabé tečky,
  průměr je čára — denní výkyvy (voda, jídlo) přestanou přehlušovat skutečný trend.
- **Řazení cviků tažením** (nápad 4): v menu cviku „Seřadit cviky“ → list s úchyty.
- **Oblíbená jídla** (nápad 15): podržení čipu „Rychle přidat“ nebo hvězdička v listu přidání.
  Max 12, ukládá se do profilu i do zálohy (rozbitá data záloha odmítne).

**Audit — opraveno:** trenér nepošle otázku dvakrát (synchronní zámek), historie chatu v paměti
max 30 zpráv, jídla 0:00–3:59 jsou „V noci“ místo „Snídaně“, z textů trenéra pryč znak „→“
(na webu se kreslil jako čtvereček). Lišta „Je dostupná nová verze“ na webu trvale zakrývala
spodní navigaci i tlačítko Hotovo v listu série — má teď „Později“ a odsazení od spodku displeje.

**E2E:** skripty `e2e_consent` a `e2e_pwa` byly zastaralé (uvítání má nově krok „Tvůj plán“, série
se zadává v listu s velkými čísly) — aktualizované, všechny tři E2E projdou.

**Výsledky:** `flutter analyze` čistý, 335 testů, web runtime 3/3, E2E workout + PWA + consent OK.

**Pro Tomáše (nesahal jsem, je to nasazení ven):** Worker `ALLOWED_ORIGINS` nemá produkční origin;
`GLOBAL_DAILY_CAP=100` při +2 za dotaz = asi 50 AI dotazů denně pro všechny testery dohromady.

**Další krok:** nápady 13 (sdílení odznaku), 10 (porovnání dvou tréninků), 2 (drop set / do selhání).

## 2026-10-27 — Sdílení odznaku a porovnání dvou tréninků (bidnej)

**Co a proč:**
- **Sdílení odznaku** (nápad 13): v detailu odemčeného odznaku tlačítko „Sdílet odznak“ → tmavá
  karta 360×450 s medailí → PNG přes systémové sdílení (na webu stažení). Sdílecí list karty tréninku
  jsem zobecnil na `ShareImageSheet`, takže obě karty jdou stejnou cestou (žádný duplikovaný kód).
- **Porovnání dvou tréninků** (nápad 10): v historii menu tréninku → „Porovnat s jiným“ → výběr
  (u každého počet společných cviků) → stránka Porovnání. Novější je vždy vlevo, ať se trénink
  otevře odkudkoli. Cviky se párují podle cviku (stejný cvik dvakrát podle pořadí), cviky jen
  z jednoho tréninku jsou na konci s popiskem „Jen <datum>“. Šipky trendu používají stejné
  `compareExercise` jako souhrn po tréninku. Dva tréninky z jednoho dne rozliší čas.

**Výsledky:** analyze čistý, 337 testů (nové: párování cviků, celý tok porovnání na 320 px,
otevření karty odznaku). Vizuálně ověřeno ve web buildu na 320 px (tmavý vzhled).

**Další krok:** nápad 2 — typ série drop set / do selhání.

## 2026-10-28 — Koncepty: z gym zápisníku životní dashboard (bidnej)

**Co a proč:** Tomáš chce, aby aplikace byla spíš life assistant: Gym je jedna záložka, Strava další,
k tomu běh a celkový přehled dne. Než se začne cokoli předělávat v Flutteru, je potřeba vybrat
navigaci a styl úvodní obrazovky — proto interaktivní koncepty v jednom HTML.

**Výstup:** `docs/design/life-dashboard-koncepty.html` — 18 proklikatelných telefonů. Liší se:
- **navigací:** spodní lišta 4–5 záložek, 2 záložky nahoře (Dnes/Deník, Gym/Strava), plovoucí pilulka,
  podtržené horní záložky, boční lišta, středové tlačítko + s nabídkou zápisu, hamburger menu;
- **úvodem:** kruhy dne, časová osa dne, bento, skóre dne, AI trenér jako první, týdenní pás,
  „co teď“, swipe karty, mapa běhu, návyky s heatmapou, tělo s regenerací, terminál;
- **paletou:** současná limetka na černé, modrá, růžová, oranžová, mátová, fialová, světlé papírové atd.

Vnitřní obrazovky (Gym, Strava, Běh, Deník) jsou sdílené a přebírají barvy konceptu, ať jde porovnat
hlavně vstup a navigaci. Ověřeno v Chrome přes Playwright: 0 chyb v konzoli, 400 px bez přetečení,
klik karta → Gym, + → nabídka, menu → šuplík.

**Rozbor běhu:** 1) ruční zápis hned, 2) import z Health Connect / Apple Zdraví, 3) vlastní GPS na pozadí
až nakonec (oprávnění, baterie, iOS sideload).

**Další krok:** Tomáš vybere koncepty → navrhnout detailní Gym nebo Strava rozhraní ve vybraném stylu.

## 2026-10-28 — Koncepty v2: 20 brandových směrů s animacemi (bidnej)

**Co a proč:** první sada 18 konceptů byla funkční, ale vizuálně si byla podobná. Pro výběr brandu je potřeba, aby každý směr měl vlastní styl a vlastní pohyb. Soubor `docs/design/life-dashboard-koncepty.html` je přepsaný od nuly.

**Engine (sdílený pro všechny koncepty):**
- Motion tokeny v CSS: instant .12 s, quick .28 s, base .45 s, slow .7 s, cine 1.1 s, easing `cubic-bezier(.22,1,.36,1)`, stagger .07 s.
- Animace se v telefonu spustí, až je telefon na obrazovce (IntersectionObserver, jednorázově).
- Počítadla: animovaná hodnota je `aria-hidden`, skutečná zvlášť pro čtečku.
- Kruhy a křivky se dokreslují (`pathLength`). Navigace má přejíždějící indikátor. Přechod obrazovek: stará odejde, pak přijde nová.
- `prefers-reduced-motion` obsah ukáže hned.
- CSS každého konceptu je scoped přes `.phone[data-c]`.
- Hvězdičkou jdou označit favority (localStorage), dole je lišta ke zkopírování výběru.

**20 směrů:**

| # | Koncept | Styl | Navigace |
|---|---|---|---|
| 01 | Aktivita | Apple Fitness | lišta |
| 02 | Tensor | NVIDIA | horní záložky |
| 03 | Pit wall | F1, stránka jezdce | lišta |
| 04 | Série | Hevy | lišta |
| 05 | Sklo | glassmorphism | pilulka |
| 06 | Deník těla | editorial | výsuvné menu |
| 07 | Hlasitě | neo-brutalismus | lišta |
| 08 | Trenér | chat | lišta + tlačítko + |
| 09 | Oblouk dne | wellness, slunce | lišta |
| 10 | Bento | bento grid | pilulka |
| 11 | Regenerace | recovery skóre | lišta |
| 12 | Příběhy | stories | pilulka |
| 13 | Sever | skandinávský, 2 záložky | 2 záložky nahoře |
| 14 | Trasa | mapa běhu | boční lišta |
| 15 | Klid | pastel, nálada | lišta |
| 16 | Terminál | CLI | horní záložky |
| 17 | Návyky | checklist | lišta + tlačítko + |
| 18 | Mapa těla | anatomie | lišta + tlačítko + |
| 19 | Arkáda | synthwave, XP | lišta |
| 20 | Atelier | luxus, zlato | 2 záložky nahoře |
| 2026-10-30 | tomas / tomas/app-vibe | P0: pohybové tokeny, haptika, bez lepivých tooltipů |
| 2026-10-30 22:50 | tomas/app-vibe | P1: pravdivý a jednající trenér |
| 2026-10-30 | tomas/app-vibe | P2: první trénink bez tření (startovní váhy, přenos sérií, dokončení) |
| 2026-10-30 | tomas/app-vibe | P3: souhrn jako zážitek – verdikt kouče, cíle na příště, další trénink, animace |
| 2026-10-30 | tomas/app-vibe | P4: tři taby Trénink·Pokrok·Strava, záložka Pokrok, domov jen o dnešku |
| 2026-10-31 | tomas/app-vibe | P5: onboarding s kvízem, odhalením plánu a připomínkou, doporučený cíl bílkovin |
| 2026-10-31 | tomas/app-vibe | P6: web hostovaný na Cloudflare, AI z webu, polish a E2E pro nový úvod |

**Ověření (Playwright, Chrome):**
- Všech 20 telefonů jsem proklikal přes všech 5 obrazovek a otevřel všechny menu a sheety: 0 chyb v konzoli.
- Při 400 px je `scrollWidth` 400, tedy bez přetečení.
- Všechna počítadla skončí na cílové hodnotě.
- V režimu reduced-motion je vidět všech 20 konceptů.

**Co nefungovalo:**
- Pilulka v konceptu 05: scoped barva přebila aktivní stav a vznikla bílá ikona na bílé pilulce. Opraveno přes `:not([aria-current])`.
- Text v příběhu se překrýval s nápovědou. Opraveno.

**Další krok:** Tomáš vybere jeden směr, případně kombinaci (navigace z jednoho, barvy z druhého). Pak teprve přenesu vybraný styl do Flutteru jako tokeny a novou úvodní obrazovku.

## 2026-10-28 — Vzhled „Závod“ podle hlasování testerů (bidnej)

**Co a proč:** Testeři vybrali z konceptů 03 Pit wall (F1, 2 hlasy + návrh) a 02 Tensor (1 hlas).
Místo dalšího konceptu je výsledek rovnou v aplikaci jako nový vzhled **Závod**, který je výchozí.
F1 dává základ (tmavá tabule, závodní červená, kurzíva, startovní světla, pořadí), Tensor telemetrii
(číslo tréninku jako vodoznak, štítek ŽIVĚ, zelená pro rekordy). Spec: `docs/design/zavod-design.md`.

**Změny:**
- `Look.pitwall` v tokenech: vlastní tmavá paleta, asymetrické rohy 4/12, nadpisy kurzíva w900.
- Vždy tmavý; v Nastavení se v Závodu skryje volba Světlý/Tmavý i výběr barvy (nic by nezměnily).
- Dnes: hero karta s vodoznakem, světla před „Začít“, ŽIVĚ u běžícího tréninku, „Pořadí rekordů“ P1–P3.
- Reduced motion: světla svítí hned, vodoznak a tečka stojí.

**Ověření:** `flutter analyze` 0 problémů; nové testy (paleta Závodu, světla s/bez reduced motion);
dva staré testy upravené na nový výchozí vzhled. Kontrast hlídá `contrast_test` (akcent 5,1 : 1, CTA 5 : 1).

**Co nefungovalo:** První běh testů padl na dvou místech: přepínač Světlý v Závodu nic nedělal
(proto je teď skrytý) a „Studio“ se v úvodu posunulo pod obrazovku.

**Další krok:** zpětná vazba testerů na telefonu, pak release beta.8.

## 2026-10-28 — Finalisté 01–03 se vším rozhraním vedle sebe (bidnej)

**Co a proč:** Tomáš chtěl finalisty (01 Aktivita, 02 Tensor, 03 Pit wall) porovnat celé,
ne jen úvodní obrazovku. `docs/design/finaliste.html` ukazuje mřížku 3 koncepty × 4 obrazovky
bez klikání: Priority, Trénink, V tréninku, Strava. Každý koncept řeší obrazovky jinou strukturou,
ne jen barvou (Apple: jedna věc naráz a kruhy; Tensor: tabulky a telemetrie; F1: závodní metafory).

**Rozhodnutí:** Běh vypadl z hlavních obrazovek. Nová obrazovka Priority (první spuštění, později
Nastavení) určí pořadí Síla / Strava / Regenerace / Deník. Běh je volitelný modul, výchozí vypnutý.

**Ověření:** prohlížeč 1280 px a 400 px, 0 chyb v konzoli, stránka bez vodorovného přetečení
(řádky telefonů se na mobilu posouvají do strany). Opraveno: kruh ve Stravě 01 zajížděl pod lištu
a slot BOX v 03 omylem dědil žlutou barvu pit stopu.

**Další krok:** hlasování testerů po obrazovkách, pak Priority do aplikace (onboarding + Nastavení).

## 2026-10-30 · Finále pro testery na mobilu + hlasování (tomas/finaliste)

**Co a proč:** testeři otevírají odkaz na telefonu, ale stránka finalistů měla tři telefony vedle sebe
(1136 px na řádek). Na úzké obrazovce je teď každý řádek karusel na swipe se zarážkou (scroll-snap)
a telefony jsou zmenšené na 80 % (`zoom:.8`, 288 px). Nad každým telefonem je štítek konceptu, protože
lepicí hlavička sloupců na mobilu nedává smysl. Na široké obrazovce zůstává mřížka a hlavička
konečně lepí (dřív ji rozbíjel `overflow-x` na obalu).

**Přidáno:**
- Horní lišta: odkaz zpět na 20 konceptů z 1. kola a tlačítko „Hlasovat“.
- Pruh „P1 · Vítěz 1. kola: 03 Pit wall“ a žlutý štítek vítěze u sloupce i u telefonů.
- Formulář: u každé z 4 obrazovek a „celkově“ volba 01/02/03, poznámka, přezdívka.
  Hlas se ukládá do databáze artefaktu (`votes/<id>`, každý přepisuje jen svůj, čtou všichni),
  průběžné výsledky se kreslí živě, poznámky vidí jen Tomáš.
- Kdo není přihlášený na claude.ai, dostane hotový text hlasu a tlačítko „Zkopírovat“, ať ho pošle zprávou.
- Animace telefonů: místo pozastavení (prvky visely na průhlednosti 0) se před zobrazením nespouští
  vůbec, takže stránka je kompletní i bez scrollování.
- Stránka konceptů má nahoře odkaz na finále a Pit wall štítek „vítěz 1. kola“.

**Ověření:** 390 px: tělo stránky bez přetečení, řádky 956/390 px scrollují samy, telefon 288 px,
0 chyb v konzoli; odeslání bez přihlášení ukáže text k zkopírování. Databáze hlasů po publikaci
odpovídá (prázdná kolekce `votes`).

**Odkazy:** finále https://claude.ai/code/artifact/8b5559c5-c88d-424d-9f8e-b5b305effb40 ·
koncepty https://claude.ai/code/artifact/507b7536-4470-4ca8-88ba-debc3dacd292
(soukromé, Tomáš je musí sdílet přes Share).

**Další krok:** sesbírat hlasy, podle nich složit obrazovky a udělat onboarding priorit v aplikaci.

## 2026-10-30 · Finále veřejně bez přihlášení (tomas/finaliste)

**Proč:** artefakt na claude.ai jde otevřít jen s přihlášením, testeři účet nemají.

**Co:** stránky běží zdarma na Cloudflare Pages: https://gymzapisnik-finale.pages.dev/
(koncepty na `/koncepty`). Zdroj je pořád `docs/design/`, `tool/finale-site/build.py` je zkopíruje
do `public/` a odkazy na artefakty přepíše na relativní. Pages Function `functions/api/votes.js`:
POST uloží hlas do KV `FINALE_VOTES` (klíč `v:<náhodné id prohlížeče>`, volby i v metadatech),
GET vrací jen součty. Poznámky a jména ven nejdou, čtou se přes `wrangler kv key get`.
Stránka mimo claude.ai pozná API a hlasuje přes něj, svůj hlas si pamatuje v localStorage.

**Nasazení:** `python -X utf8 tool/finale-site/build.py` a pak ve `tool/finale-site`
`../../worker/node_modules/.bin/wrangler pages deploy --branch main`.

**Ověření:** veřejná URL 200, API vrací prázdné součty, špatné id odmítne (400). Skutečný hlas
z prohlížeče na 390 px se uložil (status „Hlas je uložený“), testovací záznam jsem z KV smazal.

**Co nefungovalo:** OAuth token wrangleru vypršel uprostřed (projekt a KV se stihly vytvořit,
deploy už ne), Tomáš se znovu přihlásil přes `wrangler login`. Výpis KV je zpožděný až o minutu,
proto součty po odeslání nenaskočí hned; stránka to teď říká.

**Další krok:** rozeslat odkaz, po hlasování vytáhnout součty a poznámky z KV.

## 2026-10-30 · App vibe P0: pohybový systém a hmatová odezva (tomas/app-vibe)

**Proč:** audit ukázal, že se v aplikaci skoro nic nehýbe a odezva na akce je rozházená
(6 míst s různým `HapticFeedback`, doby animací natvrdo). Bez jednoho zdroje pravdy by každá
další fáze přidala vlastní čísla a appka by působila nesourodě.

**Co:**
- `lib/ui/design/motion.dart`: doby 120/280/450/700 ms, křivka `Cubic(.22,1,.36,1)`, rozestup
  70 ms, `Motion.on(context)` respektuje systémové „omezit animace“. Widgety `Reveal` (jednorázový
  vjezd, obsah je ve stromu hned) a `CountUp` (čtečka dostane jen konečnou hodnotu).
- `lib/ui/design/haptics.dart`: odezva podle významu (tick, tap, confirm, record, success, alert).
  Potvrzená série je teď `confirm`, rekord `record`, konec pauzy `alert`.
- Tlačítka potvrzení série, ± v listu série a výměny cviku nemají tooltip (na webu visel přes
  další řádek), popisek pro čtečku je v `Semantics`. Testy hledají přes `test/support/finders.dart`.

**Ověření:** `flutter analyze` čistý, `flutter test` 343/343 včetně nových testů pohybu.

**Další krok:** P1, trenér, který mluví pravdu o dnešním plánu a umí jednat.

## 2026-10-30 — P1: pravdivý trenér, který umí jednat (tomas/app-vibe)

**Co a proč:** AI trenér tvrdil „dnes nic v plánu“, vymýšlel „Full body C“ a psal hvězdičky. Příčina: kontext posílal jen `nextDay` (model ho četl jako „někdy později“), nikdy seznam dnů programu, a prompt nevysvětloval klíče JSON. Hlavní karta a trenér navíc měly každý vlastní výpočet dne.

- `AppState.todaySplitDay` / `pickSplitDay`: jeden zdroj dne pro hlavní kartu i trenéra.
- `coach_context.dart`: `todayPlan` (stav dne, název, „i/n“, cviky s návrhem váhy), `program.days`, `trainingDays`, zbývající dny týdne.
- `worker/src/prompts.ts`: slovník klíčů, zákaz markdownu, odrážky „• “. Worker nasazený.
- `lib/coach/local_coach.dart`: místní odpovědi pro 5 čipů, ranní/večerní přehled, `tidyReply`, hledání stagnace.
- Trenér: „Co mám dnes cvičit?“ odpoví hned bez sítě; při chybě AI místní odpověď; tlačítka „Začít {den}“ a „Otevřít program“; po odpovědi další nabízené otázky.
- Souhlas v úvodu obsahuje AI odstavec, nový uživatel už nedostane druhé okno „Než použiješ AI“.

**Review (subagent) našel a opraveno:** místní odpovědi s vlastními názvy cviků by šly v historii do AI (teď `ChatMessage.local` + `aiHistory`); klasifikátor bral každé „dnes“ jako dotaz na plán; `tidyReply` mazal „3. série“; volba dne se nemazala u jiných startů; dělení nulou u prázdného programu.

**Ověření:** 354 testů zelených, analyze čisté, worker 37 testů. Headless Chrome 390 px: přehled „Dobrý večer. Dnes je na řadě Full body A, 5 cviků. Týden: 0 z 3.“, okamžitá odpověď s plánem, skutečná AI odpověď „Dnes máš na programu celkem 16 sérií“ (4+4+3+3+2 = 16), bez hvězdiček, 0 chyb v konzoli.

**Co nefunguje dobře:** bez historie a bez Pro je u každého cviku „váhu na 5–8 opakování“ — řeší P2 (startovní váhy).

**Další krok:** P2 — první trénink bez tření.

## 2026-10-30 — P2: první trénink bez tření (tomas/app-vibe)

**Proč:** začátečník na prvním tréninku viděl 0 kg, nápovědu „8 opakování“ u předvyplněných 5, každou sérii musel přepisovat zvlášť a po „Dokončit“ s ničím potvrzeným dostal dialog a pak chybu. Přesně tady lidi z appek odcházejí.

**Co se udělalo:**
- `lib/coach/start_weight.dart`: startovní zátěž podle cviku (osa / jednoručky / stroj) a úrovně. Osa nikdy pod 20 kg (bicepsový zdvih a francouzský tlak taky na prázdné ose), jednoručky „na ruku“, pokročilý ×1,5.
- `suggest()`: poprvé předvyplní startovní váhu a dolní hranici rozsahu; nápověda říká rozsah „5–8 opakování“, ne jen horní mez. Startovní váha je i bez Pro.
- Přenos do dalších sérií: `followersOf` při otevření listu určí série se stejnými hodnotami, `carryForward` je při psaní mění. Mezistav („2“ při psaní 25) nechytí ručně zadanou sérii.
- Dokončení: bez potvrzené série nabídne „Pokračovat / Zahodit trénink“; jinak „Hotovo 1 z 16 sérií“ (počítá jen pracovní série s opakováními); „Ukládám…“ až po rozhodnutí; dvojklik neotevře dva dialogy.
- Potvrzení série: řádek a fajfka se plynule zbarví, ikona naskočí (motion tokeny).
- Přístupnost: tlačítka bez tooltipu (P0) splývala s řádkem a čtečka je nemohla zmáčknout. Teď mají vlastní uzel s akcí (Potvrdit sérii, ±, Vyměnit cvik, den v editoru programu).

**Výsledky:** 358 testů zelených, `dart analyze` čistý. Headless průchod v Chrome 390 px: nový uživatel → plán → Full body A předvyplněný 20 kg → změna na 25 kg se přenesla do sérií 2–4 → potvrzení → „Hotovo 1 z 16 sérií“, 0 chyb v konzoli.

**Co nefungovalo:** walker klikal na „Potvrdit sérii“ do středu celého řádku (tím se našla chyba přístupnosti výše).

**Další krok:** P3 — souhrn po tréninku jako zážitek (počítadla, verdikt kouče, náhled dalšího tréninku).

## 2026-10-30 · tomas/app-vibe · P3: souhrn po tréninku jako zážitek

**Co a proč:** souhrn byl tabulka čísel, nic neříkal a nic neslavil. Teď je to moment, kdy aplikace mluví jako trenér: verdikt, cíl na příště, další trénink. Je to místo s největším emočním dopadem, protože rozhoduje, jestli se člověk vrátí.

- `lib/coach/summary_coach.dart` (nový, čistý Dart): `summaryVerdict` (první trénink / rekordy / lepší v X z Y cviků / stejně / slabší den / smíšeně) a `nextTargetLabel` („Barbell squat 25 kg × 6“).
- `AppState.nextSuggestion`: návrh na příště podle plánu nebo výchozích 3× 8–12.
- Souhrn: stats se načítají počítadlem, bloky jedou postupně (`Reveal` se staggerem), haptika `success`, nebo `record`, když padl rekord. Panel kouče, panel „Další trénink“ (den + první 3 cviky).
- Odznaky: časové (Ranní ptáče, Noční směna) jsou menší pill „Bonus“, ne stejná oslava jako „První krok“.
- `durationLabel` místo „0 min“ píše „< 1 min“.

**Review (subagent) našel a opraveno:**
- Verdikt se přepočítával při každém rebuildu → teď se počítá jednou ve State.
- `Trend.added` se počítal jako „stejně jako minule“ → teď ho verdikt přeskočí.
- Víc rekordů napříč cviky dávalo „Nové rekordy: 3.“ → teď „3 nové rekordy“ / „6 nových rekordů“.
- Bloky bez klíčů → klíč podle typu bloku.
- Prázdný den ukazoval „0 cviků · “ → teď jen název dne.
- Opravený pending Timer v `Reveal` (zrušitelný `Timer`).

**Výsledky:** 360 testů zelených, `dart analyze` čistý. Webový průchod: verdikt, „Příště: Barbell squat 25 kg × 6“, „Nový odznak: První krok“, Bonus „Noční směna“, „Další trénink Full body B · 5 cviků“, 0 chyb v konzoli.

**Další krok:** P4, tedy tři taby Trénink · Pokrok · Strava, tab Pokrok z nepoužitých dashboard widgetů a pryč iOS seznam z domovské obrazovky.

## 2026-10-30 · tomas/app-vibe · P4: tři taby, záložka Pokrok, domov jen o dnešku

**Co a proč:** domov končil iOS seznamem nastavení s natvrdo danými barvami a pokrok byl dvě úrovně hluboko. Hotové widgety (křivka síly, rekordy, mise) ležely v kódu, ale nikde se nezobrazovaly. Teď má každá otázka svou záložku. Trénink odpovídá na „co dnes“, Pokrok na „jak se zlepšuju“ a Strava na jídlo.

- `lib/app.dart`: taby Trénink · Pokrok · Strava. Každý má vlastní navigaci a tooltipy jsou vypnuté (na webu zůstávaly viset).
- Záložka se ukládá do `extra['tab']` (0–2). Staré `lastTab = 1` (Strava) se převede na 2.
- `lib/ui/progress/progress_page.dart` (nová):
  - Souhrn s počítadly: tréninky, série a odznaky.
  - Křivka síly nejčastějšího cviku a nedávné rekordy.
  - Přehled: Statistiky, Cviky a rekordy, Historie, Odznaky, Váha, Program, Rady.
  - Před prvním tréninkem místo nul nulový stav „Pokrok začne prvním tréninkem“.
- `dashboard.dart`: mrtvé Material karty (`WeekCard`, `MissionCard`) jsou pryč. Křivka a rekordy jedou v paletě aplikace (`Panel`, akcent; graf se animuje podle `Motion` a respektuje omezení pohybu).
- Domov:
  - Pozdrav podle denní doby.
  - Startovní světla mají význam: jedno světlo na cvik a popisek „5 cviků · ~45 min“. Ostatní vzhledy ukazují jen popisek.
  - „Volný“ a „Sestavit“ jsou sloučené do jednoho tlačítka „Jiný trénink“ se sheetem. Bez plánu zůstává přímé „Volný trénink“.
- Mise mluví z dat. Místo „Dnes je dobrý den na trénink“ ukazuje „Tento týden 1 z 3“ a „Minule před 3 dny, máš odpočinuto.“

**Review (subagent) našel a opraveno:**
- Bez plánu dávalo „Jiný trénink“ nesmysl a stálo klepnutí navíc. Vráceno přímé „Volný trénink“.
- Pokrok počítal rekordy 3× a křivku 2× při každém rebuildu, i když byl skrytý v `IndexedStack`. Teď se počítá jednou a předává kartám.
- `StartLights` nereagovala na změnu dne. Přidán `didUpdateWidget` a znovu se spustí start.
- Popisek pod světly je zarovnaný na střed.
- Pozdrav „Dobrou noc“ je loučení. V noci se teď zdraví „Dobrý večer“.
- Mise s 0 dny: „Dnes už máš trénink za sebou.“

**Výsledky:** 365 testů zelených, včetně nového `progress_page_test` (mise, pozdravy, nulový stav, křivka a rekordy, sheet „Jiný trénink“). `dart analyze` je čistý. Webový průchod: onboarding, domov se světly a „5 cviků · ~45 min“, Pokrok prázdný, trénink, souhrn, Pokrok s daty, 0 chyb v konzoli.

**Další krok:** P5. Onboarding má mít jeden slide s hodnotou, kvíz, odhalení plánu, připomínku a souhlas, s uloženým krokem. K tomu odvozený cíl bílkovin.

## 2026-10-31 · tomas/app-vibe · P5: onboarding s kvízem, odhalením plánu a připomínkou, doporučený cíl bílkovin

**Co a proč:** úvod byl brožura. Tři slidy s funkcemi, výběr barvy, kvíz a souhlas. Krok se neukládal a kvíz začínal od výchozích hodnot. Nový uživatel tak deset obrazovek nic nedostal. Teď úvod vede k jedné věci: k hotovému plánu.

- `onboarding_page.dart` (přepsáno). Kroky:
  - Jeden slide s hodnotou.
  - Kvíz: cíl, počet tréninků, zkušenost, minuty, dny v týdnu a nepovinná váha.
  - Odhalení plánu: program, týden a první trénink s cviky.
  - Připomínka: jen na mobilu, s časy 7–20 h.
  - Souhlas.
- Krok se ukládá do `extra['onboardingStep']`. Po zavření aplikace se úvod vrátí, kde byl, a kvíz čte dřívější odpovědi. Výběr barvy zůstal jen v Nastavení.
- `coach/nutrition_target.dart`:
  - Bílkoviny podle cíle: 1,6–2,0 g na kg, zaokrouhleno na 5 g.
  - Energie: 33 kcal na kg plus přebytek podle cíle, jen pro dospělé. Mladší 18 let kalorický cíl nedostanou.
- Strava bez vlastních cílů:
  - Ukáže doporučení z váhy a tlačítko „Nastavit jako cíl“.
  - Bez váhy nabídne „Zapsat váhu“.
- Domov ve volný den podle plánu psal „Dnes · Full body A“ a vedle „Dnes volno“. Teď píše „Příště · pondělí“ a tlačítko „Začít i dnes“.

**Review (subagent) našel a opraveno:**
- Dny odebrané po návratu do kvízu zůstávaly uložené. Teď se při jiném počtu smažou. Přidán regresní test.
- „Přeskočit“ kvíz a pak zpět vedlo na odhalení plánu, který se neuložil. Teď vede zpět na kvíz.
- Váha 72,55 se uložila jako 72,6 a porovnávala s 72,55, takže každý návrat přidal záznam. Teď se porovnává zaokrouhleně.
- Pole váhy mělo jen nápovědu. Dostalo stálý popisek pro čtečku.
- Nález pro E2E skripty v `tool/`, které čekají starý úvod, je přesunutý do P6.

**Co nefungovalo:** headless průchod dvakrát spadl („Target crashed“). Příčina byla v testeru, ne v aplikaci. Dny mají roli `switch` a tester hledal `button`, takže u každého dne 14× scrolloval a čekal. Měření paměti při 60 scrollech ukázalo stabilních 36–38 MB, takže v aplikaci únik není.

**Výsledky:**
- 372 testů zelených.
- `dart analyze` je čistý.
- Webový průchod s čistým profilem: hodnota → kvíz (Po/St/Pá, 80 kg) → „Plán je hotový“ → souhlas → domov → Strava „Bílkoviny 0 z 160 g, Energie 0 z 2900 kcal, Doporučeno z tvé váhy 80 kg“ → nastavení cíle. Konzole bez chyb.

**Další krok:** P6. AI na hostovaném webu (Cloudflare Pages a ALLOWED_ORIGINS), E2E skripty pro nový úvod a drobný polish.

## 2026-10-31 · tomas/app-vibe · P6: web hostovaný na Cloudflare, AI z webu, polish a E2E pro nový úvod

**Co a proč:** AI trenér na webu nefungoval, protože proxy povolovala jen localhost a hostovaná PWA neexistovala. Teď má aplikace veřejnou HTTPS adresu, ze které AI odpovídá. K tomu drobnosti z auditu a E2E skripty pro nový onboarding a tři taby.

- Hosting: https://gymzapisnik-app.gymzapisnik-ai.workers.dev.
  - Je to statický `build/web` nasazený jako Cloudflare Worker s assety.
  - `pages project create` dnes zakládá Worker a `pages deploy` padal na `worker/wrangler.toml`, proto Worker s `--assets` z prázdné složky.
- `worker/wrangler.toml`: `ALLOWED_ORIGINS` obsahuje hostovaný původ. Proxy je nasazená a preflight z hostingu vrací 204 se správnou hlavičkou.
- Ověřeno živě: otázka trenérovi z hostovaného webu dostala odpověď prostým textem s akcí „Otevřít program“.
- Polish:
  - Chipy otázek u trenéra se čtečce obrazovky ohlašují jako tlačítko (`_QuestionChip`).
  - Vybraný segment v kvízu má akcentový rámeček a podbarvení, ne jen tučné písmo.
  - Vodoznak na hlavní kartě se už neořízne.
  - Načítací přechod respektuje omezení pohybu.
- E2E: `e2e_consent`, `e2e_workout` a `review_mobile` jdou přes „Sestavit můj plán“ a taby Trénink · Pokrok · Strava.
- Past: headless Chrome 156 v persistentním profilu service worker vůbec nezaregistruje, ani u minimální stránky. `navigator.serviceWorker.ready` pak visí a renderer po ~76 s spadne.
  - `e2e_consent` proto běží v dočasném kontextu a na SW čeká nejvýš 20 s s čitelnou chybou.
  - Argument se složkou profilu už nepotřebuje.

**Výsledky:** 372 testů zelených, `dart analyze` čistý. E2E consent (včetně offline reloadu), workout i review_mobile prošly s 0 chybami stránky. Hostovaná verze je nasazená z aktuálního buildu.

**Další krok:** test na fyzickém Androidu a iPhonu (PWA z hostované adresy) a zpětná vazba od testerů. Kvalita AI odpovědí: model se občas opakuje, to je na úpravu promptu.

**Review (subagent) našel a opraveno:**
- Vodoznak rostl se systémovou velikostí písma a při 200 % se ořízl. Teď `TextScaler.noScaling` a jeden řádek.
- Regex v E2E `Začít ` chytal i „Začít trénink“ v jiných listech. Teď `Začít (?!trénink)`.
