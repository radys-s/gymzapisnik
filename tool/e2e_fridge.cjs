// E2E: AI kouč ledničky proti lokálnímu mock proxy (worker/dev/mock-server.mjs).
// Souhlas → Výživa → Co mám v ledničce → fotka přes výběr souboru → upozornění →
// seznam potravin → návrhy jídel → zápis do deníku → reload a seznam zůstal.
// Build: flutter build web --release --dart-define=AI_URL=http://localhost:8787
const {chromium}=require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
let ctx;
(async()=>{
 ctx=await chromium.launchPersistentContext(process.argv[2],{executablePath:process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:400,height:800}});
 const errs=[]; const p=await ctx.newPage(); p.on('pageerror',e=>errs.push(String(e)));
 const requests=[]; p.on('request',r=>{ if(r.url().includes('/v1/')) requests.push(r.method()+' '+new URL(r.url()).pathname); });
 const statuses=[]; p.on('response',r=>{ if(r.url().includes('/v1/') && r.request().method()==='POST') statuses.push(r.status()); });
 const txt=()=>p.evaluate(()=>[...document.querySelectorAll('flt-semantics')].map(e=>e.getAttribute('aria-label')||e.textContent).filter(Boolean).join(' | '));
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
  throw new Error(msg+'\n'+(await txt()));
 };
 const has=re=>t=>re.test(t);
 const tap=(role,name)=>p.getByRole(role,{name}).first().click();
 const tapUntil=async(role,name,test,msg)=>{
  for(let i=0;i<5;i++){
   await tap(role,name).catch(()=>{});
   try { await see(test,msg,3000); return; } catch(_) {}
  }
  throw new Error(msg);
 };

 // Skutečný JPEG pro výběr souboru: snímek prázdné stránky.
 const shot=await ctx.newPage(); await shot.setContent('<body style="background:#c84">lednička</body>');
 const jpeg=await shot.screenshot({type:'jpeg',quality:70}); await shot.close();

 await p.goto('http://localhost:8099/'); await sem();
 await tap('checkbox',/Souhlasím/);
 await tap('radio',/18 let nebo/);
 await tap('button','Pokračovat');

 await tapUntil('button',/^Výživa/,has(/Co mám v ledničce/),'nutrition page');
 await tapUntil('button',/Co mám v ledničce/,has(/Vyfotit/),'fridge page');

 const chooser=p.waitForEvent('filechooser',{timeout:15000});
 await tap('button','Z galerie');
 await see(has(/Než použiješ AI/),'one-time AI notice');
 await tap('button','Rozumím');
 await (await chooser).setFiles({name:'lednicka.jpg',mimeType:'image/jpeg',buffer:jpeg});
 await see(has(/Přidáno 4/),'4 items recognised',20000);
 await see(t=>/Vejce/.test(t)&&/6 ks/.test(t)&&/Tvaroh/.test(t),'items listed with amounts');

 await tap('button','10 min');
 await tapUntil('button','Navrhni jídlo',has(/Návrhy jídel/),'meal ideas page');
 await see(has(/Tvaroh s banánem/),'first meal card');
 await see(has(/Odhad podle tabulky potravin/),'macros from local food table');
 await tapUntil('button','Zapsat do deníku',has(/Přidat jídlo/),'food form opened');
 await tap('button','Uložit');
 await see(has(/Zapsáno: Tvaroh s banánem/),'meal logged');

 await p.reload(); await sem();
 await tapUntil('button',/kcal dnes/,has(/Tvaroh s banánem/),'logged meal survives reload');
 const logged=(await txt()).match(/Tvaroh s banánem/g).length;
 if(logged!==1) throw new Error('meal logged '+logged+' times');
 await tapUntil('button',/Co mám v ledničce/,has(/Vyfotit/),'fridge page again');
 await see(t=>/Vejce/.test(t)&&/Mléko/.test(t),'pantry survives reload');

 console.log('requests:',requests.join(', '));
 if(statuses.join()!=='200,200') throw new Error('AI HTTP statuses: '+statuses.join());
 const posts=requests.filter(r=>r.startsWith('POST'));
 if(posts.join()!=='POST /v1/fridge,POST /v1/meals') throw new Error('unexpected AI calls: '+posts.join());
 await ctx.setOffline(true);
 await p.reload(); await sem();
 await tapUntil('button',/kcal dnes/,has(/Tvaroh s banánem/),'diary available after offline reload');
 await tapUntil('button',/Co mám v ledničce/,has(/Vyfotit/),'pantry offline');
 await see(t=>/Vejce/.test(t)&&/Mléko/.test(t),'pantry retained offline');
 await tap('button','Navrhni jídlo');
 await see(has(/K AI se nepodařilo připojit/),'offline AI error leaves pantry available');
 if(errs.length) throw new Error('page errors: '+errs.join('\n'));
 console.log('E2E fridge OK');
 await ctx.close();
})().catch(async e=>{ console.error('FAIL:',e.message); await ctx?.close().catch(()=>{}); process.exit(1); });
