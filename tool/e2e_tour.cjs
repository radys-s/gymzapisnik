// Screenshot tour of the real web build for UX review (run in CI by tester-build.yml).
// New user: onboarding answered like a person would → every tab → one full workout →
// summary → settings. Saves a PNG and the semantics text per step to E2E_DIR.
// Never fails on a missing element: logs it and goes on, so one run shows the whole app.
// Usage: node tool/e2e_tour.cjs <profile-dir>   (app served at http://localhost:8099/)
const {chromium} = require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
const fs = require('node:fs');
const path = require('node:path');

const out = process.env.E2E_DIR || 'e2e-shots';
fs.mkdirSync(out, {recursive: true});
const log = [];
const note = (...a) => { const s = a.join(' '); console.log(s); log.push(s); };

(async () => {
  const ctx = await chromium.launchPersistentContext(process.argv[2] || '/tmp/gz-tour', {
    executablePath: process.env.CHROME,
    headless: true,
    viewport: {width: 390, height: 844},
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
  });
  const p = await ctx.newPage();
  const errors = [];
  p.on('pageerror', e => errors.push('pageerror: ' + String(e)));
  p.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()); });

  const txt = () => p.evaluate(() => [...document.querySelectorAll('flt-semantics')]
    .map(e => e.getAttribute('aria-label') || e.textContent).filter(Boolean).join(' | '));
  const sem = async () => {
    for (let i = 0; i < 30; i++) {
      await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click()).catch(() => {});
      await p.waitForTimeout(500);
      if (await p.evaluate(() => document.querySelectorAll('flt-semantics').length > 1)) return;
    }
    note('WARN semantics did not start');
  };
  let n = 0;
  const shot = async name => {
    await p.waitForTimeout(700);
    const file = `${String(++n).padStart(2, '0')}-${name}`;
    await p.screenshot({path: path.join(out, file + '.png')}).catch(() => {});
    const t = await txt().catch(() => '');
    fs.writeFileSync(path.join(out, file + '.txt'), t);
    note(`shot ${file}: ${t.slice(0, 160)}`);
  };
  const buttons = () => p.evaluate(() => [...document.querySelectorAll('flt-semantics[role=button],flt-semantics[role=checkbox],flt-semantics[role=radio],flt-semantics[role=switch],flt-semantics[role=tab]')]
    .map(e => (e.getAttribute('aria-label') || e.textContent || '').trim()).filter(Boolean));
  // Click by accessible name; scroll the Flutter page until the element is on screen.
  const tap = async (name, role = 'button') => {
    const l = p.getByRole(role, {name}).first();
    if (!(await l.count())) { note('MISS', role, String(name)); return false; }
    for (let i = 0; i < 10; i++) {
      const box = await l.boundingBox().catch(() => null);
      if (box && box.y >= 40 && box.y + box.height <= 844 - 80) break;
      await p.mouse.move(195, 420);
      await p.mouse.wheel(0, box && box.y < 40 ? -300 : 300);
      await p.waitForTimeout(250);
    }
    await l.click({timeout: 4000}).catch(e => note('CLICKFAIL', String(name), e.message.split('\n')[0]));
    await p.waitForTimeout(600);
    return true;
  };
  const scrollShots = async (name, pages = 3) => {
    await shot(name);
    for (let i = 1; i < pages; i++) {
      await p.mouse.move(195, 420);
      await p.mouse.wheel(0, 650);
      await shot(`${name}-${i + 1}`);
    }
    for (let i = 0; i < pages; i++) { await p.mouse.wheel(0, -1500); await p.waitForTimeout(100); }
  };
  const section = async (name, fn) => {
    try { await fn(); } catch (e) { note('SECTION FAIL', name, e.message.split('\n')[0]); await shot(`fail-${name}`); }
  };

  await p.goto('http://localhost:8099/');
  await p.waitForTimeout(4000);
  await sem();

  await section('onboarding', async () => {
    const prefer = [/^Sestavit můj plán/, /^Pokračovat/, /^Vyber za mě/, /^Nic mě nebolí/,
      /^Doplním později/, /^Teď ne/, /^Hotovo/, /^Začít/];
    const skip = /^(Zpět|Přeskočit|Back)$/;
    for (let step = 0; step < 30; step++) {
      const t = await txt();
      if (/Domů/.test(t) && /Strava/.test(t) && /Pokrok/.test(t)) break;
      await shot(`onboarding-${step}`);
      if (/Než začneš|Souhlasím/.test(t)) {
        await tap(/Souhlasím/, 'checkbox');
        await tap(/18 let nebo/, 'radio');
        await tap(/^Pokračovat/);
        continue;
      }
      const names = await buttons();
      let clicked = false;
      for (const re of prefer) {
        if (names.some(x => re.test(x)) && await tap(re)) { clicked = true; break; }
      }
      if (!clicked) {
        const option = names.find(x => !skip.test(x));
        if (!option) { note('STUCK onboarding', names.join(' / ')); break; }
        await tap(option);
      }
    }
  });

  await section('home', async () => { await scrollShots('home', 4); });
  await section('training-tab', async () => { await tap(/Trénink/, 'tab'); await scrollShots('training', 3); });
  await section('strava-tab', async () => { await tap(/Strava/, 'tab'); await scrollShots('strava', 3); });
  await section('progress-tab', async () => { await tap(/Pokrok/, 'tab'); await scrollShots('progress', 3); });

  await section('workout', async () => {
    await tap(/Domů/, 'tab');
    await p.mouse.wheel(0, -2000);
    if (!(await tap(/^Začít/))) await tap(/Volný trénink/);
    await shot('workout-start');
    const t = await txt();
    if (!/Potvrdit sérii/.test(t)) {
      await tap(/Přidat cvik/);
      await shot('picker');
      await p.getByRole('textbox').last().click().catch(() => {});
      await p.keyboard.type('bench');
      await p.waitForTimeout(800);
      await tap(/^Bench press/);
      await tap(/Přidat cvik/);
    }
    await scrollShots('workout', 2);
    for (let i = 0; i < 3; i++) {
      if (!(await tap('Potvrdit sérii'))) break;
      await shot(`set-${i + 1}-done`);
    }
    await tap('Přeskočit');
    await tap(/^Dokončit/);
    await shot('finish-confirm');
    await tap(/^Dokončit/);
    await p.waitForTimeout(2500);
    await p.mouse.click(195, 420);
    await scrollShots('summary', 3);
    await tap(/^Hotovo/);
    await scrollShots('home-after', 3);
  });

  await section('progress-after-workout', async () => {
    await tap(/Pokrok/, 'tab');
    await scrollShots('progress-after-workout', 3);
  });

  await section('settings', async () => {
    if (!(await tap(/^Nastavení/))) { await tap(/Pokrok/, 'tab'); await tap(/Nastavení/); }
    await scrollShots('settings', 5);
  });

  note('ERRORS', errors.length);
  for (const e of errors) note(e.slice(0, 300));
  fs.writeFileSync(path.join(out, 'log.txt'), log.join('\n'));
  await ctx.close();
})().catch(e => { note('TOUR CRASH', e.message); fs.writeFileSync(path.join(out, 'log.txt'), log.join('\n')); process.exit(1); });
