# Gym zápisník AI (Cloudflare Worker)

Proxy for the fridge coach. The app sends a fridge photo or an item list; the
Worker calls Cloudflare Workers AI and returns validated JSON. The app holds no
secret. Images and texts are not logged or stored; only daily counters per
install ID live in KV for two days.

Model: `@cf/mistralai/mistral-small-3.1-24b-instruct` (vision, Apache 2.0).
Swap via the `MODEL` variable (e.g. `@cf/google/gemma-3-12b-it`).

## API

All requests: `POST`, JSON body, header `X-Install-Id: <uuid v4>` (random ID
the app generates once). Errors: `{"error": {"code", "message"}}` with a Czech
message the app can show as is.

- `POST /v1/fridge` `{"image": "<base64 JPEG, max ~1 MB>"}` →
  `{"items": [{"name", "amount", "unit": "g"|"ml"|"ks"|null, "confidence"}]}`
- `POST /v1/meals`
  `{"items": [{"name", "amount", "unit"}], "context": {"trainingToday", "eatenToday": {"kcal", "protein"}, "proteinLeft", "maxMinutes", "adult"}}` →
  `{"meals": [{"title", "minutes", "ingredients": [...], "steps": [...], "estimate": {"kcal", "protein", "carbs", "fat"}}]}`

| Status | code | Meaning |
|---|---|---|
| 400 | `bad_request` | invalid body, missing install ID |
| 403 | `forbidden` | browser origin not in `ALLOWED_ORIGINS` |
| 413 | `too_large` | body over the limit |
| 429 | `quota_install` / `quota_global` | daily limit of this install / all testers |
| 502 | `ai_failed` | model failed twice or returned invalid JSON |

Limits (`wrangler.toml` `[vars]`): 8 photos and 20 meal requests per install
per UTC day; `GLOBAL_DAILY_CAP` model calls per day for everybody (retries
count), kept below the free 10,000 Neurons/day.

Free only: deploy on the Workers **Free** plan (no payment method). Workers AI
cannot bill a Free account; when the daily allocation runs out, Workers AI
fails with error 4006, the Worker marks the day as exhausted in KV and answers
`429 quota_global` without calling the model again until the next UTC day.

## Develop

```bash
npm install
npm test
npm run typecheck
```

Local mock without Cloudflare: `npm run mock` bundles the real Worker code
(`wrangler deploy --dry-run`) and serves it on `http://localhost:8787` with an
in-memory KV and a fake model (fixed fridge items and two meals, no network,
no cost). `PORT`, `ORIGINS` and `MOCK_AI=exhausted` (simulates a used-up free
plan) are optional environment variables. Build the app with
`--dart-define=AI_URL=http://localhost:8787` to use it.

## Deployed

`https://gymzapisnik-ai.gymzapisnik-ai.workers.dev` (Workers Free plan, KV
namespace `QUOTA` id in `wrangler.toml`). First live check 2026-10-08: fridge
photo ~4 s, meal ideas ~13 s, `guided_json` with nullable types accepted.
Redeploy after changes: `npx wrangler deploy`.

## Deploy from scratch (needs a Cloudflare account)

```bash
npx wrangler login
npx wrangler kv namespace create QUOTA
```

Paste the returned `id` into `wrangler.toml` (`[[kv_namespaces]]`), add the
PWA origin to `ALLOWED_ORIGINS`, then:

```bash
npx wrangler deploy
```

Put the printed `https://gymzapisnik-ai.<subdomain>.workers.dev` URL into the
app (`lib/ai/ai_config.dart`).
