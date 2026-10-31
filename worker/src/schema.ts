// Request and model-output validation. Pure functions, no Workers APIs.

export type Unit = "g" | "ml" | "ks";
const UNITS: readonly Unit[] = ["g", "ml", "ks"];

export interface FridgeItem {
  name: string;
  amount: number | null;
  unit: Unit | null;
  confidence: number;
}

export interface Ingredient {
  name: string;
  amount: number | null;
  unit: Unit | null;
}

export interface Estimate {
  kcal: number;
  protein: number;
  carbs: number;
  fat: number;
}

export interface Meal {
  title: string;
  minutes: number;
  ingredients: Ingredient[];
  steps: string[];
  estimate: Estimate;
}

export interface MealContext {
  trainingToday: boolean;
  eatenToday: { kcal: number | null; protein: number | null };
  proteinLeft: number | null;
  maxMinutes: number;
  adult: boolean;
}

export interface MealsRequest {
  items: Ingredient[];
  context: MealContext;
}

export const MAX_ITEMS = 40;
export const MAX_NAME = 60;
export const MAX_MEALS = 3;
export const MAX_STEPS = 10;
export const MAX_STEP_LEN = 300;
/** ~1 MB of JPEG bytes as base64. */
export const MAX_IMAGE_B64 = 1_400_000;

const isObj = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

/** Single line, trimmed, no control characters (prompt hygiene). */
export function cleanText(v: unknown, max: number): string | null {
  if (typeof v !== "string") return null;
  const s = v.replace(/[\u0000-\u001f\u007f]+/g, " ").replace(/\s+/g, " ").trim();
  if (s.length === 0) return null;
  return s.length > max ? s.slice(0, max).trim() : s;
}

function num(v: unknown, min: number, max: number): number | null {
  const n = typeof v === "string" ? Number(v.replace(",", ".")) : v;
  return typeof n === "number" && Number.isFinite(n) && n >= min && n <= max
    ? n
    : null;
}

function unit(v: unknown): Unit | null {
  if (typeof v !== "string") return null;
  const u = v.trim().toLowerCase();
  if (u === "kus" || u === "kusy" || u === "kusů" || u === "pcs") return "ks";
  return (UNITS as readonly string[]).includes(u) ? (u as Unit) : null;
}

function ingredient(v: unknown): Ingredient | null {
  if (!isObj(v)) return null;
  const name = cleanText(v.name, MAX_NAME);
  if (name === null) return null;
  return { name, amount: num(v.amount, 0.01, 100_000), unit: unit(v.unit) };
}

// ---- requests ----

export function parseFridgeRequest(body: unknown): { image: string } | string {
  if (!isObj(body) || typeof body.image !== "string") {
    return "Chybí fotka.";
  }
  const image = body.image.replace(/^data:image\/jpeg;base64,/, "");
  if (image.length > MAX_IMAGE_B64) return "Fotka je moc velká.";
  // JPEG starts with FF D8 FF, which is "/9j/" in base64.
  if (!image.startsWith("/9j/") || !/^[A-Za-z0-9+/]+=*$/.test(image)) {
    return "Fotka musí být JPEG.";
  }
  return { image };
}

export function parseMealsRequest(body: unknown): MealsRequest | string {
  if (!isObj(body) || !Array.isArray(body.items)) {
    return "Chybí seznam potravin.";
  }
  const items = body.items
    .slice(0, MAX_ITEMS)
    .map(ingredient)
    .filter((i): i is Ingredient => i !== null);
  if (items.length === 0) return "Seznam potravin je prázdný.";
  const c = isObj(body.context) ? body.context : {};
  const eaten = isObj(c.eatenToday) ? c.eatenToday : {};
  const maxMinutes = num(c.maxMinutes, 5, 120);
  return {
    items,
    context: {
      trainingToday: c.trainingToday === true,
      eatenToday: {
        kcal: num(eaten.kcal, 0, 20_000),
        protein: num(eaten.protein, 0, 1_000),
      },
      proteinLeft: num(c.proteinLeft, 0, 500),
      maxMinutes: maxMinutes === null ? 30 : Math.round(maxMinutes),
      // Anything but an explicit `true` is treated as a minor.
      adult: c.adult === true,
    },
  };
}

// ---- model output ----

