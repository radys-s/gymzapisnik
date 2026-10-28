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
