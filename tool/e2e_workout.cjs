// E2E: souhlas → trénink → potvrzení série → pauza → dokončení → reload → opakování za 1 klik.
const {chromium}=require(process.env.PLAYWRIGHT_CORE || 'playwright-core');
(async()=>{
 const ctx=await chromium.launchPersistentContext(process.argv[2],{executablePath:process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,viewport:{width:400,height:800}});
 const errs=[]; const p=await ctx.newPage(); p.on('pageerror',e=>errs.push(String(e)));
 const sem=async()=>{await p.waitForSelector('flt-semantics-placeholder',{state:'attached',timeout:20000}); await p.evaluate(()=>document.querySelector('flt-semantics-placeholder').click()); await p.waitForTimeout(800);};
 const txt=()=>p.evaluate(()=>[...document.querySelectorAll('flt-semantics')].map(e=>e.getAttribute('aria-label')||e.textContent).filter(Boolean).join(' | '));
 const wait=ms=>p.waitForTimeout(ms);
 const check=(ok,msg)=>{if(!ok) throw new Error(msg); console.log('ok:',msg);};
 await p.goto('http://localhost:8099/'); await sem();
 await p.getByRole('checkbox',{name:/Souhlasím/}).click();
 await p.getByRole('radio',{name:/18 let nebo/}).click(); await wait(300);
 await p.getByRole('button',{name:'Pokračovat'}).click(); await wait(1200);

 // první trénink
 await p.getByRole('button',{name:/Začít trénink/}).click(); await wait(800);
 await p.getByRole('button',{name:/Přidat cvik/}).click(); await wait(800);
 await p.keyboard.type('bench'); await wait(500);
 await p.getByRole('button',{name:/^Bench press/}).first().click(); await wait(800);
 const boxes=p.getByRole('textbox');
 await boxes.nth(0).click(); await p.keyboard.type('77,5');
 await boxes.nth(1).click(); await p.keyboard.type('8'); await wait(300);
 await p.getByRole('button',{name:'Potvrdit sérii'}).click(); await wait(500);
 check(await p.getByRole('button',{name:'Zrušit potvrzení'}).count()===1,'set confirmed');
 check(/Pauza [12]:\d\d/.test(await txt()),'rest timer started');
 await p.getByRole('button',{name:'+15'}).click(); await wait(300);
 check(/Pauza 2:1\d/.test(await txt()),'rest +15');
 await p.getByRole('button',{name:'Přeskočit'}).click(); await wait(500);
 check(!/Pauza/.test(await txt()),'rest skipped');
 await p.reload(); await sem(); await wait(500);
 check(/Pokračovat v tréninku/.test(await txt()),'active workout survives reload');
 await p.getByRole('button',{name:/Pokračovat v tréninku/}).click(); await wait(800);
 check(await p.getByRole('button',{name:'Zrušit potvrzení'}).count()===1,'confirmed set survives reload');
 await p.getByRole('button',{name:'Dokončit'}).click(); await wait(1200);
 check(/Poslední trénink/.test(await txt()),'finished workout on home');

 // druhý trénink: předvyplněno, 1 klik
 await p.reload(); await sem(); await wait(500);
 await p.getByRole('button',{name:/Začít trénink/}).click(); await wait(800);
 await p.getByRole('button',{name:/Přidat cvik/}).click(); await wait(800);
 await p.getByRole('button',{name:/^Bench press/}).first().click(); await wait(800);
 check((await txt()).includes('77,5×8'),'last time shown');
 await p.getByRole('button',{name:'Potvrdit sérii'}).click(); await wait(500);
 check(await p.getByRole('button',{name:'Zrušit potvrzení'}).count()===1,'one tap logs same set');
 console.log('errors',errs);
 if(errs.length) process.exit(1);
 await ctx.close();
})().catch(e=>{console.error('FAIL',e.message);process.exit(1)});
