// Gym zápisník AI proxy: fridge photo -> items, items -> meal suggestions,
// machine photo -> catalog exercises, trainer chat.
// Runs Workers AI; the app holds no secret. Images and texts are never logged
// or stored, only daily counters per install ID.

import {
  FRIDGE_SYSTEM,
  MACHINE_SYSTEM,
  coachSystem,
  mealsSystem,
  mealsUser,
} from "./prompts";
import {
  isExhausted,
  markExhausted,
  reserve,
  type Feature,
  type QuotaStore,
} from "./quota";
import {
  MAX_IMAGE_B64,
  fridgeSchema,
  machineSchema,
  mealsSchema,
  parseCoachRequest,
  parseFridgeRequest,
  parseMachineRequest,
  parseMealsRequest,
  validateCoach,
  validateFridge,
  validateMachine,
  validateMeals,
  type CoachRequest,
  type MachineRequest,
  type MealsRequest,
} from "./schema";

export interface AiBinding {
  run(model: string, input: Record<string, unknown>): Promise<unknown>;
}

export interface Env {
  AI: AiBinding;
  QUOTA: QuotaStore;
  MODEL?: string;
  /** Textový model jen pro trenéra (bez obrázků); jinak MODEL. */
  COACH_MODEL?: string;
  ALLOWED_ORIGINS?: string;
  FRIDGE_PER_INSTALL?: string;
  MEALS_PER_INSTALL?: string;
  MACHINE_PER_INSTALL?: string;
  COACH_PER_INSTALL?: string;
  GLOBAL_DAILY_CAP?: string;
}

const DEFAULT_MODEL = "@cf/mistralai/mistral-small-3.1-24b-instruct";
const INSTALL_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_BODY = MAX_IMAGE_B64 + 4_096;
const MAX_MEALS_BODY = 16_384;
const MAX_COACH_BODY = 24_576;

const ROUTES: Record<string, Feature> = {
  "/v1/fridge": "fridge",
  "/v1/meals": "meals",
  "/v1/machine": "machine",
  "/v1/coach": "coach",
};

const BODY_LIMIT: Record<Feature, number> = {
  fridge: MAX_BODY,
  meals: MAX_MEALS_BODY,
  // Photo plus the exercise list.
  machine: MAX_BODY + 16_384,
  coach: MAX_COACH_BODY,
};

const QUOTA_MESSAGE: Record<Feature, string> = {
  fridge: "Dnešní limit fotek je vyčerpaný. Zkus to zítra, nebo uprav seznam ručně.",
  meals: "Dnešní limit návrhů je vyčerpaný. Zkus to zítra.",
  machine: "Dnešní limit fotek strojů je vyčerpaný. Najdi cvik v seznamu.",
  coach: "Dnešní limit otázek na trenéra je vyčerpaný. Zkus to zítra.",
};

type ErrorCode =
  | "bad_request"
  | "forbidden"
  | "not_found"
  | "too_large"
  | "quota_install"
  | "quota_global"
  | "service_busy"
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

const exhausted = (origin: string | null) =>
  fail(
    "quota_global",
    "AI pro testery má dnes vyčerpanou kapacitu. Zkus to zítra.",
    429,
    origin,
  );

async function readJson(
  request: Request,
  max: number,
): Promise<unknown | "too_large" | "bad"> {
  const declared = Number(request.headers.get("Content-Length"));
  if (Number.isFinite(declared) && declared > max) return "too_large";
  const reader = request.body?.getReader();
  if (!reader) return "bad";
  const parts: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const chunk = await reader.read();
    if (chunk.done) break;
    size += chunk.value.byteLength;
    if (size > max) {
      await reader.cancel();
      return "too_large";
    }
    parts.push(chunk.value);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const part of parts) {
    bytes.set(part, offset);
    offset += part.byteLength;
  }
  const text = new TextDecoder().decode(bytes);
  try {
    return JSON.parse(text);
  } catch {
    return "bad";
  }
}

/**
 * Workers AI on the Free plan refuses calls once the daily 10,000 Neurons are
 * used (error 4006). The account is never charged; we just stop for the day.
 */
export function isAllocationExhausted(error: unknown): boolean {
  const text = error instanceof Error ? error.message : String(error);
  // Anchored to the start of the message: later parts of an error may echo
  // user content, which must not switch the AI off for everybody.
  return /^(?:[A-Za-z]*Error:\s*)?4006:[^\n]*daily free allocation/i.test(text);
}

/**
 * Calls the model; on a throw or output that fails [validate] tries once more.
 * Returns null when both attempts fail, "exhausted" when the free daily
 * allocation is used up (no retry then).
 */
