// Episode 1 resume through the real web export (QA-hook build): play to Mira, reload the page, resume; relay, reload, resume; pay for the fight, reload, resume without a second charge.
// usage: PORT=8800 node ep1_resume.cjs <outdir> <key|touch> <w> <h> <tag>
const { chromium } = require(process.env.PW||'/home/user/my-app/node_modules/@playwright/test');
const fs=require('fs');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS; const PORT=process.env.PORT||'8800';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const k=Math.min(W/1280,H/720), ox=(W-1280*k)/2, oy=(H-720*k)/2; const G=(gx,gy)=>({x:ox+gx*k,y:oy+gy*k});
const T=MODE==='touch'; const results=[]; const ok=(n,c,d='')=>{ results.push({n,c:!!c,d}); console.log((c?'PASS':'FAIL')+': '+n+(d?'  ('+d+')':'')); };
(async()=>{
 fs.mkdirSync(S,{recursive:true});
 const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx = await b.newContext(T?{viewport:{width:W,height:H},hasTouch:true,isMobile:true,deviceScaleFactor:2}:{viewport:{width:W,height:H}});
 const p = await ctx.newPage(); const cdp=T?await ctx.newCDPSession(p):null;
 const msgs=[]; p.on('console',m=>{ if(m.type()==='error') msgs.push(m.text()) }); p.on('pageerror',e=>msgs.push('PAGEERR '+e.message));
 const q=async()=>await p.evaluate(()=>window.__qa||{});
 const shot=async(nm)=>{ await p.screenshot({path:`${S}/${TAG}_${nm}.png`}); console.log('shot',TAG+'_'+nm); };
 const active=new Map();
 const send=async(type)=>{ await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:[...active.entries()].map(([id,pt])=>({x:pt.x,y:pt.y,id}))}); };
 const tdown=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchStart'); };
 const tmove=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchMove'); };
 const tup=async(id)=>{ active.delete(id); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[...active.entries()].map(([i,pt])=>({x:pt.x,y:pt.y,id:i}))}); };
 const ttap=async(gx,gy,id=1,ms=80)=>{ await tdown(id,gx,gy); await sleep(ms); await tup(id); };
 const click=async(gx,gy)=>{ if(T) await ttap(gx,gy); else await p.mouse.click(G(gx,gy).x,G(gx,gy).y); };
 const STICK=[126,610];
 const hold_dir=async(dir,ms)=>{ if(T){ await tdown(1,STICK[0],STICK[1]); await tmove(1,STICK[0]+110*dir,STICK[1]); await sleep(ms); await tup(1);} else { const kk=dir>0?'d':'a'; await p.keyboard.down(kk); await sleep(ms); await p.keyboard.up(kk); } };
 const act=async()=>{ if(T) await ttap(1162,638,2); else await p.keyboard.press('e'); };
 const hold_act=async(ms)=>{ if(T){ await tdown(2,1162,638); await sleep(ms); await tup(2);} else { await p.keyboard.down('e'); await sleep(ms); await p.keyboard.up('e'); } };
 const advance=async()=>{ if(T) await ttap(300,570,3); else await p.keyboard.press('e'); };
 const goto_x=async(x,tol=40,max=90)=>{ for(let i=0;i<max;i++){ const s=await q(); if(Math.abs(s.px-x)<=tol) return s; await hold_dir(s.px<x?1:-1, Math.min(500,Math.abs(s.px-x)*2.2)); await sleep(60);} return await q(); };
 const waitScene=async(sc,ms=60000)=>{ const t=Date.now(); while(Date.now()-t<ms){ if((await q()).scene===sc) return true; await sleep(500);} return false; };
 const boot=async()=>{ await p.goto(`http://localhost:${PORT}/index.html`); await waitScene('home',90000); await sleep(600); };
 const reload=async()=>{ await sleep(3500); /* let the browser save (IndexedDB) finish */ await p.reload(); await waitScene('home',90000); await sleep(800); };
 const openEpisode=async(label)=>{ await click(176,549); await sleep(1500); await shot(label+'_mission_card'); await click(468,588); await sleep(2500); };
 const waitExplore=async(ms=15000)=>{ const t=Date.now(); while(Date.now()-t<ms){ const s=await q(); if(s.cam!==undefined) return s; await sleep(400);} return await q(); };
 await boot();
 const e0=(await q()).energy;
 // ---- start Episode 1, skip the intro, talk to Mira
 await openEpisode('1_fresh');
 for(let i=0;i<12;i++){ const s=await q(); if(s.cam!==undefined && !s.busy) break; await advance(); await sleep(900); }
 let s=await waitExplore(); ok('Fresh start reaches exploration (step 0)',s.cam!==undefined && s.step===0);
 await goto_x(500,60);
 for(let i=0;i<8;i++){ s=await q(); if(s.spot==='mira') break; await hold_dir(Math.random()<.5?1:-1,150); }
 await act(); await sleep(900);
 for(let i=0;i<40;i++){ s=await q(); if(!s.busy && s.step===1) break; await advance(); await sleep(520); }
 s=await q(); ok('Mira conversation finished: relay objective active',s.step===1 && !s.busy,'step '+s.step);
 const px1=s.px;
 // ---- reload 1
 await reload(); s=await q();
 ok('After reload the game is on the home screen with energy unchanged',s.scene==='home' && s.energy===e0,'energy '+s.energy);
 await openEpisode('2_after_reload_mira');
 s=await waitExplore();
 ok('Resume #1: straight back in the district at the relay objective (no title card, no intro)',s.cam!==undefined && s.step===1 && s.scene==='episode',`step ${s.step}, px ${s.px&&s.px.toFixed(0)} (saved ${px1&&px1.toFixed(0)})`);
 ok('Resume #1: Hero restored near the saved position',Math.abs(s.px-px1)<120,'');
 await shot('3_resumed_at_relay_step');
 // ---- relay, reload 2
 await goto_x(1560,50,120);
 for(let i=0;i<8;i++){ s=await q(); if(s.spot==='terminal') break; await hold_dir(s.px<1560?1:-1,150); }
 await hold_act(2600); await sleep(800);
 for(let i=0;i<40;i++){ s=await q(); if(s.step===2 && !s.busy) break; await advance(); await sleep(500); }
 s=await q(); ok('Relay completed: breach objective active',s.step===2 && !s.busy,'step '+s.step);
 await reload();
 await openEpisode('4_after_reload_relay');
 s=await waitExplore();
 ok('Resume #2: back at the breach objective with the relay already rebooted',s.cam!==undefined && s.step===2 && s.scene==='episode',`step ${s.step}`);
 await shot('5_resumed_at_breach_step');
 // ---- enter breach (pay), reload mid-battle, resume
 await goto_x(2200,60,140);
 for(let i=0;i<8;i++){ s=await q(); if(s.spot==='breach') break; await hold_dir(s.px<2200?1:-1,150); }
 await act(); await sleep(1500);
 for(let i=0;i<30;i++){ s=await q(); if(s.scene==='battle') break; await advance(); await sleep(600); }
 s=await q(); ok('Breach entry starts the battle and pays 6 energy once',s.scene==='battle' && s.energy===e0-6,'energy '+s.energy);
 await sleep(1500); await shot('6_battle_paid');
 await reload(); s=await q();
 ok('Reload mid-battle: back at home, energy stays paid (no refund)',s.scene==='home' && s.energy===e0-6,'energy '+s.energy);
 await openEpisode('7_after_reload_battle');
 s=await waitExplore();
 ok('Resume #3: district at the open breach',s.cam!==undefined && s.step===2,'step '+s.step);
 await goto_x(2200,60,140);
 for(let i=0;i<8;i++){ s=await q(); if(s.spot==='breach') break; await hold_dir(s.px<2200?1:-1,150); }
 await sleep(400); await shot('8_breach_prompt_energy_paid');
 await act(); await sleep(1500);
 for(let i=0;i<30;i++){ s=await q(); if(s.scene==='battle') break; await advance(); await sleep(600); }
 s=await q(); ok('Resumed breach entry starts the battle WITHOUT charging energy again',s.scene==='battle' && s.energy===e0-6,'energy '+s.energy);
 await sleep(1200); await shot('9_battle_resumed');
 ok('No console errors',msgs.length===0,JSON.stringify(msgs).slice(0,200));
 fs.writeFileSync(`${S}/${TAG}_results.json`,JSON.stringify({tag:TAG,viewport:[W,H],mode:MODE,results},null,1));
 console.log('SUMMARY',TAG,results.filter(r=>r.c).length+'/'+results.length);
 await b.close();
})();
