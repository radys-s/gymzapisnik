# Gym zápisník – návod pro testery

Dík, že to zkoušíš. Tréninky, deník a seznam potravin jsou uložené v zařízení,
bez účtu a cloudové synchronizace. AI po potvrzení upozornění odesílá fotku
nebo seznam do Cloudflare Workers AI; hledání čárového kódu používá Open Food Facts.
Pravidelně si **ulož zálohu** (Nastavení → Uložit zálohu do souboru).

## Co je nového v beta.5

**Rekord hned v tréninku**: po potvrzení série, která překoná tvůj rekord, uvidíš pohár u série.
V nabídce cviku (⋯) najdeš **Kotouče na činku** a **Přidat rozcvičku**. **Odznaky** (Cvičení → Odznaky)
sbíráš za tréninky, pravidelnost, rekordy a objem; nové ukáže souhrn tréninku. Souhrn ukazuje,
kolikátý trénink to byl a kolik jich máš tento týden; ikonou **Sdílet** pošleš kartu tréninku jako obrázek.
**Regenerace svalů** na stránce Cvičení ukáže odpočaté partie a umí z nich sestavit trénink.
**Statistiky** (Cvičení → Statistiky) mají kalendář tréninků, týdenní grafy a srovnání s minulým měsícem.
Napiš, jestli tě odznaky a regenerace motivují, nebo jen překáží.

## Co bylo nového v beta.4

Nový vzhled a dvě záložky: **Cvičení** a **Strava**. Historie („Vše“), cviky a rekordy,
program a tělesná váha jsou na stránce Cvičení; Nastavení otevře ozubené kolo vpravo
nahoře na obou záložkách. Při prvním spuštění projdeš krátké uvítání a vybereš vzhled (Automaticky, Aurora, Studio) a barvu; obojí změníš v Nastavení → Vzhled a barva.
Program si můžeš sestavit sám (Cvičení → Program) včetně počtu tréninků za týden.
Nativní aplikace (Android i iPhone) umí připomínku tréninku a upozornění na konec pauzy.
**Sestavit trénink** (Cvičení): vyber partie a počet cviků, aplikace navrhne trénink; každý cvik
můžeš vyměnit. **Nahradit** cvik v tréninku ukáže alternativy podle hlavy svalu (např. boční delt).
**Rady pro růst svalů** (Cvičení) shrnou základy a ukážou tvoje série za posledních 7 dní.
Při spuštění uvidíš krátkou radu nebo motivační větu; klepnutím ji přeskočíš.

## Android (APK)

1. Stáhni soubor `gymzapisnik.apk`, který ti poslal Tomáš.
2. Otevři ho. Telefon se zeptá, jestli povolit instalaci z tohoto zdroje: povol.
3. Nainstaluj a otevři. Při zapnutí připomínek (Nastavení → Připomínky) povol oznámení.

Aktualizace: nejdřív ulož zálohu a nainstaluj novější APK přes starou. Zachování
dat vyžaduje stejný balíček a podpis. Neodinstalovávej původní aplikaci.
Ověření aktualizace na konkrétním telefonu je součást testu.

## iPhone (nativní IPA přes iLoader)

Ověřené sestavení beta.3 a postup místního podpisu jsou v
[IOS_SIDELOAD.md](IOS_SIDELOAD.md). Nejdřív zálohuj data; Safari/PWA a nativní
aplikace mají oddělené úložiště. Do aplikace přenes dokončené tréninky pomocí
JSON zálohy, původní data nemaž. Fyzické ověření iPhonu zatím čeká na testera.
Po instalaci proveď celý trénink níže, restart v režimu letadlo a zkus kameru
i galerii včetně odmítnutí oprávnění. Zapni připomínky (Nastavení → Připomínky),
povol oznámení a ověř upozornění na konec pauzy se zamčeným telefonem. Aplikace
podepsaná zdarma po 7 dnech přestane běžet a s ní i oznámení; obnov ji v iLoaderu.

## iPhone (webová aplikace)

1. V **Safari** otevři adresu aplikace, kterou ti poslal Tomáš.
2. Klepni na tlačítko Sdílet (čtvereček se šipkou) → **Přidat na plochu** → Přidat.
3. Spouštěj ji z ikony na ploše. První spuštění potřebuje internet a dokončené
   stažení offline cache. Pak ověř spuštění v režimu letadlo podle scénáře níže.
   Test v Chrome nenahrazuje fyzické ověření v Safari na iPhonu.

