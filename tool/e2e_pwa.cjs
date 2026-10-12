// Isolated Chrome profile seeded by e2e_workout.cjs. Never use a personal profile.
const {chromium} = require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const worker = 'build/web/service_worker.js';
const original = fs.readFileSync(worker, 'utf8');
let context;
const errors = [];
async function launch(offline = false) {
  context = await chromium.launchPersistentContext(process.argv[2], {
    executablePath: process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true, viewport: {width: 400, height: 800},
  });
  await context.setOffline(offline);
  const page = context.pages()[0] || await context.newPage();
  for (const other of context.pages()) {
    if (other !== page) await other.close();
  }
  page.on('pageerror', e => errors.push(String(e)));
  return page;
}
async function semantics(page) {
  await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder') || document.querySelectorAll('flt-semantics').length > 1);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 1);
}
async function see(page, pattern) {
  await page.waitForFunction(source => new RegExp(source).test(
    [...document.querySelectorAll('flt-semantics')].map(e => e.getAttribute('aria-label') || e.textContent).join(' | ')
  ), pattern.source, {timeout: 20000});
}
async function type(page, index, text) {
  await page.getByRole('textbox').nth(index).click();
  await page.waitForFunction(() => document.activeElement?.tagName === 'INPUT');
  await page.keyboard.press('Control+A');
  await page.keyboard.type(text);
}
(async () => {
  let page = await launch();
  await page.goto('http://localhost:8099/');
  await semantics(page);
  await page.evaluate(async () => { await navigator.serviceWorker.ready; });
  await page.waitForFunction(() => !!navigator.serviceWorker.controller);
  // Program může založit den s více cviky; bench press v něm už být může.
  await page.getByRole('button', {name: /^(Začít|Pokračovat v tréninku)/}).first().click();
  await see(page, /Potvrdit sérii|Přidat cvik/);
  const workoutText = () => page.evaluate(() => [...document.querySelectorAll('flt-semantics')]
    .map(e => e.getAttribute('aria-label') || e.textContent).join(' | '));
  if (!/Bench press/.test(await workoutText())) {
    await page.getByRole('button', {name: /Přidat cvik/}).first().click();
    await see(page, /Přidat cviky/);
    await page.getByRole('textbox').last().click();
    await page.keyboard.type('bench');
    // Výběr je vícenásobný: označit cvik a potvrdit tlačítkem dole.
    await page.getByRole('button', {name: /^Bench press/}).first().click();
    await page.getByRole('button', {name: 'Přidat cvik'}).last().click();
  }
  await see(page, /Potvrdit sérii/);
  await type(page, 0, '82,5');
  await type(page, 1, '7');
  await page.getByRole('button', {name: 'Potvrdit sérii'}).first().click();
  await see(page, /Zrušit potvrzení/);

  // A real service worker install/controller change using the same built assets.
  fs.writeFileSync(worker, original.replace(/const CACHE = '[^']+';/,
    `const CACHE = 'gymzapisnik-shell-review-${Date.now()}';`));
  await page.evaluate(async () => { const r = await navigator.serviceWorker.getRegistration(); await r.update(); });
  await page.getByRole('button', {name: 'Načíst', exact: true}).waitFor({timeout: 30000});
  // Correct a confirmed set just before accepting the update.
  await type(page, 1, '6');
  await Promise.all([
    page.waitForEvent('load'),
    page.getByRole('button', {name: 'Načíst', exact: true}).click(),
  ]);
  await semantics(page);
  await see(page, /Pokračovat v tréninku/);
  await page.getByRole('button', {name: /Pokračovat v tréninku/}).click();
  await see(page, /Zrušit potvrzení/);
  console.log('ok: update preserves corrected confirmed set');
  await context.setOffline(true);
  await page.reload();
  await semantics(page);
  await see(page, /Pokračovat v tréninku/);
  console.log('ok: offline reload');
  await context.close();

  page = await launch(true);
  await page.goto('http://localhost:8099/');
  await semantics(page);
  await see(page, /Pokračovat v tréninku/);
  await page.getByRole('button', {name: /Pokračovat v tréninku/}).click();
  await see(page, /Zrušit potvrzení/);
  const values = [];
  for (const index of [0, 1]) {
    await page.getByRole('textbox').nth(index).click();
    await page.waitForFunction(() => document.activeElement?.tagName === 'INPUT');
    values.push(await page.evaluate(() => document.activeElement.value));
  }
  assert.ok(values.some(v => /82[,.]5/.test(v)), JSON.stringify(values));
  assert.ok(values.includes('6'), JSON.stringify(values));
  console.log('ok: full browser restart offline preserves 82.5 kg x 6');
  await page.getByRole('button', {name: 'Dokončit', exact: true}).click();
  // Den programu má další nepotvrzené série, takže se dokončení musí potvrdit.
  await see(page, /Dokončit trénink\?/);
  await page.getByRole('button', {name: 'Dokončit', exact: true}).last().click();
  await see(page, /Trénink hotový/);
  await see(page, /495/);
  await page.getByRole('button', {name: 'Hotovo', exact: true}).click();
  await page.getByRole('button', {name: 'Vše', exact: true}).click();
  await see(page, /Hevy Push/);
  await see(page, /495/);
  console.log('ok: offline summary and history match saved volume 495 kg');
  assert.deepEqual(errors, []);
})().catch(async e => {
  console.error(e); process.exitCode = 1;
  if (process.env.E2E_SHOT) await context?.pages()[0]?.screenshot({path: process.env.E2E_SHOT}).catch(() => {});
}).finally(async () => {
  fs.writeFileSync(worker, original);
  await context?.close();
});
