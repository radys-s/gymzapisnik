# Gym zápisník

Česká aplikace pro silový trénink, která ti řekne, co máš dnes cvičit. Pak ti pomůže to
zapsat a ukáže, jestli se zlepšuješ. Je pro lidi, kteří chodí do gymu a nechtějí vést
tabulku ani platit předplatné za základní věci.

**Vyzkoušet na webu:** https://gymzapisnik-app.gymzapisnik-ai.workers.dev. Funguje i jako PWA,
v Safari přes Sdílet → Přidat na plochu.

Aplikace běží na Androidu (APK), na iPhonu (IPA k sideloadu) a na webu. Data zůstávají v zařízení:
SQLite přes Drift, na webu IndexedDB. Účet ani server pro data nejsou potřeba.

## Co umí

### Trénink
- **Plán na míru za minutu:** krátký kvíz (cíl, dny v týdnu, úroveň, čas, volitelně váha) sestaví
  program z pěti splitů (Full body, Upper/Lower, PPL, Arnold, Bro split).
- **Dnešní trénink na domovské obrazovce:** ukazuje, jaký den je na řadě, počet cviků a odhad
  délky. Ve dny volna podle plánu ukazuje příští trénink.
- **Rychlý zápis:** série jsou předvyplněné z minula nebo rozumnou startovní váhou. Potvrzení je
  jedno klepnutí. Úprava série se přenese do dalších nepotvrzených sérií.
- **Kouč v aplikaci:** dvojitá progrese (všechny série na horní hranici → +2,5 kg), po stagnaci
  odlehčení. U každého cviku je vysvětlení, proč má takovou váhu.
- **Pauza mezi sériemi:** odpočet podle času konce, takže sedí i po návratu do aplikace. Na konci
  vibruje a pípne.
- **Souhrn po tréninku:** srovnání s minulým tréninkem, nové rekordy, verdikt kouče, cíle na příště
  a náhled dalšího tréninku.

### Pokrok
- Křivka síly (odhad 1RM), osobní rekordy, statistiky, kalendář a historie po měsících.
- Týdenní mise a streak se žolíkem na jeden zmeškaný týden. K tomu odznaky a tělesná váha s trendem.
- Detail cviku: rekordy, graf a všechna provedení. Porovnání dvou tréninků.

### Strava
- Deník jídel s makry a vyhledávání podle čárového kódu (Open Food Facts). Oblíbená jídla.
- Doporučený denní cíl bílkovin podle váhy a cíle. Energie se doporučuje jen dospělým.
- **AI lednička:** z fotky lednice sestaví seznam potravin a navrhne tři jídla s postupem a makry.

### AI trenér
- Ptáš se česky („Co mám dnes cvičit?“, „Jak rozložit tréninky do konce týdne?“). Trenér zná tvůj
  plán, dnešní den, týden i zotavení svalů. Odpověď může nabídnout akci, třeba „Začít trénink“
  nebo „Otevřít program“.
- Bez internetu nebo bez AI odpoví místní kouč z dat v aplikaci.

### Ostatní
- Záloha a obnova do JSON (obnova nic nezdvojí), export do CSV pro český Excel, import z Hevy.
- Připomínky tréninku na Androidu a iPhonu.
- Souhlas s podmínkami a potvrzení věku (18+ nebo souhlas zákonného zástupce). Mladším 18 let
  aplikace nenabízí kalorické cíle.

## Soukromí

- Tréninky, jídla a váha jsou jen v zařízení. Zálohu si děláš sám do souboru.
- AI funkce jdou přes vlastní proxy (`worker/`, Cloudflare Workers AI, model Mistral Small 3.1).
  Aplikace v sobě nemá žádný API klíč. Proxy nic neukládá kromě denních počítadel limitů.
- Fotka lednice se před odesláním zmenší na JPEG do 1024 px. Trenérovi jde jen souhrn tréninků,
  žádné jméno.
- Na každé zařízení platí denní limity AI. Celkový strop drží proxy v rámci Free plánu, takže
  nic nestojí peníze.

## Instalace

