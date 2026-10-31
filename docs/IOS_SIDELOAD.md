# iPhone: IPA k sideloadu

Na iPhonu běží Gym zápisník jako nativní aplikace bez App Storu. GitHub Actions na macOS
sestaví **nepodepsanou** IPA. Podepíše se až u tebe na počítači tvým Apple ID. Do GitHubu
se neposílá žádný Apple účet, certifikát ani provisioning profile.

## 1. Sestavení

Workflow **iPhone beta for local sideloading** (`.github/workflows/ios-sideload.yml`) se
spouští ručně: Actions → workflow → Run workflow. Z příkazové řádky:

```bash
gh workflow run ios-sideload.yml --ref main
```

Workflow udělá tohle:

1. Nainstaluje Flutter 3.47.2 a zamčené závislosti.
2. Pustí Python testy, `flutter analyze` a `flutter test`.
3. Zkompiluje release pro fyzický iPhone (arm64) s AI proxy (`AI_URL`).
4. Zkontroluje bundle: identitu `cz.radys.gymzapisnik`, verzi, platformu iPhoneOS, arm64
   binárky a texty oprávnění pro kameru a fotky.
5. Zabalí `gymzapisnik-<verze>-unsigned.ipa`, `SHA256.txt`, `ios-build.json` a
   `SOURCE_COMMIT.txt`.

Artifact `gymzapisnik-ios-sideload` vydrží jeden den. Stažení:

```bash
gh run download <run-id> -n gymzapisnik-ios-sideload -D dist/ios
```

## 2. Podpis a instalace (Windows)

Funguje to se zdarma Apple ID, jen podpis platí 7 dní a potom se musí obnovit.

**Sideloadly** (nejjednodušší):

1. Nainstaluj iTunes a iCloud přímo od Applu (ne z Microsoft Store) a Sideloadly.
2. Připoj iPhone kabelem a potvrď na něm „Důvěřovat tomuto počítači“.
3. Přetáhni IPA do Sideloadly, zadej své Apple ID a dej Start.
4. Na iPhonu otevři Nastavení → Obecné → Správa VPN a zařízení, vyber svůj Apple ID
   profil a zvol Důvěřovat.
5. Od iOS 16 zapni Nastavení → Soukromí a zabezpečení → Režim pro vývojáře. Telefon se
   restartuje.

Alternativy jsou **AltStore** (umí obnovovat podpis přes Wi-Fi) a **iLoader**.

Před instalací zkontroluj SHA256 proti `SHA256.txt`:

```powershell
Get-FileHash .\gymzapisnik-*-unsigned.ipa -Algorithm SHA256
```

## 3. Aktualizace a data

- Při podpisu nové verze zachovej stejné Apple ID a stejnou identitu. Aplikace se pak
  přepíše a data v ní zůstanou.
- Data z webové PWA se do nativní aplikace nepřenesou sama. V PWA dej Nastavení → Záloha,
  v aplikaci pak Obnova ze souboru.
- Když podpis vyprší, aplikace se nespustí, ale data zůstávají. Stačí ji znovu podepsat.

## 4. Co ověřit na telefonu

1. Úvod: kvíz, odhalení plánu, připomínka (povol oznámení), souhlas.
2. Celý trénink: startovní váhy, potvrzení série, pauza se zamčeným telefonem (oznámení
   na konci), dokončení a souhrn.
3. Trenér: „Co mám dnes cvičit?“ musí vyjmenovat dnešní cviky. Pak jedna vlastní otázka.
4. Strava: zápis jídla, čárový kód a AI lednička s fotkou z kamery i z galerie.
5. Restart telefonu, letadlový režim (trénink jde zapsat offline), záloha a obnova.

Úspěšný build a podpis ještě nedokazují, že aplikace na telefonu běží. To ukáže až
průchod výše.

Zdroje: [Flutter iOS build](https://docs.flutter.dev/deployment/ios),
[Sideloadly](https://sideloadly.io), [AltStore](https://altstore.io),
[iLoader](https://github.com/nab138/iloader).