async function runValidated<T>(
  env: Env,
  input: Record<string, unknown>,
  validate: (raw: unknown) => T | null,
  now: Date,
  modelOverride?: string,
): Promise<T | null | "exhausted"> {
  const model = modelOverride || env.MODEL || DEFAULT_MODEL;
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const out = (await env.AI.run(model, input)) as { response?: unknown };
      const result = validate(out?.response);
      if (result !== null) return result;
    } catch (error) {
      // Error details may contain user content; do not log them.
      if (isAllocationExhausted(error)) {
        try {
          await markExhausted(env.QUOTA, now);
        } catch {
          // The 429 still holds; the next call will just try the model again.
        }
        return "exhausted";
      }
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
  const feature: Feature | undefined = Object.hasOwn(ROUTES, path)
    ? ROUTES[path]
    : undefined;
  if (feature === undefined) {
    return fail("not_found", "Neznámá adresa.", 404, origin);
  }
  if (request.method !== "POST") {
    return fail("bad_request", "Použij POST.", 405, origin);
  }
  const installId = request.headers.get("X-Install-Id") ?? "";
  if (!INSTALL_RE.test(installId)) {
    return fail("bad_request", "Chybí identifikátor aplikace.", 400, origin);
  }

  const body = await readJson(request, BODY_LIMIT[feature]);
  if (body === "too_large") {
    return fail("too_large", "Požadavek je moc velký.", 413, origin);
  }
  if (body === "bad") {
    return fail("bad_request", "Neplatný požadavek.", 400, origin);
  }
  const parsed:
    | { image: string }
    | MealsRequest
    | MachineRequest
    | CoachRequest
    | string =
    feature === "fridge"
      ? parseFridgeRequest(body)
      : feature === "meals"
        ? parseMealsRequest(body)
        : feature === "machine"
          ? parseMachineRequest(body)
          : parseCoachRequest(body);
  if (typeof parsed === "string") {
    return fail("bad_request", parsed, 400, origin);
  }

  if (await isExhausted(env.QUOTA, now)) return exhausted(origin);

  const quota = await reserve(
    env.QUOTA,
    {
      fridge: limitOf(env.FRIDGE_PER_INSTALL, 8),
      meals: limitOf(env.MEALS_PER_INSTALL, 20),
      machine: limitOf(env.MACHINE_PER_INSTALL, 10),
      coach: limitOf(env.COACH_PER_INSTALL, 20),
      global: limitOf(env.GLOBAL_DAILY_CAP, 100),
    },
    installId,
    feature,
    now,
  );
  if (quota === "install") {
    return fail("quota_install", QUOTA_MESSAGE[feature], 429, origin);
  }
  if (quota === "global") return exhausted(origin);

  // MachineRequest also has `image`, so branch on the route, not the shape.
  if (feature === "machine") {
    const req = parsed as MachineRequest;
    const known = new Set(req.exercises.map((e) => e.id));
    const result = await runValidated(
      env,
      {
        messages: [
          { role: "system", content: MACHINE_SYSTEM },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: JSON.stringify({ cviky: req.exercises }),
              },
              {
                type: "image_url",
                image_url: { url: `data:image/jpeg;base64,${req.image}` },
              },
            ],
          },
        ],
        guided_json: machineSchema,
        max_tokens: 300,
        temperature: 0.1,
      },
      (raw) => validateMachine(raw, known),
      now,
    );
    if (result === "exhausted") return exhausted(origin);
    if (result === null) {
      return fail(
        "ai_failed",
        "AI stroj nepoznala. Zkus jinou fotku, nebo najdi cvik v seznamu.",
        502,
        origin,
      );
    }
    return json(result, 200, origin);
  }

  if ("messages" in parsed) {
    const reply = await runValidated(
      env,
      {
        messages: [
          { role: "system", content: coachSystem(parsed.adult) },
          {
            role: "system",
            content: `Data o tréninku uživatele (JSON): ${parsed.context}`,
          },
          ...parsed.messages,
        ],
        max_tokens: 450,
        temperature: 0.3,
        // Méně opakování stejných vět v jedné odpovědi.
        frequency_penalty: 0.4,
      },
      validateCoach,
      now,
      env.COACH_MODEL,
    );
    if (reply === "exhausted") return exhausted(origin);
    if (reply === null) {
      return fail(
        "ai_failed",
        "Trenér teď neodpověděl. Zkus to znovu.",
        502,
        origin,
      );
    }
    return json({ reply }, 200, origin);
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
    if (items === "exhausted") return exhausted(origin);
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
  if (meals === "exhausted") return exhausted(origin);
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
    } catch (error) {
      const origin = request.headers.get("Origin");
      const kvBusy = error instanceof Error &&
        /^KV (?:PUT|GET) failed: 429\b/.test(error.message);
      return fail(
        kvBusy ? "service_busy" : "ai_failed",
        kvBusy
          ? "Služba je teď vytížená. Zkus to za chvíli."
          : "Služba teď nefunguje. Zkus to později.",
        kvBusy ? 503 : 500,
        allowedOrigin(env, origin) ? origin : null,
      );
    }
  },
};

export { handle };
