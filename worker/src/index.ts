// Gym zápisník AI proxy: fridge photo -> items, items -> meal suggestions.
// Runs Workers AI; the app holds no secret. Images and texts are never logged
// or stored, only daily counters per install ID.

import { FRIDGE_SYSTEM, mealsSystem, mealsUser } from "./prompts";
import { countRetry, reserve, type Feature, type QuotaStore } from "./quota";
import {
  MAX_IMAGE_B64,
  fridgeSchema,
  mealsSchema,
  parseFridgeRequest,
  parseMealsRequest,
  validateFridge,
  validateMeals,
} from "./schema";

export interface AiBinding {
  run(model: string, input: Record<string, unknown>): Promise<unknown>;
}

export interface Env {
  AI: AiBinding;
  QUOTA: QuotaStore;
  MODEL?: string;
  ALLOWED_ORIGINS?: string;
  FRIDGE_PER_INSTALL?: string;
  MEALS_PER_INSTALL?: string;
  GLOBAL_DAILY_CAP?: string;
}

const DEFAULT_MODEL = "@cf/mistralai/mistral-small-3.1-24b-instruct";
const INSTALL_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_BODY = MAX_IMAGE_B64 + 4_096;
const MAX_MEALS_BODY = 16_384;

type ErrorCode =
  | "bad_request"
  | "forbidden"
  | "not_found"
  | "too_large"
  | "quota_install"
  | "quota_global"
  | "ai_failed";

function limitOf(v: string | undefined, fallback: number): number {
  const n = Number(v);
  return Number.isInteger(n) && n >= 0 ? n : fallback;
}

function allowedOrigin(env: Env, origin: string | null): boolean {
  if (origin === null) return true; // native app, curl
  return (env.ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean)
    .includes(origin);
}

function corsHeaders(origin: string | null): Record<string, string> {
  if (origin === null) return {};
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Install-Id",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function json(
  body: unknown,
  status: number,
  origin: string | null,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...corsHeaders(origin),
    },
  });
}

function fail(
  code: ErrorCode,
  message: string,
  status: number,
  origin: string | null,
): Response {
  return json({ error: { code, message } }, status, origin);
}

async function readJson(
  request: Request,
  max: number,
): Promise<unknown | "too_large" | "bad"> {
  const declared = Number(request.headers.get("Content-Length"));
  if (Number.isFinite(declared) && declared > max) return "too_large";
  const text = await request.text();
  if (text.length > max) return "too_large";
  try {
    return JSON.parse(text);
  } catch {
    return "bad";
  }
}

/**
 * Calls the model; on a throw or output that fails [validate] tries once more.
 * Returns null when both attempts fail.
 */
async function runValidated<T>(
  env: Env,
  input: Record<string, unknown>,
  validate: (raw: unknown) => T | null,
  now: Date,
): Promise<T | null> {
  const model = env.MODEL || DEFAULT_MODEL;
  for (let attempt = 0; attempt < 2; attempt++) {
    if (attempt > 0) await countRetry(env.QUOTA, now);
    try {
      const out = (await env.AI.run(model, input)) as { response?: unknown };
      const result = validate(out?.response);
      if (result !== null) return result;
    } catch {
      // Error details may contain user content; do not log them.
    }
  }
  return null;
}

async function handle(
  request: Request,
  env: Env,
  now: Date,
): Promise<Response> {
  const origin = request.headers.get("Origin");
  if (!allowedOrigin(env, origin)) {
    return fail("forbidden", "Přístup z tohoto webu není povolen.", 403, null);
  }
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }
  const path = new URL(request.url).pathname;
  const feature: Feature | null =
    path === "/v1/fridge" ? "fridge" : path === "/v1/meals" ? "meals" : null;
  if (feature === null) {
    return fail("not_found", "Neznámá adresa.", 404, origin);
  }
  if (request.method !== "POST") {
    return fail("bad_request", "Použij POST.", 405, origin);
  }
  const installId = request.headers.get("X-Install-Id") ?? "";
  if (!INSTALL_RE.test(installId)) {
    return fail("bad_request", "Chybí identifikátor aplikace.", 400, origin);
  }

  const body = await readJson(
    request,
    feature === "fridge" ? MAX_BODY : MAX_MEALS_BODY,
  );
  if (body === "too_large") {
    return fail("too_large", "Požadavek je moc velký.", 413, origin);
  }
  if (body === "bad") {
    return fail("bad_request", "Neplatný požadavek.", 400, origin);
  }
  const parsed =
    feature === "fridge" ? parseFridgeRequest(body) : parseMealsRequest(body);
  if (typeof parsed === "string") {
    return fail("bad_request", parsed, 400, origin);
  }

  const quota = await reserve(
    env.QUOTA,
    {
      fridge: limitOf(env.FRIDGE_PER_INSTALL, 8),
      meals: limitOf(env.MEALS_PER_INSTALL, 20),
      global: limitOf(env.GLOBAL_DAILY_CAP, 100),
    },
    installId,
    feature,
    now,
  );
  if (quota === "install") {
    return fail(
      "quota_install",
      feature === "fridge"
        ? "Dnešní limit fotek je vyčerpaný. Zkus to zítra, nebo uprav seznam ručně."
        : "Dnešní limit návrhů je vyčerpaný. Zkus to zítra.",
      429,
      origin,
    );
  }
  if (quota === "global") {
    return fail(
      "quota_global",
      "AI pro testery má dnes vyčerpanou kapacitu. Zkus to zítra.",
      429,
      origin,
    );
  }

  if ("image" in parsed) {
    const items = await runValidated(
      env,
      {
        messages: [
          { role: "system", content: FRIDGE_SYSTEM },
          {
            role: "user",
            content: [
              { type: "text", text: "Co je na fotce k jídlu?" },
              {
                type: "image_url",
                image_url: { url: `data:image/jpeg;base64,${parsed.image}` },
              },
            ],
          },
        ],
        guided_json: fridgeSchema,
        max_tokens: 800,
        temperature: 0.1,
      },
      validateFridge,
      now,
    );
    if (items === null) {
      return fail(
        "ai_failed",
        "AI fotku nezpracovala. Zkus jinou fotku, nebo zapiš potraviny ručně.",
        502,
        origin,
      );
    }
    return json({ items }, 200, origin);
  }

  const meals = await runValidated(
    env,
    {
      messages: [
        { role: "system", content: mealsSystem(parsed.context.adult) },
        { role: "user", content: mealsUser(parsed) },
      ],
      guided_json: mealsSchema,
      max_tokens: 1_400,
      temperature: 0.4,
    },
    (raw) => validateMeals(raw, parsed.context.maxMinutes),
    now,
  );
  if (meals === null) {
    return fail(
      "ai_failed",
      "AI teď návrh nevymyslela. Zkus to znovu, nebo uprav seznam.",
      502,
      origin,
    );
  }
  return json({ meals }, 200, origin);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      return await handle(request, env, new Date());
    } catch {
      const origin = request.headers.get("Origin");
      return fail(
        "ai_failed",
        "Služba teď nefunguje. Zkus to později.",
        500,
        allowedOrigin(env, origin) ? origin : null,
      );
    }
  },
};

export { handle };
