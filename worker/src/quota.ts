// Daily quota in KV. KV is eventually consistent, so counts are approximate
// (a burst from many devices can overshoot a little). That is acceptable for
// a free tester allocation; the app cannot hold a secret anyway.

export interface QuotaStore {
  get(key: string): Promise<string | null>;
  put(
    key: string,
    value: string,
    options?: { expirationTtl?: number },
  ): Promise<void>;
}

export type Feature = "fridge" | "meals";

export interface Limits {
  fridge: number;
  meals: number;
  global: number;
}

/** UTC day, e.g. "2026-10-07". */
export const dayOf = (now: Date) => now.toISOString().slice(0, 10);

const TTL = 2 * 24 * 3600;

async function read(store: QuotaStore, key: string): Promise<number> {
  const n = Number(await store.get(key));
  return Number.isFinite(n) && n > 0 ? n : 0;
}

export type QuotaResult = "ok" | "install" | "global";

/**
 * Checks and reserves one request of [feature] for [installId]. Also reserves
 * both possible model calls in the global counter. Reserve the retry upfront:
 * KV permits only one write per key per second. Unused retries stay reserved.
 */
export async function reserve(
  store: QuotaStore,
  limits: Limits,
  installId: string,
  feature: Feature,
  now: Date,
): Promise<QuotaResult> {
  const day = dayOf(now);
  const installKey = `i:${day}:${installId}:${feature}`;
  const globalKey = `g:${day}`;
  const [mine, all] = await Promise.all([
    read(store, installKey),
    read(store, globalKey),
  ]);
  if (mine >= limits[feature]) return "install";
  if (all + 2 > limits.global) return "global";
  await Promise.all([
    store.put(installKey, String(mine + 1), { expirationTtl: TTL }),
    store.put(globalKey, String(all + 2), { expirationTtl: TTL }),
  ]);
  return "ok";
}

/** The free Workers AI allocation ran out today (set after error 4006). */
export async function markExhausted(
  store: QuotaStore,
  now: Date,
): Promise<void> {
  await store.put(`x:${dayOf(now)}`, "1", { expirationTtl: TTL });
}

export async function isExhausted(
  store: QuotaStore,
  now: Date,
): Promise<boolean> {
  return (await store.get(`x:${dayOf(now)}`)) === "1";
}
