# Progress log

## Časová osa

| Datum čas | Okno/branch | Krok |
|---|---|---|
| 2026-10-27 | bidnej / bidnej/black-october | Bezpečnostní update závislostí po „Black October“ |
| 2026-10-27 | bidnej / bidnej/beta8 | Audit beta.7 + nápady 6, 9, 4, 15 (1RM, trend váhy, řazení cviků, oblíbená jídla) |
| 2026-10-27 | bidnej / bidnej/beta8 | Nápady 13 a 10: sdílení odznaku, porovnání dvou tréninků |

## 2026-10-27 — Bezpečnostní update závislostí (Black October)

**Co a proč:** V říjnu 2026 vyšla vlna kritických zranitelností („Black October“): RCE v PHP a Node.js,
otrávený LiteLLM 1.107.0 na PyPI, kompromitované mezilehlé CA eMudhra (řeší certifi 2026.10.19+),
RCE v Next.js. Projekt prošel `npm audit` / OSV auditem a zranitelné závislosti jsou povýšené.

**Změny:** worker: vitest 3 → 5 (kritické RCE v tinypool, path traversal v @vitest/mocker), wrangler → 4.152, override undici 7.30.1 (miniflare má pevně 7.28.0 s DoS/SRI chybami), sharp.

**Ověření:** 36/36 testů, typecheck, `wrangler deploy --dry-run` i `wrangler dev` OK, npm audit 0. Branch vychází z `cviceni`.

**Co zůstává:** lokální Node 24.18.0 a PHP 8.5.8 na PC jsou zranitelné — aktualizovat na Node 24.22.1+ a PHP 8.5.12+.

## 2026-10-27 — beta.8, první dávka: audit a čtyři nápady (bidnej)

**Co a proč:** Z beta.7 nepřišla zpětná vazba z telefonu, tak jsem udělal vlastní audit jako tester
a vybral malé nápady, které běží jen lokálně (bez serveru). Branch `bidnej/beta8` z `cviceni`.

**Nové funkce:**
- **Kalkulačka 1RM** (nápad 6): na detailu cviku tabulka 3–12 opakování z nejlepší série.
  `weightForReps` je obrácený Epley (1RM / (1 + reps/30)), zaokrouhlený dolů na 2,5 kg —
  dolů proto, aby odhad nikdy nebyl těžší než realita. Příklad: 100 kg 1RM na 10 opak. = 100 / 1,333 = 75 kg.
- **Trend tělesné váhy** (nápad 9): klouzavý průměr za 7 dní. Jednotlivá vážení jsou slabé tečky,
  průměr je čára — denní výkyvy (voda, jídlo) přestanou přehlušovat skutečný trend.
- **Řazení cviků tažením** (nápad 4): v menu cviku „Seřadit cviky“ → list s úchyty.
- **Oblíbená jídla** (nápad 15): podržení čipu „Rychle přidat“ nebo hvězdička v listu přidání.
  Max 12, ukládá se do profilu i do zálohy (rozbitá data záloha odmítne).

**Audit — opraveno:** trenér nepošle otázku dvakrát (synchronní zámek), historie chatu v paměti
max 30 zpráv, jídla 0:00–3:59 jsou „V noci“ místo „Snídaně“, z textů trenéra pryč znak „→“
(na webu se kreslil jako čtvereček). Lišta „Je dostupná nová verze“ na webu trvale zakrývala
spodní navigaci i tlačítko Hotovo v listu série — má teď „Později“ a odsazení od spodku displeje.

**E2E:** skripty `e2e_consent` a `e2e_pwa` byly zastaralé (uvítání má nově krok „Tvůj plán“, série
se zadává v listu s velkými čísly) — aktualizované, všechny tři E2E projdou.

**Výsledky:** `flutter analyze` čistý, 335 testů, web runtime 3/3, E2E workout + PWA + consent OK.

**Pro Tomáše (nesahal jsem, je to nasazení ven):** Worker `ALLOWED_ORIGINS` nemá produkční origin;
`GLOBAL_DAILY_CAP=100` při +2 za dotaz = asi 50 AI dotazů denně pro všechny testery dohromady.

**Další krok:** nápady 13 (sdílení odznaku), 10 (porovnání dvou tréninků), 2 (drop set / do selhání).

## 2026-10-27 — Sdílení odznaku a porovnání dvou tréninků (bidnej)

**Co a proč:**
- **Sdílení odznaku** (nápad 13): v detailu odemčeného odznaku tlačítko „Sdílet odznak“ → tmavá
  karta 360×450 s medailí → PNG přes systémové sdílení (na webu stažení). Sdílecí list karty tréninku
  jsem zobecnil na `ShareImageSheet`, takže obě karty jdou stejnou cestou (žádný duplikovaný kód).
- **Porovnání dvou tréninků** (nápad 10): v historii menu tréninku → „Porovnat s jiným“ → výběr
  (u každého počet společných cviků) → stránka Porovnání. Novější je vždy vlevo, ať se trénink
  otevře odkudkoli. Cviky se párují podle cviku (stejný cvik dvakrát podle pořadí), cviky jen
  z jednoho tréninku jsou na konci s popiskem „Jen <datum>“. Šipky trendu používají stejné
  `compareExercise` jako souhrn po tréninku. Dva tréninky z jednoho dne rozliší čas.

**Výsledky:** analyze čistý, 337 testů (nové: párování cviků, celý tok porovnání na 320 px,
otevření karty odznaku). Vizuálně ověřeno ve web buildu na 320 px (tmavý vzhled).

**Další krok:** nápad 2 — typ série drop set / do selhání.
