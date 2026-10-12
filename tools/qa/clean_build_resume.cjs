// CLEAN web export (no QA hook), real input only: new save -> Episode 1 -> talk to Mira -> reload the page -> the mission card says RESUME and returns to the relay objective.
// Results are read from screenshots (no telemetry exists in this build) plus window.__qa being undefined.
// usage: PORT=8801 node clean_build_resume.cjs <outdir> <key|touch> <w> <h> <tag>
const { chromium } = require(process.env.PW||'/home/user/my-app/node_modules/@playwright/test');
const fs=require('fs');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS; const PORT=process.env.PORT||'8801';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const k=Math.min(W/1280,H/720), ox=(W-1280*k)/2, oy=(H-720*k)/2; const G=(gx,gy)=>({x:ox+gx*k,y:oy+gy*k});
const T=MODE==='touch';
(async()=>{
 fs.mkdirSync(S,{recursive:true});
 const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx = await b.newContext(T?{viewport:{width:W,height:H},hasTouch:true,isMobile:true,deviceScaleFactor:2}:{viewport:{width:W,height:H}});
 const p = await ctx.newPage(); const cdp=T?await ctx.newCDPSession(p):null;
 const msgs=[]; p.on('console',m=>{ if(m.type()==='error') msgs.push(m.text()) }); p.on('pageerror',e=>msgs.push('PAGEERR '+e.message));
 const shot=async(nm)=>{ await p.screenshot({path:`${S}/${TAG}_${nm}.png`}); console.log('shot',TAG+'_'+nm); };
 const tap=async(gx,gy)=>{ if(T){ const pt=G(gx,gy); await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:pt.x,y:pt.y,id:1}]}); await sleep(90); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]}); } else { await p.mouse.click(G(gx,gy).x,G(gx,gy).y); } };
 const walk=async(ms)=>{ if(T){ const st=G(126,610), m=G(236,610); await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:st.x,y:st.y,id:1}]}); await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:m.x,y:m.y,id:1}]}); await sleep(ms); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]}); } else { await p.keyboard.down('d'); await sleep(ms); await p.keyboard.up('d'); } };
 const act=async()=>{ if(T) await tap(1162,638); else await p.keyboard.press('e'); };
 const adv=async()=>{ if(T) await tap(300,570); else await p.keyboard.press('e'); };
 await p.goto(`http://localhost:${PORT}/index.html`); await sleep(9000);
 console.log('qa hook absent:',(await p.evaluate(()=>typeof window.__qa))==='undefined');
 await tap(640,480); await sleep(2500);          // onboarding -> mission card opens
 await tap(468,588); await sleep(3500);          // BEGIN EPISODE 1
 for(let i=0;i<14;i++){ await adv(); await sleep(900); }
 await sleep(800); await shot('1_explore_fresh');
 await walk(1500); await sleep(500); await shot('2_near_mira');
 await act(); await sleep(1200);
 for(let i=0;i<9;i++){ await adv(); await sleep(800); }
 await sleep(1000); await shot('3_after_mira_talk');
 await sleep(3500);                               // let the browser finish saving
 await p.reload(); await sleep(9000);
 await shot('4_reloaded_home');
 await tap(176,549); await sleep(1500); await shot('5_mission_card_resume');
 await tap(468,588); await sleep(3000); await shot('6_resumed_in_district');
 console.log('console errors:',JSON.stringify(msgs));
 await b.close();
})();
