# Nápady od Clauda

Sem Claude zapisuje nápady na další funkce. V aplikaci se nezobrazují. Tomáš u každého
rozhodne a změní stav; do aplikace jde jen to, co je **Schváleno**.

**Stavy:** `Návrh` (čeká na Tomáše) · `Schváleno` (Claude ho naplánuje do dalšího updatu) ·
`Zamítnuto` (zůstává tu, ať se znovu nenavrhuje) · `Hotovo` (verze, ve které vyšel).

**Jak rozhodnout:** stačí napsat do chatu třeba „schvaluju 3 a 7, 12 zamítám". Claude upraví stav.

U každého nápadu: proč by pomohl, odhad práce (S = do jednoho večera, M = jeden update,
L = několik updatů nebo server) a riziko.

## Ke schválení

### Trénink

1. **Superset jedním klepnutím** · M · `Návrh`
   Dva cviky se střídají bez pauzy, časovač běží až po druhém. Šetří čas v posilovně a Hevy to umí.
   Riziko: složitější karta tréninku, musí zůstat čitelná na 320 px.

2. **Drop set a série do selhání** · S · `Schváleno` (beta.8)
   Další typ série vedle Pracovní a Rozcvička. Rekordy a objem by ho počítaly zvlášť.

3. **Cviky na čas** · M · `Návrh`
   Plank, kardio a strečink v minutách místo kg × opakování. Potřebuje nový typ cviku a jiný řádek série.

4. **Přesun cviku tažením** · S · `Schváleno` (beta.8)
   Dnes se cvik posouvá přes menu. Tažení prstem je rychlejší.

5. **Návody k cvikům** · M · `Hotovo` (beta.7)
   Tři věty k technice a nejčastější chyby, vlastní text. Riziko: hodně psaní a kontrola správnosti.

6. **Kalkulačka 1RM** · S · `Schváleno` (beta.8)
   Z libovolné série odhad maxima a tabulka vah pro 3–12 opakování. Data už aplikace počítá.

### Pokrok

7. **Shrnutí roku** · M · `Návrh`
   Jedna sdílitelná karta: tréninky, tuny, rekordy, nejlepší měsíc. Dobré na konec prosince.

8. **Mapa těla** · M · `Hotovo` (beta.7)
   Postava, na které svítí unavené a odpočaté partie. Navazuje na regeneraci svalů.

9. **Trend tělesné váhy** · S · `Schváleno` (beta.8)
   Vyhlazená křivka (průměr za 7 dní) místo skákajících bodů.

10. **Porovnání dvou tréninků** · S · `Schváleno` (beta.8)
    Libovolné dva tréninky vedle sebe, série po sérii.

### Motivace

11. **Týdenní výzva** · S · `Návrh`
    Malý cíl navíc, třeba „o 1 opakování víc u benche". Bez trestu, když se nesplní.

12. **Plán na příští týden** · M · `Návrh`
    Na konci týdne návrh, co přidat podle partií s malým objemem.

13. **Sdílení odznaku** · S · `Schváleno` (beta.8)
    Odznak jako obrázek, stejně jako karta tréninku.

### Strava

14. **Nový vzhled Stravy** · M · `Hotovo` (beta.7)
    Stejně čistý jako Cvičení. Dnes je Strava vizuálně o krok pozadu.

15. **Oblíbená jídla** · S · `Schváleno` (beta.8)
    Běžné jídlo zapsat jedním klepnutím.

### Telefon a zařízení

16. **Widget na plochu** · M · `Návrh`
    Týdenní cíl a další trénink bez otevření aplikace. Android i iPhone zvlášť.

17. **Záloha do cloudu** · L · `Návrh`
    Data v bezpečí i při ztrátě telefonu. Potřebuje účet a server, zásadní hlavně pro iPhone.

18. **Hodinky** · L · `Návrh`
    Potvrzení série a pauza na zápěstí. Hodně práce na dvou platformách.

### S ostatními

19. **Přátelé a jejich tréninky** · L · `Návrh`
    Potřebuje server, moderaci a ochranu nezletilých uživatelů. Doporučuju až po cloudové záloze.

20. **Silové úrovně** · M · `Návrh`
    Srovnání síly podle váhy a pohlaví. Potřebuje ověřené tabulky a nesmí tlačit mladší uživatele.

## Schváleno

Do beta.8 (2026-10-27, Tomáš: „většinu, co se hodí a dá se udělat“): 2, 4, 6, 9, 10, 13, 15.

## Zamítnuto

Zatím nic.

## Hotovo

- beta.7: 5 (návody ke cvikům na obrazovce cviku), 8 (mapa těla v regeneraci), 14 (nový vzhled Stravy).
