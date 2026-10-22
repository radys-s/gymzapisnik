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
 // Výběr cviku je vícenásobný: označit a potvrdit tlačítkem dole.
 const pick=async name=>{
  await p.getByRole('button',{name}).first().click();
  await p.getByRole('button',{name:'Přidat cvik'}).last().click();
 };
 // Flutter neposouvá stránku za Playwrightem: dokud prvek není vidět, posunout kolečkem.
 const tap=async(role,name)=>{
  // Řádek pod nadpisem sekce web někdy hlásí jako skupinu, ne tlačítko.
  let l=p.getByRole(role,{name}).first();
  await l.waitFor({state:'attached',timeout:5000}).catch(()=>{});
  if(role==='button'&&!(await p.getByRole(role,{name}).count())) l=p.getByRole('group',{name}).last();
  for(let i=0;i<12;i++){
   const box=await l.boundingBox({timeout:1500}).catch(()=>null);
   // Spodní lišta (~90 px) překrývá konec stránky.
   if(box&&box.y>=60&&box.y+box.height<=p.viewportSize().height-90) break;
   await p.mouse.move(200,400);
   await p.mouse.wheel(0,box&&box.y<40?-300:300);
   await p.waitForTimeout(250);
  }
  await l.click();
 };
 // Dlouhé stránky staví řádky až při posunu: posouvat, dokud text není na stránce.
 const scrollTo=async re=>{
  for(let i=0;i<15&&!re.test(await txt());i++){
   await p.mouse.move(200,400); await p.mouse.wheel(0,500); await p.waitForTimeout(300);
  }
 };
 // Klik, který se mohl ztratit při přestavbě sémantiky, zopakuje.
 const tapUntil=async(role,name,test,msg)=>{
  for(let i=0;i<5;i++){
   await tap(role,name);
   try { await see(test,msg,3000); return; } catch(_) {}
  }
  throw new Error(msg);
 };

 // První spuštění: uvítání (4 obrazovky, barva) a souhlas.
 const onboard=async()=>{
  await see(has(/Gym zápisník/),'welcome');
  for(let i=0;i<4;i++){ await tap('button','Pokračovat'); await p.waitForTimeout(400); }
  // Dotazník „Tvůj plán“ jde přeskočit.
  await see(has(/Tvůj plán/),'plan step');
  await tapUntil('button','Přeskočit',has(/Než začneš/),'consent');
  await tap('checkbox',/Souhlasím/);
  await tap('radio',/18 let nebo/);
  await tap('button','Pokračovat');
 };
 await p.goto('http://localhost:8099/'); await sem();
 await onboard();

 // první trénink
 await tap('button',/Začít trénink|Volný trénink/);
 await tap('button',/Přidat cvik/);
 await see(has(/Přidat cviky/),'picker open');
 await p.getByRole('textbox').last().click();
 await p.keyboard.type('bench');
 await see(t=>/Bench press/.test(t)&&!/Deadlift/.test(t),'picker search');
 await pick(/^Bench press/);
 await see(has(/Potvrdit sérii/),'exercise added');
 // Pole série otevře list s velkými čísly; v něm se píše (kg je zaostřené).
 await tap('button',/Váha v kg, Série 1/);
 await see(has(/Hotovo/),'set sheet opened');
 const sheetBoxes=p.getByRole('textbox');
 const typeSheet=async(i,value)=>{
  for(let a=0;a<5;a++){
   await sheetBoxes.nth(i).click();
   const focused=await p.waitForFunction(()=>document.activeElement?.tagName==='INPUT',null,{timeout:2000}).then(()=>true,()=>false);
   if(!focused) continue;
   await p.keyboard.press('Control+A');
   await p.keyboard.type(value,{delay:30});
   if(await p.waitForFunction(v=>document.activeElement?.value===v,value,{timeout:2000}).then(()=>true,()=>false)) return;
  }
  throw new Error('typing into sheet field '+i+' failed');
 };
 // V listu jsou jediná textová pole na stránce: váha a opakování.
 await typeSheet(0,'77,5');
 await typeSheet(1,'8');
 await tap('button','Hotovo');
 await see(t=>!/Hotovo/.test(t),'set sheet closed');
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
 await see(has(/Tento týden 1 z/),'finished workout counts this week');

 // druhý trénink: předvyplněno, 1 klepnutí
 await p.reload(); await sem();
 await tap('button',/Začít trénink|Volný trénink/);
 await tap('button',/Přidat cvik/);
 await see(has(/Nedávné/),'recent exercises first');
 await pick(/^Bench press/);
 await see(has(/Minule 77,5 kg, 8 opakování/),'last time shown');
 await tapUntil('button','Potvrdit sérii',has(/Zrušit potvrzení/),'one tap logs same set');
 await tap('button','Dokončit');
 await see(has(/Stejně jako minule/),'second summary compares with first');
 await tap('button','Hotovo');
 await see(has(/Tento týden 2 z/),'week on home');
 // tělesná váha z řádku na domovské stránce
 // Domovská stránka je dlouhá a řádky se staví až při posunu.
 await scrollTo(/Tělesná váha/);
 await tap('button',/Tělesná váha/);
 await tap('button',/Zapsat váhu/);
 await p.waitForFunction(()=>document.activeElement?.tagName==='INPUT',null,{timeout:5000});
 await p.keyboard.type('80,5',{delay:30});
 await tap('button','Uložit');
 await see(has(/80,5 kg/),'bodyweight saved');
 await p.goBack();
 await see(has(/Cviky a rekordy/),'back home');
 await tap('button',/^Vše/);
 await see(has(/(Leden|Únor|Březen|Duben|Květen|Červen|Červenec|Srpen|Září|Říjen|Listopad|Prosinec) \d{4}/),'history grouped by month');
 await p.goBack();
 await tap('button',/Cviky a rekordy/);
 await see(has(/Cvičené/),'trained exercises on top');
 await tap('button',/^Bench press/);
 await see(t=>/Svaly/.test(t)&&/Technika/.test(t),'exercise screen with technique');
 await scrollTo(/Odhad 1RM v čase/);
 await see(t=>/Osobní rekordy/.test(t)&&/Odhad 1RM v čase/.test(t),'exercise detail with chart');
 // program: výběr, dnešní den a trénink s návrhem kouče
 await p.goBack(); await p.goBack();
 await scrollTo(/Program/);
 await tap('button',/^Program/);
 await scrollTo(/Push \/ Pull \/ Legs/);
 await tap('button',/Push \/ Pull \/ Legs/);
 await tap('button','Používat tento program');
 await see(has(/Tento program používáš/),'program active');
 await p.goBack(); await p.goBack();
 // Domov si pamatuje posun: zpátky nahoru k hlavní kartě.
 for(let i=0;i<6;i++){ await p.mouse.move(200,400); await p.mouse.wheel(0,-1500); await p.waitForTimeout(200); }
 await see(has(/Začít Push/),'today card for program');
 await tap('button',/Začít Push/);
 await see(t=>/přidej 2,5 kg|Drž|Poprvé/.test(t),'coach reason in workout');
 // nastavení: CSV a záloha se stáhnou, smazání dat, obnova ze souboru
 await p.goBack().catch(()=>{});
 await p.reload(); await sem();
 await tap('button','Nastavení');
 await see(has(/Pauza mezi sériemi/),'settings open');
 await scrollTo(/Co obsahuje Pro/);
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
 await tapUntil('button',/Smazat všechna data/,has(/Smazat všechna data\?/),'wipe confirm');
 await tap('button','Smazat vše');
 await onboard();
 await tapUntil('button','Nastavení',has(/Obnovit ze zálohy/),'settings after wipe');
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
 await p.mouse.wheel(0,1500);
 await tap('button',/^Vše/);
 await see(t=>(t.match(/Bench press/g)||[]).length>=2,'history restored');
 await see(has(/Hevy Push/),'hevy workout in history');
 console.log('errors',errs);
 if(errs.length) process.exit(1);
 await ctx.close();
})().catch(async e=>{
 console.error('FAIL',e.message.split(String.fromCharCode(10))[0]);
 if(page&&process.env.E2E_SHOT) await page.screenshot({path:process.env.E2E_SHOT}).catch(()=>{});
 if(page) console.error('page:',(await page.evaluate(()=>document.body.innerText+' || '+[...document.querySelectorAll('flt-semantics')].map(x=>x.getAttribute('aria-label')||x.textContent).filter(Boolean).join(' | ')).catch(()=>'')).slice(0,600));
 await context?.close().catch(()=>{});
 process.exit(1);
});
