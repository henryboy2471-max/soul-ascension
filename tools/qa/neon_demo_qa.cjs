// Browser QA for the 2.5D Neon District demo (web build, ?demo=neon&qa=1): four-direction movement, collision, camera, NPC dialogue, touch + keyboard.
// usage: node neon_demo_qa.cjs <outdir> <key|touch> <w> <h> <tag>   (serves from http://localhost:$PORT)
const { chromium } = require(process.env.PW_MODULE || '/home/user/my-app/node_modules/@playwright/test');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS; const PORT=process.env.PORT||'8796';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const k=Math.min(W/1280,H/720), ox=(W-1280*k)/2, oy=(H-720*k)/2; const G=(gx,gy)=>({x:ox+gx*k,y:oy+gy*k});
const T=MODE==='touch';
(async()=>{
 const b = await chromium.launch({executablePath:process.env.CHROME||'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx = await b.newContext(T?{viewport:{width:W,height:H},hasTouch:true,isMobile:true,deviceScaleFactor:2}:{viewport:{width:W,height:H}});
 const p = await ctx.newPage(); const cdp=T?await ctx.newCDPSession(p):null;
 const msgs=[]; p.on('console',m=>{ if(m.type()==='error') msgs.push(m.text()) }); p.on('pageerror',e=>msgs.push('PAGEERR '+e.message));
 const q=async()=>await p.evaluate(()=>window.__qa||{});
 let n=0; const shot=async(nm)=>{ await p.screenshot({path:`${S}/nd_${TAG}_${String(++n).padStart(2,'0')}_${nm}.png`}); console.log('shot',nm); };
 const active=new Map();
 const send=async(type)=>{ await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:[...active.entries()].map(([id,pt])=>({x:pt.x,y:pt.y,id}))}); };
 const tdown=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchStart'); };
 const tmove=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchMove'); };
 const tup=async(id)=>{ active.delete(id); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[...active.entries()].map(([i,pt])=>({x:pt.x,y:pt.y,id:i}))}); };
 const STICK=[126,610];
 const KEYS={right:'d',left:'a',down:'s',up:'w'}; const VEC={right:[1,0],left:[-1,0],down:[0,1],up:[0,-1]};
 const hold=async(dir,ms)=>{ if(T){ await tdown(1,STICK[0],STICK[1]); await tmove(1,STICK[0]+110*VEC[dir][0],STICK[1]+110*VEC[dir][1]); await sleep(ms); await tup(1); } else { await p.keyboard.down(KEYS[dir]); await sleep(ms); await p.keyboard.up(KEYS[dir]); } await sleep(150); };
 const act=async()=>{ if(T){ await tdown(2,1162,638); await sleep(90); await tup(2);} else await p.keyboard.press('e'); await sleep(200); };
 const advance=async()=>{ if(T){ await tdown(3,300,570); await sleep(80); await tup(3);} else await p.keyboard.press('e'); await sleep(250); };
 const results=[]; const check=(name,ok,extra='')=>{ results.push({name,ok}); console.log((ok?'PASS':'FAIL')+': '+name+' '+extra); };
 await p.goto(`http://localhost:${PORT}/index.html?demo=neon&qa=1`);
 let st={}; for(let i=0;i<160;i++){ await sleep(500); st=await q(); if(st.scene==='demo') break; }
 check('Demo starts from the URL flag',st.scene==='demo',JSON.stringify({scene:st.scene,where:st.where}));
 for(let i=0;i<40;i++){ st=await q(); if(!st.locked&&!st.dlg) break; await advance(); await sleep(400); }
 st=await q(); check('Opening cinematic ends and control returns',!st.locked);
 await shot('start');
 // closed-loop helpers: traffic and pedestrians are random, so aim by reading the state instead of timing blindly
 const gotoZ=async(z)=>{ for(let i=0;i<24;i++){ const c=await q(); if(Math.abs(c.pz-z)<0.035) return; await hold(c.pz<z?'down':'up',Math.min(500,Math.abs(c.pz-z)*264/150*1000+60)); } };
 const gotoX=async(x)=>{ for(let i=0;i<40;i++){ const c=await q(); if(Math.abs(c.px-x)<25) return; await hold(c.px<x?'right':'left',Math.min(700,Math.abs(c.px-x)/235*1000+60)); } };
 await gotoZ(0.36); st=await q();
 await hold('left',1100); st=await q();
 await hold('right',700); let s2=await q(); check('Move right: x increases and Echo faces right',s2.px>st.px+60&&s2.dir==='right',JSON.stringify({dx:Math.round(s2.px-st.px),dir:s2.dir}));
 await hold('left',700); let s3=await q(); check('Move left: x decreases and Echo faces left',s3.px<s2.px-60&&s3.dir==='left',JSON.stringify({dx:Math.round(s3.px-s2.px),dir:s3.dir}));
 await hold('up',300); let s4=await q(); check('Move up (away): depth decreases and back view shows',s4.pz<s3.pz-0.03&&s4.dir==='up',JSON.stringify({dz:+(s4.pz-s3.pz).toFixed(3),dir:s4.dir}));
 await hold('down',400); let s5=await q(); check('Move down (toward camera): depth increases and front view shows',s5.pz>s4.pz+0.03&&s5.dir==='down',JSON.stringify({dz:+(s5.pz-s4.pz).toFixed(3),dir:s5.dir}));
 await shot('walk');
 // camera follows
 await gotoZ(0.36); await gotoX(300); await sleep(900); const c0=(await q()).cam; await gotoX(1150); await sleep(900); const c1=(await q()).cam; check('Camera tracks the player',c1>c0+300,JSON.stringify({cam0:Math.round(c0),cam1:Math.round(c1)}));
 // walk to Kofi's stall (x~560) and test collision with the stall
 await gotoZ(0.36); await gotoX(560); let cur=await q();
 for(let i=0;i<3;i++){ await hold('up',700); }
 cur=await q(); check('Stall blocks walking through it (z stays in front)',cur.pz>0.22,JSON.stringify({pz:+cur.pz.toFixed(3),spot:cur.spot}));
 check('Kofi becomes interactable at the stall',cur.spot==='kofi',JSON.stringify({spot:cur.spot}));
 await act(); await sleep(600); st=await q(); check('ACT opens a dialogue and locks movement',st.dlg&&st.locked); await shot('dialogue');
 for(let i=0;i<10;i++){ st=await q(); if(!st.dlg) break; await advance(); await sleep(300); }
 await sleep(900); st=await q(); check('Dialogue closes and control returns',!st.dlg&&!st.locked);
 const fps=(await q()).fps;
 console.log('FPS (software GL, not representative)',fps);
 check('Console clean',msgs.length===0,JSON.stringify(msgs.slice(0,3)));
 console.log('SUMMARY',JSON.stringify({passed:results.filter(r=>r.ok).length,failed:results.filter(r=>!r.ok).map(r=>r.name)}));
 await b.close();
})();
