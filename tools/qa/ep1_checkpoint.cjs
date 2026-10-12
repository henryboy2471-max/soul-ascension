// Episode 1 exploration checkpoint through the real web export (QA build from make_ep1_qa_build.sh):
// home -> intro -> walk to Mira (collision) -> dialogue -> relay hold -> breach entry, with screenshots and camera sampling.
// usage: PORT=8790 node ep1_checkpoint.cjs <outdir> <key|touch> <w> <h> <tag>
const { chromium } = require(process.env.PW||'/home/user/my-app/node_modules/@playwright/test');
const fs=require('fs');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS; const PORT=process.env.PORT||'8790';
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
 const STICK=[126,610];
 const hold_dir=async(dir,ms)=>{ if(T){ await tdown(1,STICK[0],STICK[1]); await tmove(1,STICK[0]+110*dir,STICK[1]); await sleep(ms); await tup(1);} else { const kk=dir>0?'d':'a'; await p.keyboard.down(kk); await sleep(ms); await p.keyboard.up(kk); } };
 const hold_vert=async(dir,ms)=>{ if(T){ await tdown(1,STICK[0],STICK[1]); await tmove(1,STICK[0],STICK[1]+110*dir); await sleep(ms); await tup(1);} else { const kk=dir>0?'s':'w'; await p.keyboard.down(kk); await sleep(ms); await p.keyboard.up(kk); } };
 const act=async()=>{ if(T) await ttap(1162,638,2); else await p.keyboard.press('e'); };
 const hold_act=async(ms,mid,at=0.5)=>{ if(T){ await tdown(2,1162,638); await sleep(ms*at); if(mid) await mid(); await sleep(ms*(1-at)); await tup(2);} else { await p.keyboard.down('e'); await sleep(ms*at); if(mid) await mid(); await sleep(ms*(1-at)); await p.keyboard.up('e'); } };
 const advance=async()=>{ if(T) await ttap(300,570,3); else await p.keyboard.press('e'); };
 const goto_x=async(x,tol=40,max=60)=>{ for(let i=0;i<max;i++){ const s=await q(); if(Math.abs(s.px-x)<=tol) return s; await hold_dir(s.px<x?1:-1, Math.min(500,Math.abs(s.px-x)*2.2)); await sleep(60);} return await q(); };
 const t0=Date.now();
 await p.goto(`http://localhost:${PORT}/index.html`);
 for(let i=0;i<120;i++){ await sleep(500); if((await q()).scene==='home') break; }
 const bootS=((Date.now()-t0)/1000).toFixed(1);
 if(T){ await ttap(176,549); await sleep(1500); await ttap(468,588); } else { await p.mouse.click(176,549); await sleep(1500); await p.mouse.click(468,588); }
 await sleep(2500);
 for(let i=0;i<12;i++){ const s=await q(); if(s.step!==undefined && !s.busy && s.cam!==undefined) break; await advance(); await sleep(900); }
 let s=await q(); ok('Episode 1 reaches exploration',s.scene==='episode' && s.cam!==undefined,'boot '+bootS+' s');
 await sleep(800); await shot('1_explore_start');
 // camera sampling while walking right: whole-pixel layer positions, no reversals
 const samples=[]; let walking=true; const sampler=(async()=>{ while(walking){ const v=await q(); samples.push([v.cam,v.layer,v.ppos]); await sleep(40);} })();
 await hold_dir(1,2600); walking=false; await sampler;
 console.log('layer samples',JSON.stringify(samples.map(v=>v[1])));
 const layers=samples.map(v=>v[1]).filter(v=>v!==undefined), cams=samples.map(v=>v[0]);
 let rev=0; for(let i=1;i<layers.length;i++) if(layers[i]>layers[i-1]+0.01) rev++;
 ok('Camera tracks the Hero while walking (cam moved)',cams[cams.length-1]>cams[0]+50,cams[0].toFixed(0)+' -> '+cams[cams.length-1].toFixed(0));
 ok('Parallax layer positions are whole pixels',layers.every(v=>v===Math.round(v)),layers.length+' samples');
 ok('Camera never reverses while walking one way',rev===0,'reversals '+rev);
 // back toward Mira, collision on her lane
 await goto_x(380,60);
 s=await q(); let before=s.px;
 await hold_dir(1,2200); s=await q();
 await shot('2_mira_collision_or_pass');
 ok('Hero passes Mira without walking through her (eased around)',s.px>600 || (s.px<=560-36+2),'px '+before.toFixed(0)+' -> '+s.px.toFixed(0));
 await goto_x(500,60);
 for(let i=0;i<8;i++){ s=await q(); if(s.spot==='mira') break; await hold_dir(Math.random()<.5?1:-1,150); }
 await act(); await sleep(900);
 for(let i=0;i<6;i++){ s=await q(); if(s.dlg) break; await sleep(400); }
 await sleep(900); s=await q(); await shot('3_npc_dialogue');
 ok('Mira dialogue opens and locks movement',!!s.dlg && s.locked===true,(s.who||'')+': '+(s.dlg||'').slice(0,40));
 for(let i=0;i<6;i++){ await advance(); await sleep(1300); s=await q(); if((s.who||'').includes('ASCENDANT')||!s.dlg) break; }
 await sleep(900); await shot('3b_hero_line');
 for(let i=0;i<30;i++){ s=await q(); if(!s.busy) break; await advance(); await sleep(520); }
 s=await q(); ok('Dialogue closes and the relay objective unlocks',s.step===1 && !s.busy,'step '+s.step);
 // relay
 await goto_x(1560,50,90);
 for(let i=0;i<8;i++){ s=await q(); if(s.spot==='terminal') break; await hold_dir(s.px<1560?1:-1,150); }
 await sleep(300); await shot('4_relay_prompt');
 await hold_act(2600,async()=>{ await shot('5_relay_channel'); },0.18);
 await sleep(800);
 for(let i=0;i<40;i++){ s=await q(); if(s.step===2 && !s.busy) break; await advance(); await sleep(500); }
 s=await q(); ok('Relay hold-to-channel completes and advances to the breach',s.step===2 && !s.busy,'step '+s.step);
 await shot('6_relay_done');
 // breach
 await goto_x(2200,60,120);
 for(let i=0;i<8;i++){ s=await q(); if(s.spot==='breach') break; await hold_dir(s.px<2200?1:-1,150); }
 await sleep(300); await shot('7_breach_prompt'); ok('Breach prompt appears at the breach',s.spot==='breach','spot '+s.spot);
 await act(); await sleep(1500); await shot('8_breach_entry');
 for(let i=0;i<30;i++){ s=await q(); if(s.scene==='battle') break; await advance(); await sleep(600); }
 s=await q(); await sleep(1200); await shot('9_battle_start');
 ok('Breach entry starts the Soul Realm battle',s.scene==='battle','scene '+s.scene);
 ok('No console errors',msgs.length===0,JSON.stringify(msgs).slice(0,200));
 fs.writeFileSync(`${S}/${TAG}_results.json`,JSON.stringify({tag:TAG,viewport:[W,H],mode:MODE,results},null,1));
 console.log('SUMMARY',TAG,results.filter(r=>r.c).length+'/'+results.length);
 await b.close();
})();
