# Progress log

## Časová osa

| Datum čas | Okno/branch | Krok |
|---|---|---|
| 2026-10-27 | bidnej / bidnej/black-october | Bezpečnostní update závislostí po „Black October“ |

## 2026-10-27 — Bezpečnostní update závislostí (Black October)

**Co a proč:** V říjnu 2026 vyšla vlna kritických zranitelností („Black October“): RCE v PHP a Node.js,
otrávený LiteLLM 1.107.0 na PyPI, kompromitované mezilehlé CA eMudhra (řeší certifi 2026.10.19+),
RCE v Next.js. Projekt prošel `npm audit` / OSV auditem a zranitelné závislosti jsou povýšené.

**Změny:** worker: vitest 3 → 5 (kritické RCE v tinypool, path traversal v @vitest/mocker), wrangler → 4.152, override undici 7.30.1 (miniflare má pevně 7.28.0 s DoS/SRI chybami), sharp.

**Ověření:** 36/36 testů, typecheck, `wrangler deploy --dry-run` i `wrangler dev` OK, npm audit 0. Branch vychází z `cviceni`.

**Co zůstává:** lokální Node 24.18.0 a PHP 8.5.8 na PC jsou zranitelné — aktualizovat na Node 24.22.1+ a PHP 8.5.12+.