/** Model text to JSON: tolerates ```json fences and text around the object. */
export function extractJson(raw: unknown): unknown {
  if (isObj(raw)) return raw;
  if (typeof raw !== "string") return null;
  const fenced = raw.match(/```(?:json)?\s*([\s\S]*?)```/);
  const text = fenced ? fenced[1] : raw;
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch {
    return null;
  }
}

export function validateFridge(raw: unknown): FridgeItem[] | null {
  const json = extractJson(raw);
  if (!isObj(json) || !Array.isArray(json.items)) return null;
  const seen = new Set<string>();
  const items: FridgeItem[] = [];
  for (const v of json.items.slice(0, MAX_ITEMS)) {
    const i = ingredient(v);
    if (i === null || seen.has(i.name.toLowerCase())) continue;
    seen.add(i.name.toLowerCase());
    const conf = isObj(v) ? num(v.confidence, 0, 1) : null;
    items.push({ ...i, confidence: conf ?? 0.5 });
  }
  return items;
}

export function validateMeals(raw: unknown, maxMinutes: number): Meal[] | null {
  const json = extractJson(raw);
  if (!isObj(json) || !Array.isArray(json.meals)) return null;
  const meals: Meal[] = [];
  for (const v of json.meals) {
    if (!isObj(v)) continue;
    const title = cleanText(v.title, 80);
    const minutes = num(v.minutes, 1, 240);
    if (title === null || minutes === null) continue;
    if (minutes > maxMinutes) continue;
    const ingredients = Array.isArray(v.ingredients)
      ? v.ingredients.map(ingredient).filter((i): i is Ingredient => i !== null)
      : [];
    const steps = Array.isArray(v.steps)
      ? v.steps
          .slice(0, MAX_STEPS)
          .map((s) => cleanText(s, MAX_STEP_LEN))
          .filter((s): s is string => s !== null)
      : [];
    const e = isObj(v.estimate) ? v.estimate : {};
    const estimate = {
      kcal: num(e.kcal, 0, 5_000),
      protein: num(e.protein, 0, 300),
      carbs: num(e.carbs, 0, 600),
      fat: num(e.fat, 0, 300),
    };
    if (
      ingredients.length === 0 ||
      steps.length === 0 ||
      estimate.kcal === null ||
      estimate.protein === null ||
      estimate.carbs === null ||
      estimate.fat === null
    ) {
      continue;
    }
    meals.push({
      title,
      minutes: Math.round(minutes),
      ingredients: ingredients.slice(0, 20),
      steps,
      estimate: estimate as Estimate,
    });
    if (meals.length === MAX_MEALS) break;
  }
  return meals.length > 0 ? meals : null;
}

// ---- guided_json schemas for the model ----

const ingredientSchema = {
  type: "object",
  properties: {
    name: { type: "string" },
    amount: { type: ["number", "null"] },
    unit: { type: ["string", "null"], enum: ["g", "ml", "ks", null] },
  },
  required: ["name", "amount", "unit"],
};

export const fridgeSchema = {
  type: "object",
  properties: {
    items: {
      type: "array",
      maxItems: MAX_ITEMS,
      items: {
        ...ingredientSchema,
        properties: {
          ...ingredientSchema.properties,
          confidence: { type: "number", minimum: 0, maximum: 1 },
        },
        required: ["name", "amount", "unit", "confidence"],
      },
    },
  },
  required: ["items"],
};

export const mealsSchema = {
  type: "object",
  properties: {
    meals: {
      type: "array",
      minItems: 1,
      maxItems: MAX_MEALS,
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          minutes: { type: "integer" },
          ingredients: { type: "array", items: ingredientSchema },
          steps: { type: "array", items: { type: "string" } },
          estimate: {
            type: "object",
            properties: {
              kcal: { type: "number" },
              protein: { type: "number" },
              carbs: { type: "number" },
              fat: { type: "number" },
            },
            required: ["kcal", "protein", "carbs", "fat"],
          },
        },
        required: ["title", "minutes", "ingredients", "steps", "estimate"],
      },
    },
  },
  required: ["meals"],
};

// ---- machine photo -> catalog exercises ----

export interface CatalogEntry {
  id: string;
  name: string;
}

export interface MachineRequest {
  image: string;
  exercises: CatalogEntry[];
}

export interface MachineMatch {
  id: string;
  confidence: number;
}

