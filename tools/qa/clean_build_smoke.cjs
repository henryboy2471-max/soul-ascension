// Smoke test of the CLEAN web export (no QA hook): boots, confirms window.__qa is absent, opens Settings, starts Episode 1 with real input only, walks, screenshots.
// usage: PORT=8793 node clean_build_smoke.cjs <outdir> <key|touch> <w> <h> <tag>
const { chromium } = require(process.env.PW||'/home/user/my-app/node_modules/@playwright/test');
const fs=require('fs');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS; const PORT=process.env.PORT||'8793';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const k=Math.min(W/1280,H/720), ox=(W-1280*k)/2, oy=(H-720*k)/2; const G=(gx,gy)=>({x:ox+gx*k,y:oy+gy*k});
const T=MODE==='touch'; const results=[]; const ok=(n,c,d='')=>{ results.push({n,c:!!c,d}); console.log((c?'PASS':'FAIL')+': '+n+(d?'  ('+d+')':'')); };
(async()=>{
 fs.mkdirSync(S,{recursive:true});
 const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx = await b.newContext(T?{viewport:{width:W,height:H},hasTouch:true,isMobile:true,deviceScaleFactor:2}:{viewport:{width:W,height:H}});
 const p = await ctx.newPage(); const cdp=T?await ctx.newCDPSession(p):null;
 const msgs=[]; p.on('console',m=>{ if(m.type()==='error') msgs.push(m.text()) }); p.on('pageerror',e=>msgs.push('PAGEERR '+e.message));
 const shot=async(nm)=>{ await p.screenshot({path:`${S}/${TAG}_${nm}.png`}); console.log('shot',TAG+'_'+nm); };
 const tap=async(gx,gy)=>{ if(T){ const pt=G(gx,gy); await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:pt.x,y:pt.y,id:1}]}); await sleep(90); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]}); } else { await p.mouse.click(G(gx,gy).x,G(gx,gy).y); } };
 const t0=Date.now();
 await p.goto(`http://localhost:${PORT}/index.html`);
 await sleep(9000);
 // the clean build never defines the QA state object
 ok('Clean build has no QA telemetry (window.__qa undefined)', (await p.evaluate(()=>typeof window.__qa))==='undefined');
 // first launch shows onboarding; pick through it if present
await shot('0_first_screen');
 await tap(640,480); await sleep(2500);
 await shot('1_home_after_onboarding');
 await tap(911,597); await sleep(900);
 await shot('1b_home_modal_closed');
 await tap(1180,53); await sleep(1200);
 await shot('2_settings');
 await tap(1180,53); await sleep(300); await p.keyboard.press('Escape'); await sleep(500);
 // reload: the save must survive (no onboarding again)
 await p.reload(); await sleep(9000);
 await shot('3_after_reload_home');
 // start Episode 1 with real input
 await tap(176,549); await sleep(1500); await shot('4_mission_screen');
 await tap(468,588); await sleep(3500); await shot('5_title_card_or_intro');
 for(let i=0;i<14;i++){ if(T) await tap(300,570); else await p.keyboard.press('e'); await sleep(900); }
 await sleep(1000); await shot('6_explore');
 if(T){ const st=G(126,610), m=G(236,610); await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:st.x,y:st.y,id:1}]}); await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:m.x,y:m.y,id:1}]}); await sleep(1800); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]}); } else { await p.keyboard.down('d'); await sleep(1800); await p.keyboard.up('d'); }
 await sleep(500); await shot('7_explore_walked');
 ok('No console errors',msgs.length===0,JSON.stringify(msgs).slice(0,200));
 await b.close();
 fs.writeFileSync(`${S}/${TAG}_clean_results.json`,JSON.stringify({tag:TAG,results},null,1));
})();
