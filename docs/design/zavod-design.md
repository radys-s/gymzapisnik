# Vzhled „Závod“ (2026-10-28)

Výsledek hlasování testerů nad `life-dashboard-koncepty.html`:

| Pořadí | Koncept | Hlasy | Co z něj bereme |
|---|---|---|---|
| 1 | 03 Pit wall (F1) | 2 + návrh | základ: tmavá tabule, závodní červená, kurzíva, startovní světla, pořadí |
| 2 | 02 Tensor („Pull Ready“) | 1 | telemetrie: velké číslo jako vodoznak, štítek ŽIVĚ, zelená pro rekordy |

Řádek konceptů má 3 sloupce, takže „poslední v prvním řádku“ je opět 03. Proto F1 jako základ
a z Tensoru jen telemetrické prvky. Nový vzhled je výchozí, Aurora/Studio/Automaticky zůstávají v Nastavení.

## Tokeny (`lib/ui/design/tokens.dart`, `Look.pitwall`)

- Vždy tmavý (`ThemeMode.dark` v `app.dart`), barva motivu se nevybírá.
- Pozadí `#15151E`, karta `#1F1F2B`, vyvýšené `#2A2A38`, oddělovač `#2E2E3D`.
- Text bílý / `#A9A9BC` / `#6E6E84`.
- Akcent `#FF5545` (5,1 : 1 na kartě), na něm černý text; CTA závodní červená `#E10600` s bílým textem (5 : 1).
- Přechod `#E10600 → #FF5A1F → #FFB000`, pozitivní `#00E676`.
- Rohy karet asymetrické 4 / 12 (`cardRadius`), tlačítka 4.
- Nadpisy kurzíva w900 (`race()` v `theme.dart`).

## Komponenty

- **`_RaceHero`** (HeroCard v Závodu): tmavý přechod, 4px červený levý pruh, obrysové číslo tréninku
  jako vodoznak (vjede zprava 900 ms).
- **`StartLights`**: pět světel před tlačítkem Začít, rozsvítí se postupně jednou za otevření.
- **`LiveTag`**: „ŽIVĚ“ s blikající zelenou tečkou u rozběhnutého tréninku (3 bliknutí, ne smyčka).
- **Panel**: červený levý pruh.
- **`_RecordsBoard`** na Dnes: „Pořadí rekordů“ P1–P3 s barevným pruhem týmu, ťuk otevře cvik.

## Přístupnost

- Reduced motion: světla rovnou svítí, vodoznak stojí, tečka nebliká.
- Dekorace (`StartLights`, vodoznak) je mimo čtečku.
- Popisky nejsou uppercase v datech, testy `find.text` platí.
- Kontrast hlídá `contrast_test` pro všechny vzhledy.
