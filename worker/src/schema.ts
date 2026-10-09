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
