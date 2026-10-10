# iPhone beta.3 přes iLoader

Cílem je release IPA pro fyzický iPhone, podepsaná až místně v iLoaderu.
Sestavení potřebuje macOS/Xcode; Windows ani iLoader aplikaci nezkompilují.
Do GitHubu se neposílá Apple účet, certifikát ani provisioning profile.

## Stav 2026-10-10

Znovu prošlo 184 Flutter testů, 28 testů proxy, TypeScript a Flutter analýza.
Statický test reprodukoval chybějící kamerové a galerijní oprávnění; Info.plist
je opravený. Šest Python testů včetně release gates prošlo. GitHub workflow
rozpoznal jako aktivní (ID 380589872); spuštění Xcode ani IPA zatím neověřené.

Tomáš schválil výhradně použití bez placeného čerpání. Job se proto dosud
nespustil: token nemá billing scope a browser není přihlášený. Před spuštěním
je potřeba ověřit účetní zákaz placené spotřeby Actions (nulový rozpočet se
zapnutým Stop usage when budget limit is reached, nebo jinou prokazatelnou
blokaci plateb). Samotný časový limit není cenový limit. Viditelnost repa se
nemění a Apple údaje zůstávají lokální. Žádný hotový IPA soubor zatím není.

Workflow `iPhone beta for local sideloading` se spouští pouze ručně. Používá
standardní macOS 15 runner, Flutter 3.47.2, zamčené závislosti, testy a analýzu.
Po skutečné kompilaci kontroluje arm64 device bundle, Flutter frameworky,
oprávnění, identitu a verzi. Teprve pak balí IPA, SHA256 a zdrojový commit.
Artifact je uchovaný jeden den; repozitář je soukromý, minuty a úložiště
mohou být účtované po vyčerpání kvóty. Časový limit je 40 minut na běh.

Identita zůstává cz.radys.gymzapisnik / Gym zápisník. UI verze je beta.3+12;
iOS bundle má číselnou verzi 1.0.0 a build 12. AI používá stávající HTTPS proxy.
Na iOS tato beta nepodporuje tréninkové připomínky ani platby.

## Po úspěšném sestavení

1. Zkontroluj SHA256 a importuj `gymzapisnik-1.0.0-beta.3-unsigned.ipa` do
   iLoaderu. Podepsání a Apple přihlášení proveď lokálně podle jeho návodu.
2. Zachovej identitu při dalších aktualizacích. Data Safari/PWA se do native
   aplikace nepřenesou automaticky: nejdřív exportuj JSON, potom ho obnov v app.
   Původní PWA ani její data kvůli tomu nemaž.
3. Ověř celý trénink podle TESTERS.md, restart, opravu potvrzené série,
   souhrn/historii a opakovanou obnovu bez duplicit. Pak skutečnou kameru,
   galerii, odmítnutí oprávnění, zápis jídla a restart offline.

Úspěšný Xcode build ani podpis přes iLoader nejsou důkazem fyzického běhu.
Pokud běh selže nebo gate odhalí nesprávný bundle, IPA se nepředává.

Zdroje: [Flutter iOS build](https://docs.flutter.dev/deployment/ios),
[image_picker oprávnění](https://pub.dev/packages/image_picker),
[iLoader](https://github.com/nab138/iloader),
[GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).
