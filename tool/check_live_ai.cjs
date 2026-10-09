// Explicit diagnostic against the already deployed proxy; no personal data.
// LIVE_AI_URL=https://... PLAYWRIGHT_CORE=<path> node tool/check_live_ai.cjs
// Optional APP_ORIGIN (must be allowed by the deployed Worker). Does not deploy.
const { chromium } = require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');

(async () => {
  const api = process.env.LIVE_AI_URL;
  if (!api) throw new Error('Set LIVE_AI_URL to explicitly enable live calls.');
  const origin = process.env.APP_ORIGIN || 'http://localhost:8080';
  const browser = await chromium.launch({
    executablePath: process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true,
  });
  try {
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.route(origin + '/review-ai-probe', route => route.fulfill({
      contentType: 'text/html', body: '<html><body>AI transport diagnostic</body></html>',
    }));
    await page.goto(origin + '/review-ai-probe');
    const install = randomUUID();
    const mealRequest = {
      items: [
        {name: 'vejce', amount: 6, unit: 'ks'},
        {name: 'chléb', amount: 200, unit: 'g'},
        {name: 'rajče', amount: 150, unit: 'g'},
      ],
      context: {adult: true, trainingToday: true, maxMinutes: 20,
        eatenToday: {kcal: null, protein: null}, proteinLeft: null},
    };
    const results = [];
    for (let i = 0; i < 3; i++) {
      const result = await page.evaluate(async ({api, install, body}) => {
        const start = performance.now();
        try {
          const r = await fetch(api + '/v1/meals', {
            method: 'POST', headers: {'Content-Type': 'application/json', 'X-Install-Id': install},
            body: JSON.stringify(body), signal: AbortSignal.timeout(65000),
          });
          const json = await r.json();
          return {status: r.status, code: json.error?.code, meals: json.meals,
            elapsedMs: Math.round(performance.now() - start)};
        } catch (e) {
          return {status: 0, transport: e.name, elapsedMs: Math.round(performance.now() - start)};
        }
      }, {api, install, body: mealRequest});
      const missingUnits = result.meals?.flatMap(m => m.ingredients).filter(i => i.amount != null && i.unit == null).length;
      console.log(JSON.stringify({attempt: i + 1, status: result.status, code: result.code,
        transport: result.transport, elapsedMs: result.elapsedMs, meals: result.meals?.length, missingUnits}));
      results.push(result);
      if (result.status === 429) break; // do not fight the Free allocation
    }
    assert.equal(results.length, 3, 'live quota blocked the repeat check');
    for (const result of results) {
      assert.equal(result.status, 200, 'live service did not return meals');
      assert.ok(result.meals.length > 0);
    }
    console.log('Live AI browser transport: 3/3 OK (synthetic items, not fridge quality proof).');
  } finally {
    await browser.close();
  }
})().catch(error => {console.error(error.message); process.exitCode = 1;});
