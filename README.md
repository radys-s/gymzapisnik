# Gym zápisník (pracovní název)

Česká mobilní aplikace pro zápis tréninků v gymu: rychlý zápis sérií, porovnání s minulým tréninkem,
osobní rekordy, šablony splitů a denní mise. Nástupce zmrazeného projektu `athlete-os`.

Běží jako Android aplikace (APK) a jako webová PWA (iPhone). Data jsou uložená v zařízení (SQLite přes Drift,
na webu v IndexedDB).

## Stav

- **M0 (hotovo):** kostra projektu, lokální úložiště, offline PWA, souhlas s podmínkami a potvrzení věku
  (18+ nebo souhlas zákonného zástupce), navigace Domů / Historie / Cviky.
- **M1 (hotovo):** model tréninku, katalog cviků, statistiky (odhad 1RM, objem, porovnání, osobní rekordy).
- **M2 (hotovo):** zápis tréninku – předvyplnění z minula, potvrzení série jedním klepnutím, rozcvička,
  poznámky, vlastní cviky, dokončení / zahození; rozepsaný trénink přežije zavření aplikace.
- **M3 (hotovo):** pauza mezi sériemi – odpočet podle času konce (sedí i po návratu do aplikace),
  ±15 s, přeskočit, vibrace a zvuk na konci.
- **M4 (hotovo):** souhrn po dokončení – každý cvik proti minulému provedení (série ▲/▼, objem,
  odhad 1RM), nové osobní rekordy, délka a objem tréninku.
- **M5 (hotovo):** historie po měsících, detail tréninku se zopakováním, úpravou a smazáním,
  záložka Cviky s hledáním a detailem cviku (rekordy, graf odhadu 1RM, historie provedení).
- **M6 (hotovo):** 5 šablon splitů (Full body 3×, Upper/Lower, PPL, Arnold, Bro split) a kouč
  v `lib/coach/`: dvojitá progrese (všechny série na horní hranici → +2,5 kg), po dvou
  trénincích bez posunu odlehčení o 10 %. Domů ukazuje „Dnes: <den>" s návrhem pro každý cvik,
  u cviku v tréninku je vysvětlení návrhu.
- **M7 (hotovo):** dashboard na Domů – „Tento týden" (tréninky vůči plánu splitu, série, objem),
  nedávné rekordy (max 3, jeden na cvik) a rychlý progres nejčastějšího cviku s malou křivkou.
- **M8 (hotovo):** Nastavení (ikona na Domů): pauza mezi sériemi, motiv (tmavý/světlý/systém),
  záloha do JSON souboru a obnova (doplní chybějící tréninky, lokální úpravy nepřepíše, souhlas se
  nezálohuje), export CSV pro český Excel (BOM, středník, desetinná čárka, ochrana proti vzorcům),
  smazání všech dat, verze. Fáze A (tracker) je kompletní.
- **B1 (hotovo):** denní mise na Domů (trénuj dnes / máš hotovo / odpočinek / dnes je potřeba) a streak
  po týdnech se žolíkem (zachrání jeden zmeškaný týden, obnoví se za 8 týdnů). Týdenní cíl podle splitu
  nebo vlastní v Nastavení. Logika v `lib/coach/missions.dart` a `streak.dart`.
- **B2 (hotovo):** shrnutí týdne na Domů – objem proti minulému týdnu a počet cviků s novým rekordem.
- **B3 (hotovo):** příprava na Pro – `lib/premium/entitlements.dart`. Dokud je `paywallEnabled = false`,
  je všechno odemčené (testeři). Přehled Pro je v Nastavení. Zamčené Pro: kouč s návrhem váhy, mise
  a streak, shrnutí týdne, rychlý progres. Zdarma navždy: zápis, historie, cviky, záloha, CSV, import.
  Platba později = přepnout konstantu a doplnit nákup.
- B4 hotovo: import z Hevy (workout_data.csv, Nastavení → Import z Hevy, opakovaný import nic nezdvojí).

B6 hotovo: tělesná váha (karta na Domů, graf, záloha).

