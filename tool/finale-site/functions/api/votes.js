// Hlasy testerů pro finále vzhledu. GET vrací jen součty, POST uloží hlas jednoho testera.
// Poznámky a jména se ven nevracejí, čte je jen Tomáš přes `wrangler kv`.
const ROWS = ['priority', 'trenink', 'serie', 'strava', 'celkem'];
const OPTS = ['01', '02', '03'];
const ID = /^[a-z0-9]{16,40}$/;

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

export async function onRequestGet({ env }) {
  const tally = Object.fromEntries(ROWS.map((r) => [r, { '01': 0, '02': 0, '03': 0 }]));
  let count = 0;
  let cursor;
  do {
    const page = await env.FINALE_VOTES.list({ prefix: 'v:', cursor });
    for (const k of page.keys) {
      const m = k.metadata || {};
      count++;
      for (const r of ROWS) if (OPTS.includes(m[r])) tally[r][m[r]]++;
    }
    cursor = page.list_complete ? undefined : page.cursor;
  } while (cursor);
  return json({ count, tally });
}

export async function onRequestPost({ request, env }) {
  const raw = await request.text();
  if (raw.length > 4000) return json({ error: 'too_large' }, 413);
  let b;
  try {
    b = JSON.parse(raw);
  } catch {
    return json({ error: 'bad_json' }, 400);
  }
  if (!b || typeof b.id !== 'string' || !ID.test(b.id)) return json({ error: 'bad_id' }, 400);
  const meta = {};
  for (const r of ROWS) meta[r] = OPTS.includes(b[r]) ? b[r] : '';
  const note = typeof b.note === 'string' ? b.note.trim().slice(0, 600) : '';
  const name = typeof b.name === 'string' ? b.name.trim().slice(0, 40) : '';
  if (!ROWS.some((r) => meta[r]) && !note) return json({ error: 'empty' }, 400);
  await env.FINALE_VOTES.put('v:' + b.id, JSON.stringify({ ...meta, note, name, at: Date.now() }), { metadata: meta });
  return json({ ok: true });
}
