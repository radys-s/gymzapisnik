/// Adresa AI proxy (Cloudflare Worker, složka `worker/`).
///
/// Zadává se při buildu: `--dart-define=AI_URL=https://...workers.dev`.
/// Prázdná = AI funkce jsou vypnuté a aplikace to řekne uživateli.
const aiBaseUrl = String.fromEnvironment('AI_URL');
