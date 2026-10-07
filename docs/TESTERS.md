# Gym zápisník – návod pro testery

Dík, že to zkoušíš. Aplikace je v betě: data jsou jen v tvém telefonu, žádný účet
ani cloud. Pravidelně si **ulož zálohu** (Nastavení → Uložit zálohu do souboru).

## Android (APK)

1. Stáhni soubor `gymzapisnik.apk`, který ti poslal Tomáš.
2. Otevři ho. Telefon se zeptá, jestli povolit instalaci z tohoto zdroje: povol.
3. Nainstaluj a otevři. Při zapnutí připomínek (Nastavení → Připomínky) povol oznámení.

Aktualizace: nejdřív ulož zálohu a nainstaluj novější APK přes starou. Zachování
dat vyžaduje stejný balíček a podpis. Neodinstalovávej původní aplikaci.
Ověření aktualizace na konkrétním telefonu je součást testu.

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

Tato beta na iPhonu nemá připomínky tréninku; denní úkol uvidíš po otevření.
Místní úložiště není záloha: může zmizet například při vyčištění dat nebo nedostatku
místa ([pravidla WebKit](https://webkit.org/blog/14403/updates-to-storage-policy/)).
Proto ukládej JSON do souboru. Aplikace připomíná zálohu po 10 nových trénincích, ne podle
uplynulých týdnů. JSON obsahuje dokončené tréninky, vlastní cviky, váhu, výživový deník a nastavení;
rozepsaný trénink ani souhlas s podmínkami v záloze nejsou.

Při nabídce nové verze klepni na **Načíst**: aplikace počká na uložení před restartem.
Při chybě ukládání ji nezavírej a zkus uložení znovu. Používej stále stejnou adresu —
jiná doména má jiné místní úložiště.

## Jeden celý trénink na telefonu (beta.2)

Nejdřív zálohuj svoje data. Použij testovací váhy, nemusíš skutečně cvičit.

1. Začni volný trénink, přidej Bench press. Potvrď rozcvičku 40 kg × 10 a pracovní
   sérii 80 kg × 8 rychlým dvojím klepnutím. Musí zůstat potvrzená. Zkus pauzu,
   +15 a Přeskočit.
2. Oprav potvrzenou pracovní sérii na 82,5 kg × 6. Vrať se na Domů, zavři a znovu
   otevři aplikaci. Pokračuj: obě série i oprava musí zůstat.
3. Přidej pracovní sérii 80 kg × 7, potvrď a hned klepni dvakrát na Dokončit.
   Musí vzniknout jediný souhrn: 2 pracovní série, objem 1 055 kg (495 + 560).
   Rozcvička se do objemu nepočítá.
4. V Historii ověř stejné hodnoty a zopakuj trénink. Minulý výkon musí odpovídat
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
- Vybrat split a sledovat denní úkol a streak na úvodní obrazovce.
- Import z Hevy (Hevy → Profil → Nastavení → Export dat; pak Nastavení → Import z Hevy).
- Zapsat tělesnou váhu.
- Výživa (karta na Domů): přidat jídlo ručně, podle čárového kódu (např. 3017620422003 = Nutella, potřebuje
  internet; úpravu před uložením zkus) a podívat se na včerejší den. Bez internetu musí jít jídlo zapsat ručně
  a uložený deník zůstat vidět. Mobilní chování zatím nikdo neověřil.
- Výživa → „Co mám v ledničce“ (jen ve verzi se zapnutou AI): vyfoť ledničku, oprav seznam, zvol čas a nech
  si navrhnout jídlo. Napiš, co AI poznala špatně a jestli návrhy dávaly smysl. Limit je 8 fotek a 20 návrhů
  za den na telefon; kapacita pro všechny testery dohromady je omezená.

## Zpětná vazba

Nastavení → Napsat zpětnou vazbu. Nejvíc pomůže: co tě zdrželo, co chybělo, co ses
bál zapsat. Nahlásit chybu: popiš, co jsi dělal, a přilož verzi z Nastavení → O aplikaci.
