// Local mock of the AI proxy for app development and E2E tests.
// Runs the real Worker code (bundled by `wrangler deploy --dry-run`) with an
// in-memory KV and a fake Workers AI that answers instantly, offline, for free.
//
//   npm run mock            -> http://localhost:8787
//   PORT=9000 ORIGINS=http://localhost:8099 npm run mock
//
// MOCK_AI=exhausted makes every model call fail like a used-up free plan.

import { createServer } from "node:http";
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";

const bundle = resolve(process.argv[2] ?? ".wrangler/mock/index.js");
// The default export wraps errors in a 500 exactly as in production.
const worker = (await import(pathToFileURL(bundle).href)).default;

const PORT = Number(process.env.PORT ?? 8787);
const ORIGINS =
  process.env.ORIGINS ??
  "http://localhost:8080,http://127.0.0.1:8080,http://localhost:8099,http://127.0.0.1:8099";

const kv = new Map();
const quota = {
  async get(key) {
    return kv.get(key) ?? null;
  },
  async put(key, value) {
    kv.set(key, value);
  },
};

const FRIDGE = {
  items: [
    { name: "Vejce", amount: 6, unit: "ks", confidence: 0.9 },
    { name: "Tvaroh", amount: 250, unit: "g", confidence: 0.8 },
    { name: "Banán", amount: 2, unit: "ks", confidence: 0.7 },
    { name: "Mléko", amount: 1000, unit: "ml", confidence: 0.6 },
  ],
};

const MEALS = {
  meals: [
    {
      title: "Tvaroh s banánem",
      minutes: 5,
      ingredients: [
        { name: "tvaroh", amount: 250, unit: "g" },
        { name: "banán", amount: 1, unit: "ks" },
      ],
      steps: ["Nakrájej banán.", "Smíchej s tvarohem."],
      estimate: { kcal: 380, protein: 33, carbs: 36, fat: 11 },
    },
    {
      title: "Míchaná vejce",
      minutes: 10,
      ingredients: [
        { name: "vejce", amount: 3, unit: "ks" },
        { name: "mléko", amount: 50, unit: "ml" },
      ],
      steps: ["Rozšlehej vejce s mlékem.", "Na pánvi míchej do zatuhnutí."],
      estimate: { kcal: 250, protein: 20, carbs: 3, fat: 17 },
    },
  ],
};

const ai = {
  async run(_model, input) {
    if (process.env.MOCK_AI === "exhausted") {
      throw new Error(
        "AiError: 4006: you have used up your daily free allocation of 10,000 neurons",
      );
    }
    await new Promise((r) => setTimeout(r, 300));
    const user = input.messages?.[1]?.content;
    const reply = Array.isArray(user) ? FRIDGE : MEALS;
    return { response: JSON.stringify(reply) };
  },
};

const env = {
  AI: ai,
  QUOTA: quota,
  ALLOWED_ORIGINS: ORIGINS,
  FRIDGE_PER_INSTALL: process.env.FRIDGE_PER_INSTALL ?? "50",
  MEALS_PER_INSTALL: process.env.MEALS_PER_INSTALL ?? "50",
  GLOBAL_DAILY_CAP: "1000",
};

createServer(async (req, res) => {
  try {
    const chunks = [];
    for await (const c of req) chunks.push(c);
    const headers = new Headers();
    for (const [k, v] of Object.entries(req.headers)) {
      for (const one of Array.isArray(v) ? v : [v]) {
        if (one !== undefined) headers.append(k, one);
      }
    }
    const hasBody = !["GET", "HEAD", "OPTIONS"].includes(req.method ?? "");
    const request = new Request(`http://127.0.0.1:${PORT}${req.url}`, {
      method: req.method,
      headers,
      body: hasBody ? Buffer.concat(chunks) : undefined,
    });
    const response = await worker.fetch(request, env);
    res.writeHead(response.status, [...response.headers].flat());
    res.end(Buffer.from(await response.arrayBuffer()));
    console.log(req.method, req.url, response.status);
  } catch (error) {
    console.error(req.method, req.url, "mock error:", error);
    if (!res.headersSent) res.writeHead(500);
    res.end();
  }
}).listen(PORT, "127.0.0.1", () =>
  console.log(`mock AI proxy on http://localhost:${PORT} (127.0.0.1 only)`),
);