| Platforma | Jak |
|---|---|
| Web / PWA | Otevři adresu výše. Na iPhonu v Safari dej Sdílet → Přidat na plochu. |
| Android | Nainstaluj APK z `flutter build apk --release` (je potřeba povolit instalaci z neznámých zdrojů). |
| iPhone | Nepodepsaná IPA z GitHub Actions, podepíše se lokálně přes Sideloadly nebo AltStore. Návod: [docs/IOS_SIDELOAD.md](docs/IOS_SIDELOAD.md). |

Testovací scénáře pro testery: [docs/TESTERS.md](docs/TESTERS.md).

## Vývoj

Potřebuješ Flutter 3.47.2 (Dart 3.13). Pro proxy Node 20 a víc.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # jen po změně lib/data/database.dart
flutter analyze
flutter test
```

Build s AI:

```bash
flutter build web --release --dart-define=AI_URL=https://gymzapisnik-ai.gymzapisnik-ai.workers.dev
python scripts/stamp_web_build.py   # verze offline cache podle obsahu buildu
```

Bez `AI_URL` jsou AI tlačítka vypnutá a trenér odpovídá jen místně. Volitelně
`--dart-define=FEEDBACK_EMAIL=…` zapne v Nastavení řádek „Napsat zpětnou vazbu“. V repozitáři
žádná adresa není.

### AI proxy (`worker/`)

```bash
cd worker
npm install
npm test             # testy proxy a promptů
npm run mock         # skutečný kód proxy s falešným modelem na :8787, bez Cloudflare
```

Skutečná konfigurace `worker/wrangler.toml` obsahuje ID účtu, proto je v `.gitignore`. Vzor je
`worker/wrangler.example.toml`. Celý postup nasazení je v [worker/README.md](worker/README.md).
Webová PWA musí mít svůj HTTPS původ v `ALLOWED_ORIGINS`. Nativní aplikace Origin neposílá.

### Hostování webu

Statický `build/web` běží jako Cloudflare Worker s assety. Spouští se z prázdné složky, aby si
wrangler nepřebral `worker/wrangler.toml`:

```bash
npx --prefix worker wrangler deploy --name gymzapisnik-app --assets build/web --compatibility-date 2026-10-01
```

### E2E testy

Testy běží proti `build/web` servírovanému na `http://localhost:8099`. Spouští se s
`PLAYWRIGHT_CORE=<cesta k playwright-core>`.

- `node tool/e2e_consent.cjs`: uvítání, plán, souhlas, reload a offline reload ze service workeru.
- `node tool/e2e_workout.cjs <prázdná složka profilu>`: zápis, pauza, reload, souhrn, historie,
  Pokrok, program, Nastavení, záloha, obnova a import z Hevy.
- `node tool/e2e_pwa.cjs <stejná složka>`: aktualizace service workeru a offline restart.
- `node tool/e2e_fridge.cjs <složka>`: AI lednička proti `npm run mock`.
- `node tool/review_mobile.cjs`: rychlý průchod v izolovaném mobilním prohlížeči.

Past: headless Chrome 156 v persistentním profilu service worker nezaregistruje. Testy, které
service worker potřebují, proto běží v dočasném kontextu.

## Struktura

```
lib/
  coach/     plán, progrese, mise, streak, místní trenér, startovní váhy (čistý Dart)
  domain/    modely, statistiky, historie, rekordy (bez Flutteru)
  data/      databáze Drift, úložiště, webová perzistence, Open Food Facts
  ai/        klient AI proxy
  state/     stav aplikace pro obrazovky
  notify/    připomínky
  premium/   příprava na Pro (dnes je všechno odemčené)
  ui/        obrazovky: home, workout, summary, progress, nutrition, coach, onboarding…
worker/      AI proxy (Cloudflare Worker, TypeScript)
web/         PWA: offline cache (service_worker.js), zámek jednoho okna
scripts/     kontrola iOS buildu, razítko webové cache
tool/        E2E skripty (Playwright)
test/        Flutter testy
```

## Stav

Beta. Na Androidu, webu a v testech je hotový celý tok: plán, trénink, souhrn, pokrok, strava
a AI trenér. Před rozesláním testerům zbývá ověřit aplikaci na fyzickém iPhonu a Androidu
a sebrat první zpětnou vazbu.

Aplikace nenahrazuje trenéra ani lékaře.
