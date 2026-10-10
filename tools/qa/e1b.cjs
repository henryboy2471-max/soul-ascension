// Episode 1 through the real web export (keyboard 1280x720 or touch): home -> intro -> explore objectives -> Soul Realm battle (Shade + Enforcer) -> ending -> rewards
const { chromium } = require('/home/user/my-app/node_modules/@playwright/test');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS; const PORT=process.env.PORT||'8771';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const k=Math.min(W/1280,H/720), ox=(W-1280*k)/2, oy=(H-720*k)/2; const G=(gx,gy)=>({x:ox+gx*k,y:oy+gy*k});
const T=MODE==='touch';
(async()=>{
 const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx = await b.newContext(T?{viewport:{width:W,height:H},hasTouch:true,isMobile:true,deviceScaleFactor:2}:{viewport:{width:W,height:H}});
 const p = await ctx.newPage(); const cdp=T?await ctx.newCDPSession(p):null;
 const msgs=[]; p.on('console',m=>{ if(m.type()==='error'||m.type()==='warning') msgs.push(m.type()+': '+m.text()) }); p.on('pageerror',e=>msgs.push('PAGEERR '+e.message));
 const q=async()=>await p.evaluate(()=>window.__qa||{});
 let n=0; const shot=async(nm)=>{ await p.screenshot({path:`${S}/e1_${TAG}_${String(++n).padStart(2,'0')}_${nm}.png`}); console.log('shot',nm); };
 const active=new Map();
 const send=async(type)=>{ await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:[...active.entries()].map(([id,pt])=>({x:pt.x,y:pt.y,id}))}); };
 const tdown=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchStart'); };
 const tmove=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchMove'); };
 const tup=async(id)=>{ active.delete(id); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[...active.entries()].map(([i,pt])=>({x:pt.x,y:pt.y,id:i}))}); };
 const ttap=async(gx,gy,id=1,ms=80)=>{ await tdown(id,gx,gy); await sleep(ms); await tup(id); };
 const STICK=[126,610];
 const walk=async(ms,dir=1)=>{ if(T){ await tdown(1,STICK[0],STICK[1]); await tmove(1,STICK[0]+110*dir,STICK[1]); await sleep(ms); await tup(1);} else { await p.keyboard.down(dir>0?'d':'a'); await sleep(ms); await p.keyboard.up(dir>0?'d':'a'); } };
 const act=async()=>{ if(T) await ttap(1162,638,2); else await p.keyboard.press('e'); };
 const hold=async(ms)=>{ if(T){ await tdown(2,1162,638); await sleep(ms); await tup(2);} else { await p.keyboard.down('e'); await sleep(ms); await p.keyboard.up('e'); } };
 const advance=async()=>{ if(T) await ttap(300,570,3); else await p.keyboard.press('e'); };
 await p.goto(`http://localhost:${PORT}/index.html`);
 for(let i=0;i<120;i++){ await sleep(500); if((await q()).scene==='home') break; }
 await shot('home');
 const e0=(await q());
 if(T){ await ttap(176,549); await sleep(1200); await ttap(468,588); } else { await p.mouse.click(176,549); await sleep(1200); await p.mouse.click(468,588); }
 await sleep(1500);
 for(let i=0;i<10;i++){ await advance(); await sleep(900); }
 await shot('explore_start');
 const stepsSeen=new Set();
 for(let c=0;c<400;c++){
  const s=await q(); stepsSeen.add(s.step);
  if(s.scene==='battle') break;
  if(s.busy){ await advance(); await sleep(450); continue; }
  await walk(420); await act(); await sleep(380); await hold(2300); await sleep(200);
  if(c%25===24) await shot('explore_c'+c+'_step'+s.step);
 }
 let st=await q(); console.log('entered battle',JSON.stringify({scene:st.scene,energyBefore:e0.energy,energy:st.energy,steps:[...stepsSeen]}));
 const strike=T?[[1188,648],[1188,648],[1188,648],[1188,548],[876,548],[1188,648],[1188,648]]:['j','j','j','k','q','j','j'];
 const t0=Date.now(); const caps={};
 while(Date.now()-t0<480000){
  st=await q(); if(st.scene==='result') break;
  if(st.scene==='battle'){
   if(st.wave===1&&!caps.boss){ caps.boss=1; await shot('boss'); }
   if(st.phase===2&&!caps.p2){ caps.p2=1; await shot('boss_phase2'); }
   if(st.dead&&!caps.def&&st.wave===1){ caps.def=1; await shot('boss_defeat'); }
   if(st.intro>0){ await sleep(300); continue; }
   await walk(120,Math.random()<0.5?1:-1);
   for(const a of strike){ if(T) await ttap(a[0],a[1],2,60); else await p.keyboard.press(a); await sleep(70); }
  } else { await advance(); await sleep(600); }
 }
 st=await q(); console.log('result',JSON.stringify({scene:st.scene,gold:st.gold,xp:st.xp,level:st.level,energy:st.energy,completed:st.completed,codex:st.codex}));
 await sleep(900); await shot('rewards');
 console.log('CONSOLE',JSON.stringify(msgs));
 await b.close();
})();