B5 hotovo: připomínky na Androidu (plán v coach/reminders.dart, oznámení přes flutter_local_notifications; iPhone PWA bez nich).

C (kód hotov, mobilní tok neověřen): výživový deník – karta Výživa na Domů, denní přehled s listováním dnů,
ruční zápis (název, množství, kcal, bílkoviny, sacharidy, tuky; hodnoty na 100 g/ml nebo na porci, prázdné
pole = neznámo, nula = nula), hledání podle čárového kódu v Open Food Facts API v3 (ručně zadané číslo
s kontrolní číslicí; kamera se neskenuje), potvrzení a úprava před uložením, při nenalezení nebo výpadku ruční
zápis, úprava/smazání se „Vrátit", záloha a obnova (nepovinný klíč `foods`, verze zálohy zůstává 1).
Deník je v zařízení a funguje offline; internet je jen pro hledání kódu. Bez cílů a doporučení.
Logika `lib/domain/nutrition.dart`, klient `lib/data/off_client.dart`, UI `lib/ui/nutrition/`.

D1 (kód hotov, živý model neověřen): AI kouč ledničky – Výživa → „Co mám v ledničce“: fotka (image_picker,
na webu výběr souboru) se zmenší na JPEG ≤ 1024 px a pošle přes vlastní proxy (`worker/`, Cloudflare Workers AI,
model Mistral Small 3.1, žádný klíč v aplikaci) → upravitelný seznam potravin (uložený, v záloze jako `pantry`)
→ „Navrhni jídlo“ (10/20/40 min) → 3 návrhy s postupem, časem a odhadem maker (přednostně z místní tabulky
`lib/domain/food_table.dart`, jinak odhad AI) → „Zapsat do deníku“. Jednorázové upozornění před prvním odesláním.
Volitelný denní cíl bílkovin (a energie jen pro dospělé) v Nastavení → Výživa, postup na stránce Výživa.
AI se zapne buildem s `--dart-define=AI_URL=https://<worker>.workers.dev`; bez něj jsou AI tlačítka vypnutá.
Nasazení proxy: [worker/README.md](worker/README.md) (potřebuje `wrangler login` na Tomášově účtu Cloudflare).

R hotovo (kód): verze 1.0.0-beta.2+11, podmínky a soukromí, zpětná vazba, připomínka zálohy po 10 trénincích, podepsaný release APK (keystore lokálně, mimo git), návod docs/TESTERS.md.

Nezávislé review bety, důkazy testů a hranice ověření: [docs/REVIEW.md](docs/REVIEW.md).
Zbývá fyzické Android/iPhone ověření, schválené hostování PWA na HTTPS, rozeslání
APK testerům a sběr zpětné vazby. Název a kontaktní e-mail jsou zachované;
jejich potvrzení a záloha podpisového klíče jsou před distribucí na Tomášovi.

## Vývoj

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # po změně lib/data/database.dart
flutter analyze
flutter test
node --test test/web_runtime_test.cjs
cd worker && npm install && npm test   # AI proxy
cd scripts && python -m unittest
```

Webová verze:

```bash
flutter build web --release
python scripts/stamp_web_build.py      # verze offline cache podle obsahu buildu
```

E2E testy (běží proti `build/web` servírovanému na `http://localhost:8099`, profil = prázdná složka):
`PLAYWRIGHT_CORE=<cesta k playwright-core> node tool/e2e_consent.cjs <složka profilu>` a
`node tool/e2e_workout.cjs <složka profilu>` (zápis, pauza, reload, souhrn, opakování série jedním klepnutím, historie, detail cviku).

## Struktura

- `lib/data/` – databáze, úložiště dokumentů, webová perzistence
- `lib/coach/` – splity a progresní pravidla (čistý Dart)
- `lib/domain/` – čistá logika bez Flutteru (profil, tréninky, statistiky, historie)
- `lib/state/` – stav aplikace pro obrazovky
- `lib/ui/` – obrazovky
- `web/` – PWA: zámek jednoho okna (`app_bootstrap.js`), offline cache (`service_worker.js`)