Přidej aplikaci na plochu **před zapisováním tréninků**. Safari a aplikace z plochy
nesdílejí databázi IndexedDB. Pokud už máš tréninky v Safari, nejdřív tam ulož JSON
zálohu a potom ji obnov v aplikaci z plochy. Toto omezení popisuje
[WebKit](https://webkit.org/blog/14787/webkit-features-in-safari-17-2/#web-apps).

Webová aplikace na iPhonu nemá připomínky ani upozornění na konec pauzy; denní úkol
uvidíš po otevření. Oznámení má jen nativní aplikace.
Místní úložiště není záloha: může zmizet například při vyčištění dat nebo nedostatku
místa ([pravidla WebKit](https://webkit.org/blog/14403/updates-to-storage-policy/)).
Proto ukládej JSON do souboru. Aplikace připomíná zálohu po 10 nových trénincích, ne podle
uplynulých týdnů. JSON obsahuje dokončené tréninky, vlastní cviky, váhu, výživový deník,
seznam potravin a nastavení;
rozepsaný trénink ani souhlas s podmínkami v záloze nejsou.

Při nabídce nové verze klepni na **Načíst**: aplikace počká na uložení před restartem.
Při chybě ukládání ji nezavírej a zkus uložení znovu. Používej stále stejnou adresu —
jiná doména má jiné místní úložiště.

## Jeden celý trénink na telefonu (beta.4)

Nejdřív zálohuj svoje data. Použij testovací váhy, nemusíš skutečně cvičit.

1. Na Cvičení klepni na Začít trénink, přidej Bench press (označ ho a potvrď Přidat cvik). Potvrď rozcvičku 40 kg × 10 a pracovní
   sérii 80 kg × 8 rychlým dvojím klepnutím. Musí zůstat potvrzená. Zkus pauzu,
   +15 a Přeskočit.
2. Oprav potvrzenou pracovní sérii na 82,5 kg × 6. Vrať se na Cvičení, zavři a znovu
   otevři aplikaci. Pokračuj: obě série i oprava musí zůstat.
3. Přidej pracovní sérii 80 kg × 7, potvrď a hned klepni dvakrát na Dokončit.
   Musí vzniknout jediný souhrn: 2 pracovní série, objem 1 055 kg (495 + 560).
   Rozcvička se do objemu nepočítá.
4. V Historii (Cvičení → Vše) ověř stejné hodnoty a zopakuj trénink. Minulý výkon musí odpovídat
   historii; předvyplněné série musí být nepotvrzené. Potvrď pracovní sérii jedním
   klepnutím a dokonči. Dialog upozorní na zbývající nepotvrzené série.
5. Ulož JSON zálohu a obnov ji dvakrát: historie se nesmí zdvojit. Cizí či poškozený
   JSON musí zobrazit chybu bez změny dat. Hevy CSV importuj dvakrát: druhý import
   musí hlásit „Nic nového“.
6. Android: připomínku ověř v nejbližší plánovaný den se zhasnutým displejem,
   také po restartu telefonu. Zkus odmítnutí oprávnění. Nepřesné alarmy mohou přijít
   později; automatické testy plánu nepotvrzují fyzické doručení.
7. iPhone PWA: po prvním online spuštění zapni režim letadlo, ukonči a znovu otevři
   aplikaci. Ověř historii i rozepsaný trénink. Při dostupné aktualizaci ověř data
   po klepnutí na Načíst; stažení nové verze vyžaduje internet.

„Smazat všechna data“ netestuj na vlastních trénincích. Obnovu na čisté instalaci
zkoušej jen v odděleném testovacím zařízení/profilu.

## Co zkoušet

- Zapsat trénink (cvik → série → ✓) a podívat se na souhrn s porovnáním s minulým.
- Vybrat program (Cvičení → Program), nebo si sestavit vlastní, a sledovat denní úkol a týden.
- Upravit hotový trénink (Cvičení → Vše → trénink → ⋯ → Upravit): smazání série jde vrátit.
- Import z Hevy (Hevy → Profil → Nastavení → Export dat; pak Nastavení → Import z Hevy).
- Zapsat tělesnou váhu (Cvičení → Tělesná váha).
- Strava (záložka dole): přidat jídlo ručně, podle čárového kódu (např. 3017620422003 = Nutella, potřebuje
  internet; úpravu před uložením zkus) a podívat se na včerejší den. Bez internetu musí jít jídlo zapsat ručně
  a uložený deník zůstat vidět. Mobilní chování zatím nikdo neověřil.
- Strava → „Co mám v ledničce“ (jen ve verzi se zapnutou AI): vyfoť ledničku, oprav seznam, zvol čas a nech
  si navrhnout jídlo. Napiš, co AI poznala špatně a jestli návrhy dávaly smysl. Limit je 8 fotek a 20 návrhů
  za UTC den na instalaci; jde o přibližné limity, ne ověření identity telefonu.
  Celková kapacita je omezená: strop 100 rezervovaných volání = nejvýš přibližně
  50 požadavků pro všechny testery (každý rezervuje i případné opakování).
  Změna konfigurace platí až po nasazení aktualizované proxy.
  Při neznámé jednotce zvol g/ml/ks; množství z fotografie je pouze odhad.
  Zkus odmítnout AI upozornění, výběr fotky zrušit a jídlo zapsat ručně.
  Zapsaný návrh oprav, zavři aplikaci a ověř deník i seznam po návratu offline.
  Bez internetu se nové návrhy nevytvářejí. Dočasné vytížení znamená zkusit za
  chvíli; vyčerpaná denní kvóta znamená počkat do dalšího UTC dne.

## Zpětná vazba

Nastavení → Napsat zpětnou vazbu. Nejvíc pomůže: co tě zdrželo, co chybělo, co ses
bál zapsat. Nahlásit chybu: popiš, co jsi dělal, a přilož verzi z Nastavení → O aplikaci.
