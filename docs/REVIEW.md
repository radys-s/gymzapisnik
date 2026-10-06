# Nezávislé review bety — 2026-10-06

Výchozí stav: čistý `main`, HEAD `5abbac5`, `1.0.0-beta.1+10`.
Obsidian kontext a předávka z 2026-10-04 přečteny. Nejnovější dostupná aktivita
Claude patřila školnímu projektu, nikoli gymzapisniku; během práce zde nebyly
zjištěny cizí změny. Existující aplikace byla opravena, rozsah A/B zůstává zachován.

## Reprodukované nálezy a opravy

- **P1 — dvojité potvrzení série.** Dva tapy při pomalém zápisu nastavily `done`
  zpět na `false`. UI nyní čeká na zápis a ignoruje druhý tap v intervalu 300 ms
  i při rychlém úložišti. Pozdější vědomé zrušení potvrzení zůstává dostupné.
- **P1 — chyba dokončení.** Simulované selhání `store.replace` (`disk full`)
  vyhodilo nezachycenou výjimku. Dokončení nyní vrací viditelnou českou chybu,
  obnoví aktivní stav a umožní opakování. Historie vzniká až po úspěšné transakci.
  Opakované dokončení sdílí jednu operaci; UI během ní blokuje další akce a návrat.
  PWA aktualizace počká na dokončení a při jeho selhání odmítne restart.
- **P2 — souběžný Hevy import.** Dvě volání importu stejného CSV vrátila celkem 4
  místo 2 a zdvojila historii v paměti, zatímco databáze obsahovala jen 2 záznamy.
  Parsování, deduplikace, transakce i aktualizace paměti nyní probíhají ve frontě.
  Stejně je serializována obnova zálohy. Lokální úpravy existujících tréninků
  zůstávají zachované.
- **P1/P2 — neplatná záloha.** Duplicitní ID byla přijata. Obnova nyní odmítá
  duplicitní/prázdná/rezervovaná ID, střet s jiným druhem dokumentu či aktivním
  tréninkem, nepodporovanou verzi, neplatné časy a typy nastavení. Kontrola probíhá
  před transakcí; regresní test ověřuje zachování souhlasu i rozepsaného tréninku.
- **Ukládání oprav.** Původní 400ms debounce byl odstraněn. Každá editace pole
  hned pořídí snapshot a zařadí ho do fronty, chybu zobrazí uživateli. Odpadlo
  ukládání z `dispose`, které záviselo na životním cyklu zničeného řádku.
- **Návody.** Zpřesněny podmínky APK aktualizace, prvního offline spuštění,
  obsah zálohy a připomínka po 10 trénincích. Fyzické ověření není vydáváno
  za hotové. Název, e-mail a podpisové klíče jsou zachované.

## Automatické ověření

- Před opravami: `flutter analyze` bez nálezů, původních **114 Flutter testů**
  prošlo. Nová reprodukční sada prokázala 4 selhání uvedená výše; scénář rychlých
  zápisů a okamžitého dokončení při zablokovaném úložišti již původně prošel.
- Po opravách: `flutter analyze --no-pub` bez nálezů, **125 Flutter testů**
  (`flutter test --no-pub -j 2`). Nových 11 regresních testů zahrnuje pořadí
  snapshotů, selhání/obnovu fronty, dvojí dokončení, opravy potvrzené série,
  update při chybě, souběžný import a neplatnou zálohu.
- `node --test test/web_runtime_test.cjs`: **3/3** (zámek jednoho okna,
  reload, odmítnutí neúplné nové offline cache).
- Python `unittest discover -s scripts`: **2/2** (identita cache a chybějící asset).
- `tool/e2e_workout.cjs`: kompletní průchod v Chrome, bez JS chyb — zadání série,
  minulý výkon jedním tapem, pauza, reload, souhrn, historie, detail cviku, split,
  bezplatné Pro, CSV/JSON soubory, obnova a opakovaný Hevy import.
- `tool/e2e_consent.cjs`: první načtení, souhlas, reload a offline spuštění v Chrome,
  bez JS chyb; kontrola souhlasu je navíc pokryta Flutter testy.
