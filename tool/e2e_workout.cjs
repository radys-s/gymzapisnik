// E2E: souhlas → trénink → potvrzení série → pauza → reload → souhrn → druhý trénink
// (předvyplněno, 1 klepnutí) → historie → detail cviku s grafem → split a návrh kouče.
// Kontroly čekají s opakováním, ne pevnou dobu (stabilní i na vytíženém stroji).
const {chromium}=require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
let page, context;
(async()=>{
 const ctx=await chromium.launchPersistentContext(process.argv[2],{executablePath:process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:400,height:800}});
 context=ctx; const errs=[]; const p=await ctx.newPage(); page=p; p.on('pageerror',e=>errs.push(String(e)));
 const txt=()=>p.evaluate(()=>[...document.querySelectorAll('flt-semantics')].map(e=>e.getAttribute('aria-label')||e.textContent).filter(Boolean).join(' | '));
 // Zapne sémantiku Flutteru; klik před prvním snímkem se může ztratit, proto opakovat.
 const sem=async()=>{
  for(let i=0;i<20;i++){
   await p.waitForSelector('flt-semantics-placeholder',{state:'attached',timeout:20000}).catch(()=>{});
   await p.evaluate(()=>document.querySelector('flt-semantics-placeholder')?.click());
   await p.waitForTimeout(500);
   if(await p.evaluate(()=>document.querySelectorAll('flt-semantics').length>1)) return;
  }
  throw new Error('semantics did not start');
 };
 const see=async(test,msg,timeout=10000)=>{
  const end=Date.now()+timeout;
  while(Date.now()<end){ if(test(await txt())) { console.log('ok:',msg); return; } await p.waitForTimeout(200); }
  throw new Error(msg);
 };
 const has=re=>t=>re.test(t);
 const tap=(role,name)=>p.getByRole(role,{name}).first().click();

 await p.goto('http://localhost:8099/'); await sem();
 await tap('checkbox',/Souhlasím/);
 await tap('radio',/18 let nebo/);
 await tap('button','Pokračovat');

 // první trénink
 await tap('button',/Začít trénink/);
 await tap('button',/Přidat cvik/);
 await p.waitForTimeout(600);
 await p.keyboard.type('bench');
 await see(has(/Bench press/),'picker search');
 await tap('button',/^Bench press/);
 await see(has(/Potvrdit sérii/),'exercise added');
 const boxes=p.getByRole('textbox');
 await boxes.nth(0).click(); await p.keyboard.type('77,5');
 await boxes.nth(1).click(); await p.keyboard.type('8');
 await tap('button','Potvrdit sérii');
 await see(has(/Zrušit potvrzení/),'set confirmed');
 await see(has(/Pauza [12]:\d\d/),'rest timer started');
 await tap('button','+15');
 await see(has(/Pauza 2:\d\d/),'rest +15');
 await tap('button','Přeskočit');
 await see(t=>!/Pauza/.test(t),'rest skipped');
 await p.reload(); await sem();
 await see(has(/Pokračovat v tréninku/),'active workout survives reload');
 await tap('button',/Pokračovat v tréninku/);
 await see(has(/Zrušit potvrzení/),'confirmed set survives reload');
 await tap('button','Dokončit');
 await see(has(/Trénink hotový/),'summary shown');
 await see(has(/Poprvé/),'first time verdict');
 await tap('button','Hotovo');
 await see(has(/Poslední trénink/),'finished workout on home');

 // druhý trénink: předvyplněno, 1 klepnutí
 await p.reload(); await sem();
 await tap('button',/Začít trénink/);
 await tap('button',/Přidat cvik/);
 await see(has(/Nedávné/),'recent exercises first');
 await tap('button',/^Bench press/);
 await see(t=>t.includes('77,5×8'),'last time shown');
 await tap('button','Potvrdit sérii');
 await see(has(/Zrušit potvrzení/),'one tap logs same set');
 await tap('button','Dokončit');
 await see(has(/Stejně jako minule/),'second summary compares with first');
 await tap('button','Hotovo');
 await tap('tab',/Historie/);
 await see(has(/(Leden|Únor|Březen|Duben|Květen|Červen|Červenec|Srpen|Září|Říjen|Listopad|Prosinec) \d{4}/),'history grouped by month');
 await tap('tab',/Cviky/);
 await see(has(/Cvičené/),'trained exercises on top');
 await tap('button',/^Bench press/);
 await see(t=>/Osobní rekordy/.test(t)&&/Odhad 1RM v čase/.test(t),'exercise detail with chart');
 // split: výběr, dnešní den a trénink s návrhem kouče
 await p.goBack().catch(()=>{});
 await tap('tab',/Domů/);
 await tap('button',/Vyber si split/);
 await tap('button',/Push \/ Pull \/ Legs/);
 await see(has(/Dnes: Push/),'today card for split');
 await tap('button',/Začít Push/);
 await see(t=>/přidej 2,5 kg|Drž|Poprvé/.test(t),'coach reason in workout');
 console.log('errors',errs);
 if(errs.length) process.exit(1);
 await ctx.close();
})().catch(async e=>{
 console.error('FAIL',e.message.split(String.fromCharCode(10))[0]);
 if(page) console.error('page:',(await page.evaluate(()=>document.body.innerText+' || '+[...document.querySelectorAll('flt-semantics')].map(x=>x.getAttribute('aria-label')||x.textContent).filter(Boolean).join(' | ')).catch(()=>'')).slice(0,600));
 await context?.close().catch(()=>{});
 process.exit(1);
});
