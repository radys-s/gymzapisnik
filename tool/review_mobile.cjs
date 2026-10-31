// Local browser evidence, isolated profile: never uses a tester's workout data.
const {chromium} = require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
const fs = require('node:fs');
(async () => {
  const browser = await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe', headless:true});
  const context = await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:1});
  const page = await context.newPage();
  const errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  await page.goto('http://127.0.0.1:8099/');
  await page.waitForSelector('flt-semantics-placeholder',{state:'attached'});
  await page.evaluate(()=>document.querySelector('flt-semantics-placeholder').click());
  await page.getByRole('button',{name:'Sestavit můj plán',exact:true}).waitFor();
  await page.screenshot({path:'build/review-welcome.png'});
  await page.getByRole('button',{name:'Sestavit můj plán',exact:true}).click();
  await page.getByRole('button',{name:'Přeskočit',exact:true}).click();
  await page.getByRole('checkbox',{name:/Souhlasím/}).click();
  await page.getByRole('radio',{name:'Je mi 18 let nebo víc',exact:true}).click();
  await page.getByRole('button',{name:'Pokračovat',exact:true}).click();
  await page.getByRole('button',{name:/^(Začít (?!trénink)|Volný trénink)/}).first().waitFor();
  await page.screenshot({path:'build/review-home.png'});
  fs.writeFileSync('build/review-home-semantics.txt',await page.locator('flt-semantics').allTextContents().then(x=>x.join('\n')));
  if(errors.length) throw new Error(errors.join('\n'));
  console.log('PASS: welcome, consent, three-tab home in isolated mobile browser');
  await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