- `tool/e2e_pwa.cjs`: skutečná instalace nového service workeru, oprava těsně před
  Načíst, offline reload a ukončení/nové spuštění celého Chrome. Potvrzená série
  82,5 kg × 6 přežila; offline souhrn i historie obsahovaly objem 495 kg.
  Test mění pouze cache ID lokálního buildu a v `finally` vrací původní worker.
- Android release APK a web release build úspěšné. Podpis APK ověřen přes
  `apksigner`: certifikát SHA-256
  `e7f946922b2327964123d928b5e889d2e74c7772a6bd460211e35ad89acb4a9c`
  shodný s beta.1. Balíček `cz.radys.gymzapisnik`, versionCode **11**,
  versionName **1.0.0-beta.2**, minSdk 24, targetSdk 36.
- `paywallEnabled = false`; testy ověřují dostupnost všech Pro funkcí a žádné
  zámky v běžném beta UI. Žádné platby nebyly přidány.

Všechny automatické scénáře používají paměťové databáze nebo oddělené testovací
profily v `build/`. Mazání v existujícím E2E skriptu se týká pouze jeho fixtures.
Uživatelská databáze ani tréninky nebyly otevřeny ke změnám.

## Sestavení a opakování

Verze: **1.0.0-beta.2+11**. Balíčky v ignorované složce `dist/`:

- `gymzapisnik-1.0.0-beta.2.apk`
- `gymzapisnik-1.0.0-beta.2-web.zip` — obsah `build/web`, připravený ke schválenému
  hostování; nebyl publikován.
- `gymzapisnik-1.0.0-beta.2-SHA256.txt`

```powershell
flutter analyze --no-pub
flutter test --no-pub -j 2
node --test test/web_runtime_test.cjs
python -m unittest discover -s scripts
flutter build apk --release --no-pub
flutter build web --release --no-pub --no-wasm-dry-run
python scripts/stamp_web_build.py
python -m http.server 8099 --bind 127.0.0.1 --directory build/web
# V dalším terminálu; nastav PLAYWRIGHT_CORE na nainstalovaný playwright-core.
node tool/e2e_workout.cjs build/novy-testovaci-profil
node tool/e2e_pwa.cjs build/novy-testovaci-profil
node tool/e2e_consent.cjs build/druhy-novy-testovaci-profil
```

Použij nové profily, nikoli osobní profil Chrome ani již dokončený testovací profil.
E2E PWA spusť až po workout scénáři a bez souběžného přestavování `build/web`.
Naměřené výstupy jsou v ignorovaných `build/review-*.log`.

## Fyzické ověření a distribuce — otevřené

- `adb devices` neukázal připojený telefon. Instalace APK přes beta.1,
  skutečný restart/ukončení na Androidu, vibrace/zvuk a doručení oznámení
  při zhasnutém displeji či po restartu **nejsou fyzicky ověřeny**.
  Automatické testy připomínek ověřují plán, vynechání hotových dní/týdnů,
  zrušení a odmítnutí oprávnění přes fake notifier; nedokazují doručení OS.
- Safari / přidání na plochu / offline start / aktualizace na skutečném iPhonu
  **nejsou ověřeny**. Chrome není náhradou za iOS test.
  [WebKit dokumentuje](https://webkit.org/blog/14787/webkit-features-in-safari-17-2/#web-apps)
  oddělené místní úložiště Safari a aplikace z plochy: návod proto vyžaduje
  instalaci před zápisem, případně ruční přenos JSON zálohou. Obecné tvrzení
  o mazání po nečinnosti bylo nahrazeno konkrétními podmínkami úložiště dle
  [WebKit storage policy](https://webkit.org/blog/14403/updates-to-storage-policy/).
- PWA distribuce vyžaduje schválené stabilní HTTPS hostování. Nic nebylo
  publikováno ani rozesláno. Nepoužívat změnu domény jako aktualizaci aplikace.
- Předávka ponechává na Tomášovi potvrzení pracovního názvu a kontaktního e-mailu
  a zálohu keystore mimo repo. Hodnoty nebyly změněny ani klíč kopírován.
- Android má funkční podepsaný balíček pro zahájení interního fyzického testu;
  kontrola podpisu není potvrzení fyzického upgradu. Web archiv je příprava
  distribuce, nikoli běžící iPhone aplikace.

Krátký scénář jednoho tréninku a očekávané výsledky: [TESTERS.md](TESTERS.md).
