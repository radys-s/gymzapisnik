# iPhone beta.3 přes iLoader

Cílem je release IPA pro fyzický iPhone, podepsaná až místně v iLoaderu.
Sestavení potřebuje macOS/Xcode; Windows ani iLoader aplikaci nezkompilují.
Do GitHubu se neposílá Apple účet, certifikát ani provisioning profile.

## Stav 2026-10-10

Znovu prošlo 184 Flutter testů, 28 testů proxy, TypeScript a Flutter analýza.
Statický test reprodukoval chybějící kamerové a galerijní oprávnění; Info.plist
je opravený. Šest Python testů včetně release gates prošlo. GitHub workflow
rozpoznal jako aktivní (ID 380589872).

Tomáš schválil výhradně použití bez placeného čerpání. Před spuštěním byl
v přihlášeném GitHub účtu radys-s ověřen rozpočet pro produkt Actions:
0 USD, Stop usage Yes. Nastavení se neměnilo. Časový limit není cenový limit;
před dalším během ověř stejnou blokaci placené spotřeby.

[Běh 38061742003](https://github.com/radys-s/gymzapisnik/actions/runs/38061742003)
úspěšně dokončil Xcode 16.4 device release, 184 Flutter testů, šest Python
testů, analýzu i balení. Zdroj: 61c26fc4a5dbfac097dfd3393419718aa48f460c.
Stažená IPA prošla kontrolou ZIP integrity, identity, platformy iPhoneOS,
ARM64 aplikace a frameworků, oprávnění, zdrojového commitu a SHA256.

Soubor: `dist/ios/gymzapisnik-1.0.0-beta.3-unsigned.ipa` (9 372 407 bajtů).
SHA256: `1bd3524a981c0b6ab7d5e4f0dfa3810505f484dfaddbbbd4c9f7aab3baaf078e`.
Metadata a kontrolní součet jsou vedle IPA. Soubor je nepodepsaný a potřebuje
místní podpis v iLoaderu. Instalace, spuštění, kamera a úložiště na fyzickém
iPhonu zatím nejsou ověřené. Tato beta má smysl pro nový test; nejde o
potvrzení připravenosti pro veřejnou distribuci.

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