export interface MachineResult {
  machine: string | null;
  matches: MachineMatch[];
}

export const MAX_CATALOG = 150;
export const MAX_MATCHES = 3;
const ID_RE = /^[a-z0-9_-]{1,48}$/;

export function parseMachineRequest(body: unknown): MachineRequest | string {
  const photo = parseFridgeRequest(body);
  if (typeof photo === "string") return photo;
  const list = isObj(body) && Array.isArray(body.exercises) ? body.exercises : [];
  const seen = new Set<string>();
  const exercises: CatalogEntry[] = [];
  for (const v of list.slice(0, MAX_CATALOG)) {
    if (!isObj(v) || typeof v.id !== "string" || !ID_RE.test(v.id)) continue;
    const name = cleanText(v.name, MAX_NAME);
    if (name === null || seen.has(v.id)) continue;
    seen.add(v.id);
    exercises.push({ id: v.id, name });
  }
  if (exercises.length === 0) return "Chybí seznam cviků.";
  return { image: photo.image, exercises };
}

/** Keeps only ids the app sent, best first, at most [MAX_MATCHES]. */
export function validateMachine(
  raw: unknown,
  known: ReadonlySet<string>,
): MachineResult | null {
  const json = extractJson(raw);
  if (!isObj(json) || !Array.isArray(json.matches)) return null;
  const seen = new Set<string>();
  const matches: MachineMatch[] = [];
  for (const v of json.matches) {
    if (!isObj(v) || typeof v.id !== "string") continue;
    const id = v.id.trim();
    if (!known.has(id) || seen.has(id)) continue;
    seen.add(id);
    matches.push({ id, confidence: num(v.confidence, 0, 1) ?? 0.5 });
  }
  matches.sort((a, b) => b.confidence - a.confidence);
  return {
    machine: cleanText(json.machine, 80),
    matches: matches.slice(0, MAX_MATCHES),
  };
}

export const machineSchema = {
  type: "object",
  properties: {
    machine: { type: ["string", "null"] },
    matches: {
      type: "array",
      maxItems: MAX_MATCHES,
      items: {
        type: "object",
        properties: {
          id: { type: "string" },
          confidence: { type: "number", minimum: 0, maximum: 1 },
        },
        required: ["id", "confidence"],
      },
    },
  },
  required: ["machine", "matches"],
};

// ---- trainer chat ----

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface CoachRequest {
  messages: ChatMessage[];
  context: string;
  adult: boolean;
}

export const MAX_CHAT = 12;
export const MAX_MESSAGE = 1_000;
export const MAX_CONTEXT = 6_000;
export const MAX_REPLY = 1_500;

/** Like [cleanText] but keeps line breaks (chat answers have lists). */
export function cleanMultiline(v: unknown, max: number): string | null {
  if (typeof v !== "string") return null;
  const s = v
    .replace(/\r\n?/g, "\n")
    .replace(/[\u0000-\u0009\u000b-\u001f\u007f]+/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  if (s.length === 0) return null;
  return s.length > max ? s.slice(0, max).trim() : s;
}

export function parseCoachRequest(body: unknown): CoachRequest | string {
  if (!isObj(body) || !Array.isArray(body.messages)) {
    return "Chybí zpráva.";
  }
  const messages: ChatMessage[] = [];
  for (const v of body.messages.slice(-MAX_CHAT)) {
    if (!isObj(v) || (v.role !== "user" && v.role !== "assistant")) continue;
    const content = cleanMultiline(v.content, MAX_MESSAGE);
    if (content !== null) messages.push({ role: v.role, content });
  }
  if (messages.length === 0 || messages[messages.length - 1].role !== "user") {
    return "Chybí otázka.";
  }
  // The context is app data; it travels as JSON text, never as instructions.
  const context = isObj(body.context) ? JSON.stringify(body.context) : "{}";
  if (context.length > MAX_CONTEXT) return "Souhrn tréninků je moc dlouhý.";
  return { messages, context, adult: body.adult === true };
}

export function validateCoach(raw: unknown): string | null {
  // Some models wrap plain text in an object; accept {reply: "..."} too.
  const text = isObj(raw) && typeof raw.reply === "string" ? raw.reply : raw;
  return cleanMultiline(text, MAX_REPLY);
}
