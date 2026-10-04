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
- Další kroky: souhrn a porovnání (M4), historie, splity, dashboard, záloha.

## Vývoj

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # po změně lib/data/database.dart
flutter analyze
flutter test
node --test test/web_runtime_test.cjs
cd scripts && python -m unittest
```

Webová verze:

```bash
flutter build web --release
python scripts/stamp_web_build.py      # verze offline cache podle obsahu buildu
```

E2E testy (běží proti `build/web` servírovanému na `http://localhost:8099`, profil = prázdná složka):
`PLAYWRIGHT_CORE=<cesta k playwright-core> node tool/e2e_consent.cjs <složka profilu>` a
`node tool/e2e_workout.cjs <složka profilu>` (zápis, pauza, reload, opakování série jedním klepnutím).

## Struktura

- `lib/data/` – databáze, úložiště dokumentů, webová perzistence
- `lib/domain/` – čistá logika bez Flutteru (profil, tréninky, statistiky, historie)
- `lib/state/` – stav aplikace pro obrazovky
- `lib/ui/` – obrazovky
- `web/` – PWA: zámek jednoho okna (`app_bootstrap.js`), offline cache (`service_worker.js`)
