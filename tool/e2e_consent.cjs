// E2E: language → consent → reload keeps consent → offline reload from the service worker.
const {chromium}=require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
let ctx, browser;
(async()=>{
 // Dočasný kontext: v persistentním profilu headless Chrome 156 service worker
 // vůbec nezaregistruje. Souhlas přes reload drží i dočasný kontext.
 browser=await chromium.launch({executablePath:process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 ctx=await browser.newContext({viewport:{width:400,height:800}});
 const errs=[]; const p=await ctx.newPage(); p.on('pageerror',e=>errs.push(String(e)));
 const sem=async()=>{
  for(let i=0;i<20;i++){
   await p.waitForSelector('flt-semantics-placeholder',{state:'attached',timeout:20000}).catch(()=>{});
   await p.evaluate(()=>document.querySelector('flt-semantics-placeholder')?.click());
   await p.waitForTimeout(500);
   if(await p.evaluate(()=>document.querySelectorAll('flt-semantics').length>1)) return;
  }
  throw new Error('semantics did not start');
 };
 const txt=()=>p.evaluate(()=>[...document.querySelectorAll('flt-semantics')].map(e=>e.getAttribute('aria-label')||e.textContent).filter(Boolean).join(' | '));
 const see=async(re,msg)=>{
  const end=Date.now()+15000;
  while(Date.now()<end){ if(re.test(await txt())) { console.log('ok:',msg); return; } await p.waitForTimeout(200); }
  throw new Error(msg);
 };
 await p.goto('http://localhost:8099/'); await sem();
 await see(/Vyber jazyk/,'language step');
 await p.getByRole('button',{name:/Čeština/}).click();
 await see(/Každý den víš/,'welcome');
 await p.getByRole('button',{name:'Začít'}).click();
 await see(/Než začneš/,'consent');
 await p.getByRole('button',{name:/Souhlasím s podmínkami/}).click();
 await p.getByRole('button',{name:/18 let nebo/}).click();
 await p.waitForTimeout(400);
 await p.getByRole('button',{name:'Pokračovat'}).click();
 await see(/Jak chceš trénovat/,'path step');
 await p.getByRole('button',{name:'Přeskočit'}).click();
 await see(/Začít (?!trénink)|Volný trénink/,'home after consent');
 await p.reload(); await sem();
 await see(/Začít (?!trénink)|Volný trénink/,'consent kept after reload');
 // Offline jde jen se service workerem, který už stránku řídí.
 await p.evaluate(()=>Promise.race([navigator.serviceWorker.ready,new Promise((_,r)=>setTimeout(()=>r(new Error('service worker se nezaregistroval')),20000))]));
 if(!await p.evaluate(()=>!!navigator.serviceWorker.controller)){ await p.reload(); await sem(); }
 await ctx.setOffline(true); await p.reload(); await sem();
 await see(/Začít (?!trénink)|Volný trénink/,'offline reload');
 if(errs.length) throw new Error('page errors: '+errs.join('; '));
 await browser.close();
})().catch(async e=>{console.error('FAIL',e.message);await browser?.close().catch(()=>{});process.exit(1)});
