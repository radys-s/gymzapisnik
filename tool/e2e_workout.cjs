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
 // Klik, který se mohl ztratit při přestavbě sémantiky, zopakuje.
 const tapUntil=async(role,name,test,msg)=>{
  for(let i=0;i<5;i++){
   await tap(role,name);
   try { await see(test,msg,3000); return; } catch(_) {}
  }
  throw new Error(msg);
 };

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
 await boxes.nth(1).waitFor();
 // Flutter otevře skryté <input> až po kliknutí; psát až když má fokus.
 const typeInto=async(i,value)=>{
  for(let a=0;a<5;a++){
   await boxes.nth(i).click();
   const focused=await p.waitForFunction(()=>document.activeElement?.tagName==='INPUT',null,{timeout:2000}).then(()=>true,()=>false);
   if(!focused) continue;
   await p.keyboard.press('Control+A');
   await p.keyboard.type(value,{delay:30});
   if(await p.waitForFunction(v=>document.activeElement?.value===v,value,{timeout:2000}).then(()=>true,()=>false)) return;
  }
  throw new Error('typing into field '+i+' failed');
 };
 await typeInto(0,'77,5');
 await typeInto(1,'8');
 await tapUntil('button','Potvrdit sérii',has(/Zrušit potvrzení/),'set confirmed');
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
 await see(has(/Dnes máš hotovo/),'mission: done today');

 // druhý trénink: předvyplněno, 1 klepnutí
 await p.reload(); await sem();
 await tap('button',/Začít trénink/);
 await tap('button',/Přidat cvik/);
 await see(has(/Nedávné/),'recent exercises first');
 await tap('button',/^Bench press/);
 await see(t=>t.includes('77,5×8'),'last time shown');
 await tapUntil('button','Potvrdit sérii',has(/Zrušit potvrzení/),'one tap logs same set');
 await tap('button','Dokončit');
 await see(has(/Stejně jako minule/),'second summary compares with first');
 await tap('button','Hotovo');
 await see(t=>/Tento týden/.test(t)&&/Progres: Bench press/.test(t),'dashboard on home');
 await p.mouse.wheel(0,2000);
 await tap('button',/Zapsat váhu/);
 await p.waitForFunction(()=>document.activeElement?.tagName==='INPUT',null,{timeout:5000});
 await p.keyboard.type('80,5',{delay:30});
 await tap('button','Uložit');
 await see(has(/80,5 kg/),'bodyweight saved on home');
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
 // nastavení: CSV a záloha se stáhnou, smazání dat, obnova ze souboru
 await p.goBack().catch(()=>{});
 await p.reload(); await sem();
 await tap('button','Nastavení');
 await see(t=>/Uložit zálohu/.test(t)&&/Cíl tréninků týdně/.test(t),'settings open');
 await tap('button',/Co obsahuje Pro/);
 await see(t=>/Kouč, který za tebou chodí/.test(t)&&/Zatím zdarma pro testery/.test(t),'pro overview');
 await tap('button','Zatím zdarma pro testery');
 await see(has(/Uložit zálohu/),'back in settings');
 const download=async name=>{
  const [d]=await Promise.all([p.waitForEvent('download',{timeout:10000}),tap('button',name)]);
  const file=await d.path(); return {name:d.suggestedFilename(),file,text:require('fs').readFileSync(file,'utf8')};
 };
 const csv=await download(/Export do Excelu/);
 if(!csv.text.startsWith('﻿Datum;')||!/Bench press;Hrudník;1;;77,5;8/.test(csv.text)) throw new Error('csv content '+csv.text.slice(0,200));
 console.log('ok: csv download',csv.name);
 const backup=await download(/Uložit zálohu/);
 if(JSON.parse(backup.text).workouts.length!==2) throw new Error('backup content');
 console.log('ok: backup download',backup.name);
 await tap('button',/Smazat všechna data/);
 await tap('button','Smazat vše');
 await see(has(/Než začneš/),'wipe returns to consent');
 await tap('checkbox',/Souhlasím/);
 await tap('radio',/18 let nebo/);
 await tap('button','Pokračovat');
 await tap('button','Nastavení');
 const [chooser]=await Promise.all([p.waitForEvent('filechooser',{timeout:10000}),tap('button',/Obnovit ze zálohy/)]);
 await chooser.setFiles(backup.file);
 await see(has(/Obnoveno: 2 tréninky/),'restore from file');
 const hevyFile=require('path').join(require('os').tmpdir(),'gz_e2e_hevy.csv');
 require('fs').writeFileSync(hevyFile,['title,start_time,end_time,description,exercise_title,superset_id,exercise_notes,set_index,set_type,weight_kg,reps,distance_km,duration_seconds,rpe','Hevy Push,"3 Mar 2026, 09:00","3 Mar 2026, 10:00",,Bench Press (Barbell),,,0,normal,60,10,,,'].join(String.fromCharCode(10)));
 for(const [expect_,label] of [[/Z Hevy přidáno: 1 trénink/,'hevy import'],[/Nic nového/,'hevy import idempotent']]){
  let hc;
  for(let a=0;a<4&&!hc;a++){
   [hc]=await Promise.all([p.waitForEvent('filechooser',{timeout:4000}).catch(()=>null),tap('button',/Import z Hevy/).catch(()=>{})]);
  }
  if(!hc) throw new Error('hevy file chooser did not open');
  await hc.setFiles(hevyFile);
  await see(has(expect_),label);
  await p.waitForTimeout(500);
 }
 await p.goBack().catch(()=>{});
 await tap('tab',/Historie/);
 await see(t=>(t.match(/Bench press/g)||[]).length>=2,'history restored');
 await see(has(/Hevy Push/),'hevy workout in history');
 console.log('errors',errs);
 if(errs.length) process.exit(1);
 await ctx.close();
})().catch(async e=>{
 console.error('FAIL',e.message.split(String.fromCharCode(10))[0]);
 if(page) console.error('page:',(await page.evaluate(()=>document.body.innerText+' || '+[...document.querySelectorAll('flt-semantics')].map(x=>x.getAttribute('aria-label')||x.textContent).filter(Boolean).join(' | ')).catch(()=>'')).slice(0,600));
 await context?.close().catch(()=>{});
 process.exit(1);
});
