import { describe, expect, it } from "vitest";

import { handle, type Env } from "../src/index";
import type { QuotaStore } from "../src/quota";
import {
  extractJson,
  parseMealsRequest,
  validateFridge,
  validateMeals,
} from "../src/schema";

const INSTALL = "0b9f5c2e-6f1a-4c3d-9e8b-1a2b3c4d5e6f";
const NOW = new Date("2026-10-07T12:00:00Z");
const JPEG = "/9j/4AAQSkZJRgABAQ==";

class MemoryKv implements QuotaStore {
  data = new Map<string, string>();
  async get(key: string) {
    return this.data.get(key) ?? null;
  }
  async put(key: string, value: string) {
    this.data.set(key, value);
  }
}

type Reply = unknown | Error;

function makeEnv(replies: Reply[], vars: Partial<Env> = {}) {
  const calls: { model: string; input: Record<string, unknown> }[] = [];
  const kv = new MemoryKv();
  const env: Env = {
    AI: {
      async run(model, input) {
        calls.push({ model, input });
        const next = replies.shift();
        if (next instanceof Error) throw next;
        return next;
      },
    },
    QUOTA: kv,
    ALLOWED_ORIGINS: "https://app.example",
    ...vars,
  };
  return { env, calls, kv };
}

function post(
  path: string,
  body: unknown,
  headers: Record<string, string> = {},
): Request {
  return new Request(`https://ai.example${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Install-Id": INSTALL,
      ...headers,
    },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

const fridgeOk = {
  response: JSON.stringify({
    items: [
      { name: "Vejce", amount: 6, unit: "ks", confidence: 0.9 },
      { name: "vejce", amount: 2, unit: "ks", confidence: 0.4 },
      { name: "Kuřecí prsa", amount: 500, unit: "g", confidence: 0.7 },
    ],
  }),
};

const meal = {
  title: "Míchaná vejce s kuřetem",
  minutes: 15,
  ingredients: [
    { name: "vejce", amount: 3, unit: "ks" },
    { name: "kuřecí prsa", amount: 150, unit: "g" },
  ],
  steps: ["Nakrájej maso.", "Osmahni a přidej vejce."],
  estimate: { kcal: 480, protein: 55, carbs: 2, fat: 28 },
};

const mealsBody = {
  items: [{ name: "vejce", amount: 6, unit: "ks" }],
  context: {
    trainingToday: true,
    eatenToday: { kcal: 1200, protein: 60 },
    proteinLeft: 80,
    maxMinutes: 20,
    adult: true,
  },
};

async function body(res: Response) {
  return (await res.json()) as Record<string, any>;
}

describe("fridge", () => {
  it("returns validated, deduplicated items", async () => {
    const { env, calls } = makeEnv([fridgeOk]);
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(200);
    const data = await body(res);
    expect(data.items).toEqual([
      { name: "Vejce", amount: 6, unit: "ks", confidence: 0.9 },
      { name: "Kuřecí prsa", amount: 500, unit: "g", confidence: 0.7 },
    ]);
    const content = (calls[0].input.messages as any[])[1].content;
    expect(content[1].image_url.url).toBe(`data:image/jpeg;base64,${JPEG}`);
    expect(calls[0].input.guided_json).toBeDefined();
  });

  it("accepts an empty fridge", async () => {
    const { env } = makeEnv([{ response: '{"items":[]}' }]);
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(200);
    expect((await body(res)).items).toEqual([]);
  });

  it("retries once on invalid JSON, then fails with 502", async () => {
    const { env, calls, kv } = makeEnv([
      { response: "nevím" },
      new Error("JSON Mode couldn't be met"),
    ]);
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(502);
    expect((await body(res)).error.code).toBe("ai_failed");
    expect(calls).toHaveLength(2);
    expect(kv.data.get("g:2026-10-07")).toBe("2");
  });

  it("recovers on the retry", async () => {
    const { env } = makeEnv([new Error("busy"), fridgeOk]);
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(200);
  });

  it("rejects non-JPEG and oversized images without calling the model", async () => {
    const { env, calls } = makeEnv([]);
    const png = await handle(
      post("/v1/fridge", { image: "iVBORw0KGgo=" }),
      env,
      NOW,
    );
    expect(png.status).toBe(400);
    const big = await handle(
      post("/v1/fridge", { image: "/9j/" + "A".repeat(1_500_000) }),
      env,
      NOW,
    );
    expect(big.status).toBe(413);
    expect(calls).toHaveLength(0);
  });
});

describe("meals", () => {
  it("returns meals and drops ones over the time limit", async () => {
    const slow = { ...meal, title: "Pečeně", minutes: 90 };
    const { env, calls } = makeEnv([
      { response: JSON.stringify({ meals: [slow, meal] }) },
    ]);
    const res = await handle(post("/v1/meals", mealsBody), env, NOW);
    expect(res.status).toBe(200);
    const data = await body(res);
    expect(data.meals).toHaveLength(1);
    expect(data.meals[0].title).toBe(meal.title);
    const system = (calls[0].input.messages as any[])[0].content as string;
    expect(system).not.toContain("nezletilý");
  });

  it("uses the minor-safe prompt unless adult is exactly true", async () => {
    const { env, calls } = makeEnv([
      { response: JSON.stringify({ meals: [meal] }) },
    ]);
    const minor = {
      ...mealsBody,
      context: { ...mealsBody.context, adult: "true" },
    };
    await handle(post("/v1/meals", minor), env, NOW);
    const [system, user] = (calls[0].input.messages as any[]).map(
      (m) => m.content as string,
    );
    expect(system).toContain("nezletilý");
    expect(JSON.parse(user).dnesSnedenoKcal).toBeNull();
  });

  it("rejects an empty item list", async () => {
    const { env } = makeEnv([]);
    const res = await handle(post("/v1/meals", { items: [] }), env, NOW);
    expect(res.status).toBe(400);
  });
});

describe("quota", () => {
  it("limits per install and reports a Czech message", async () => {
    const { env } = makeEnv(
      [fridgeOk, fridgeOk, fridgeOk],
      { FRIDGE_PER_INSTALL: "2" },
    );
    for (let i = 0; i < 2; i++) {
      const ok = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
      expect(ok.status).toBe(200);
    }
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(429);
    const data = await body(res);
    expect(data.error.code).toBe("quota_install");
    expect(data.error.message).toContain("limit");
  });

  it("enforces the global cap across installs", async () => {
    const { env } = makeEnv([fridgeOk, fridgeOk], { GLOBAL_DAILY_CAP: "1" });
    await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    const other = post(
      "/v1/fridge",
      { image: JPEG },
      { "X-Install-Id": "11111111-2222-4333-8444-555555555555" },
    );
    const res = await handle(other, env, NOW);
    expect(res.status).toBe(429);
    expect((await body(res)).error.code).toBe("quota_global");
  });

  it("resets on the next UTC day", async () => {
    const { env } = makeEnv([fridgeOk, fridgeOk], { FRIDGE_PER_INSTALL: "1" });
    await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    const res = await handle(
      post("/v1/fridge", { image: JPEG }),
      env,
      new Date("2026-10-08T00:01:00Z"),
    );
    expect(res.status).toBe(200);
  });

  it("does not count rejected requests", async () => {
    const { env, kv } = makeEnv([]);
    await handle(post("/v1/fridge", { image: "nope" }), env, NOW);
    expect(kv.data.size).toBe(0);
  });
});

describe("free plan", () => {
  it("stops for the day when the free allocation is used up", async () => {
    const { env, calls } = makeEnv([
      new Error("AiError: 4006: you have used up your daily free allocation of 10,000 neurons"),
    ]);
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(429);
    expect((await body(res)).error.code).toBe("quota_global");
    expect(calls).toHaveLength(1); // no retry
    const next = await handle(post("/v1/meals", mealsBody), env, NOW);
    expect(next.status).toBe(429);
    expect(calls).toHaveLength(1); // no model call at all
    const tomorrow = await handle(
      post("/v1/meals", mealsBody),
      env,
      new Date("2026-10-08T00:05:00Z"),
    );
    expect(tomorrow.status).toBe(502); // model called again (no reply queued)
    expect(calls.length).toBeGreaterThan(1);
  });

  it("detects exhaustion on the retry too", async () => {
    const { env, calls } = makeEnv([
      new Error("busy"),
      new Error("4006: you have used up your daily free allocation"),
    ]);
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(429);
    expect(calls).toHaveLength(2);
  });

  it("ignores 4006 or neurons later in an error message", async () => {
    const { env, kv } = makeEnv([
      new Error("Bad input: Vejce 4006: daily free allocation neurons"),
      new Error("busy"),
    ]);
    const res = await handle(post("/v1/meals", mealsBody), env, NOW);
    expect(res.status).toBe(502);
    expect(kv.data.has("x:2026-10-07")).toBe(false);
  });

  it("still answers 429 when KV cannot store the flag", async () => {
    const { env } = makeEnv([
      new Error("AiError: 4006: you have used up your daily free allocation"),
    ]);
    const kv = env.QUOTA;
    env.QUOTA = {
      get: (k) => kv.get(k),
      put: async (k, v, o) => {
        if (k.startsWith("x:")) throw new Error("KV down");
        await kv.put(k, v, o);
      },
    };
    const res = await handle(post("/v1/fridge", { image: JPEG }), env, NOW);
    expect(res.status).toBe(429);
  });
});

describe("http", () => {
  it("requires a UUID install id", async () => {
    const { env } = makeEnv([]);
    const res = await handle(
      post("/v1/fridge", { image: JPEG }, { "X-Install-Id": "abc" }),
      env,
      NOW,
    );
    expect(res.status).toBe(400);
  });

  it("answers CORS preflight only for allowed origins", async () => {
    const { env } = makeEnv([]);
    const ok = await handle(
      new Request("https://ai.example/v1/fridge", {
        method: "OPTIONS",
        headers: { Origin: "https://app.example" },
      }),
      env,
      NOW,
    );
    expect(ok.status).toBe(204);
    expect(ok.headers.get("Access-Control-Allow-Origin")).toBe(
      "https://app.example",
    );
    expect(ok.headers.get("Access-Control-Allow-Headers")).toContain(
      "X-Install-Id",
    );
    const bad = await handle(
      post("/v1/fridge", { image: JPEG }, { Origin: "https://evil.example" }),
      env,
      NOW,
    );
    expect(bad.status).toBe(403);
    expect(bad.headers.get("Access-Control-Allow-Origin")).toBeNull();
  });

  it("returns 404 for unknown paths and 400 for bad JSON", async () => {
    const { env } = makeEnv([]);
    expect((await handle(post("/v1/x", {}), env, NOW)).status).toBe(404);
    expect((await handle(post("/v1/meals", "{"), env, NOW)).status).toBe(400);
  });
});

describe("schema", () => {
  it("extracts JSON from fenced model text", () => {
    expect(extractJson('Tady:\n```json\n{"items":[]}\n```')).toEqual({
      items: [],
    });
    expect(extractJson("bez json")).toBeNull();
  });

  it("normalises units and clamps bad numbers", () => {
    const items = validateFridge({
      items: [
        { name: " Mléko\n", amount: "1,5", unit: "L", confidence: 3 },
        { name: "Sýr", amount: -2, unit: "kusy" },
        { name: "", amount: 1, unit: "g" },
      ],
    });
    expect(items).toEqual([
      { name: "Mléko", amount: 1.5, unit: null, confidence: 0.5 },
      { name: "Sýr", amount: null, unit: "ks", confidence: 0.5 },
    ]);
  });

  it("drops meals with missing estimate or steps", () => {
    expect(
      validateMeals({ meals: [{ ...meal, steps: [] }] }, 30),
    ).toBeNull();
    expect(
      validateMeals(
        { meals: [{ ...meal, estimate: { kcal: 100 } }] },
        30,
      ),
    ).toBeNull();
  });

  it("defaults the context safely", () => {
    const req = parseMealsRequest({ items: [{ name: "rýže" }] });
    expect(req).toMatchObject({
      context: { adult: false, maxMinutes: 30, proteinLeft: null },
    });
  });
});
