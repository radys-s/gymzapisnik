# Nezávislé review C/D1 — 2026-10-09

Pokračování existující bety po Claudeově předávce, bez nové produktové fáze.
Výchozí HEAD d2fc540; výsledek 1.0.0-beta.3+12. Zachované osobní tréninky,
název, kontakt, podpisové klíče a opravy persistence z beta.2.

## Reprodukované nálezy a opravy

- Chybějící jednotka se nesmí odhadnout jako kus. Takový převod u chleba
  výrazně zkreslí makra. Neznámá jednotka zůstává neznámá a editor vyžaduje
  g/ml/ks. Kusové váhy jsou jen orientační. Prompt nyní žádá explicitní jednotky.
- Malý JPEG procházel bez dekódování: šlo přijmout neplatnou hlavičku nebo
  velké rozměry. Fotografie se vždy ověří, orientuje, zmenší a znovu kóduje.
- Chybná AI odpověď bez items působila jako prázdná lednička. Nyní je to
  chyba; platný prázdný seznam je nadále dovolený.
- Selhání uložení ID instalace bylo označené jako offline. Nyní má vlastní
  chybu ukládání a neposílá HTTP požadavek.
- Opakování modelu zapisovalo globální KV čítač podruhé hned po rezervaci.
  Test s limitem jednoho zápisu na klíč odhalil selhání. Obě možná volání
  se rezervují předem jedním zápisem; nevyužitá rezervace se nevrací.
  KV zůstává přibližné počítadlo s možnými souběhy, ne atomický finanční limit.
  Konflikt KV 429 vrací dočasné vytížení 503, denní kvóta vlastní 429.
- Streamované JSON tělo se nyní omezuje podle skutečných UTF-8 bajtů,
  i bez Content-Length. Návrh musí dodržet zvolený maximální čas bez tolerance.
- UI blokuje dvojí spuštění i během souhlasu a výběru fotky, zachytává chyby
  ukládání a seznam zobrazí jako uložený až po úspěšném zápisu.
- Seznam mohl ukazovat 61 položek, ale savePantry tiše uložil jen prvních
  60. Regresní test reprodukoval ztrátu; ukládání nyní zachová celý seznam.
- Testy dnešní mise mají pevné datum. Ochrana série proti dvojímu klepnutí
  používá zrušitelný Timer; regresní test ovládá čas místo reálného Stopwatch.
- Soukromí už netvrdí, že aplikace neposílá nic na server: odděluje lokální
  deník od dobrovolného dotazu na AI a Open Food Facts.

## Důkazy a hranice

184 Flutter testů prošlo, analyzer bez nálezů. Po poslední změně textu navíc
2 release testy. Proxy: 28 testů, TypeScript a deploy dry-run úspěšné.
Web runtime: 3 Node testy; cache stamp: 2 Python testy.
Logy jsou lokálně v build/review-d1-* (nejsou součástí commitu).

Chrome nad sestaveným webem a skutečnou lokální proxy s mock modelem ověřil
fotku, upozornění, seznam, návrhy, jeden zápis do deníku, reload a offline
zachování deníku i seznamu. Nejde o ověření kvality rozpoznání potravin.

Nasazená původní proxy odpověděla na 3 syntetické návrhy jídel 3/3 HTTP 200.
Její preflight pro origin localhost:8080 prošel, localhost:8099 byl HTTP 403:
chybný origin reprodukovatelně způsobuje neúspěšné připojení z webu.
To neprokazuje příčinu původního jednotlivého selhání na jiné adrese.
Nová konfigurace zahrnuje oba lokální porty. Změny proxy a promptu nejsou
živě ověřené, dokud uživatel neschválí a neproběhne jejich nasazení.

Chrome tréninkový E2E dále prošel zápis, minulý výkon, souhrn, historii,
opakovanou obnovu JSON a idempotentní Hevy import. Samostatný PWA E2E ověřil
skutečnou změnu service workeru s potvrzenou opravenou sérií 82,5 kg × 6,
offline reload, úplný restart Chrome offline a souhrn/historii s objemem
495 kg. Profily jsou izolované testovací, ne osobní.

Release balení je v dist/gymzapisnik-1.0.0-beta.3.apk a
dist/gymzapisnik-1.0.0-beta.3-web.zip; kontrolní součty v odpovídajícím
SHA256 souboru. APK používá dosavadní podpis a balíček cz.radys.gymzapisnik.
Webový archiv potřebuje schválený HTTPS hosting a jeho přesný origin přidaný
do konfigurace AI proxy. Lokální sestavení není veřejná distribuce.

Fyzický Android/iPhone, kamera, skutečná lednička, mobilní úložiště, doručení
připomínek a Safari PWA zatím neověřené. ADB nemá připojený telefon.
PWA se bez souhlasu nepublikuje. Placené API, cloudová synchronizace ani
platby se nepřidávají. Pro neomezuje bezplatnou betu.
