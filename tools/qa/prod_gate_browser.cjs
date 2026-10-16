// PRODUCTION web export check (build/web, preset "Web"): no QA hook/banner/button even with a save that has Episodes 1-2 cleared AND settings.dev_unlock=true; tapping where the QA button sits starts nothing.
// usage: PORT=8793 node prod_gate_browser.cjs OUTDIR  (serve build/web first)
const { chromium } = require('/home/user/my-app/node_modules/@playwright/test');
const crypto=require('crypto'); const fs=require('fs');
const OUT=process.argv[2]; const sleep=ms=>new Promise(r=>setTimeout(r,ms)); const PORT=process.env.PORT||8793;
const idb=`async (op)=>{ const db=await new Promise((res,rej)=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});
 const tx=db.transaction('FILE_DATA',op.write?'readwrite':'readonly'); const st=tx.objectStore('FILE_DATA');
 if(op.write){ await new Promise((res,rej)=>{const r=st.put({timestamp:new Date(),mode:33206,contents:new Uint8Array(op.bytes)},op.key);r.onsuccess=()=>res();r.onerror=()=>rej(r.error)}); return 'ok'; }
 return await new Promise((res)=>{const r=st.getAllKeys();r.onsuccess=()=>res(r.result)}); }`;
(async()=>{
 fs.mkdirSync(OUT,{recursive:true});
 const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome',args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx=await b.newContext({viewport:{width:1280,height:720}}); const p=await ctx.newPage();
 const errs=[]; p.on('pageerror',e=>errs.push(e.message)); p.on('console',m=>{if(m.type()==='error')errs.push(m.text())});
 const res=[]; const ok=(n,c,d='')=>{res.push({n,c:!!c,d});console.log((c?'PASS':'FAIL')+': '+n+(d?'  ('+d+')':''))};
 await p.goto(`http://localhost:${PORT}/index.html`); await sleep(9000);
 await p.mouse.click(640,480); await sleep(2500);               // onboarding -> home, creates the save
 await p.keyboard.press('Escape'); await sleep(500);
 const keys=await p.evaluate(`(${idb})({})`); 
 const saveKey=keys.find(k=>k.endsWith('soul_ascension_v1.json')); ok('The browser build wrote a save file',!!saveKey,saveKey);
 await p.goto(`http://localhost:${PORT}/index.png`); await sleep(500);   // same origin, game not running, so it cannot overwrite my edit
 // read the existing save from IDB, edit the payload, re-sign it
 const raw=await p.evaluate(`(async()=>{const db=await new Promise((res)=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>res(r.result)});const st=db.transaction('FILE_DATA').objectStore('FILE_DATA');return await new Promise(res=>{const r=st.get(${JSON.stringify(saveKey)});r.onsuccess=()=>res(Array.from(r.result.contents))})})()`);
 const env=JSON.parse(Buffer.from(raw).toString()); const data=JSON.parse(env.payload);
 data.completed=['1-1','1-2']; data.settings.dev_unlock=true; data.mission_progress={'1-3':{intro:true,zone:'workshop',clues:['tx_1']}};
 const payload=JSON.stringify(data); const sealed=JSON.stringify({schema:1,payload,sha256:crypto.createHash('sha256').update(payload).digest('hex')});
 ok('Seeded save: Episodes 1-2 cleared, dev_unlock=true, saved 1-3 progress',true);
 await p.evaluate(`(${idb})(${JSON.stringify({write:true,key:saveKey,bytes:Array.from(Buffer.from(sealed))})})`);
 await p.goto(`http://localhost:${PORT}/index.html`); await sleep(9000);
 await p.screenshot({path:`${OUT}/gate_home.png`});
 ok('Production build has no QA state hook (window.__qa / __qa_f undefined)',(await p.evaluate(()=>[typeof window.__qa,typeof window.__qa_f].join()))==='undefined,undefined');
 await p.mouse.click(112,637); await sleep(1200);            // MISSIONS
 await p.screenshot({path:`${OUT}/gate_missions.png`});
 await p.mouse.click(444,535); await sleep(2500);            // where the QA button sits in the QA flavor
 await p.screenshot({path:`${OUT}/gate_after_qa_tap.png`});
 await p.keyboard.press('Escape'); await sleep(500);
 await p.screenshot({path:`${OUT}/gate_after.png`});
 const real=errs.filter(m=>!/Failed to load resource/.test(m)); ok('No page errors (a failed static-resource load such as the favicon is ignored)',real.length===0,JSON.stringify(real).slice(0,200));
 await b.close(); fs.writeFileSync(`${OUT}/gate_results.json`,JSON.stringify(res,null,1));
})();
