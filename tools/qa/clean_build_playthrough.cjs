// CLEAN web export (no QA hook), real player input only, one full Episode 1 smoke test:
// onboarding -> opening -> exploration -> Mira -> (page reload + RESUME) -> relay -> breach -> Soul Realm battle -> ending -> rewards -> reload -> save checked.
// With no in-game telemetry the script reads the game's own save file out of the browser's IndexedDB to know where the player is and to check the results.
// usage: PORT=8810 node clean_build_playthrough.cjs <outdir> <key|touch> <w> <h> <tag>
const { chromium } = require(process.env.PW||'/home/user/my-app/node_modules/@playwright/test');
const fs=require('fs');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS; const PORT=process.env.PORT||'8810';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const k=Math.min(W/1280,H/720), ox=(W-1280*k)/2, oy=(H-720*k)/2; const G=(gx,gy)=>({x:ox+gx*k,y:oy+gy*k});
const T=MODE==='touch'; const results=[]; const ok=(n,c,d='')=>{ results.push({n,c:!!c,d}); console.log((c?'PASS':'FAIL')+': '+n+(d?'  ('+d+')':'')); };
const KEY='/userfs/godot/app_userdata/SOUL ASCENSION/soul_ascension_v1.json';
(async()=>{
 fs.mkdirSync(S,{recursive:true});
 const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx = await b.newContext(T?{viewport:{width:W,height:H},hasTouch:true,isMobile:true,deviceScaleFactor:2}:{viewport:{width:W,height:H}});
 const p = await ctx.newPage(); const cdp=T?await ctx.newCDPSession(p):null;
 const msgs=[]; p.on('console',m=>{ if(m.type()==='error') msgs.push(m.text()) }); p.on('pageerror',e=>msgs.push('PAGEERR '+e.message));
 const shots={}; const shot=async(nm)=>{ if(shots[nm]) return; shots[nm]=1; await p.screenshot({path:`${S}/${TAG}_${nm}.png`}); console.log('shot',TAG+'_'+nm); };
 const readSave=async()=>{ try{ return await p.evaluate(async(KEY)=>{ const db=await new Promise((res,rej)=>{const q=indexedDB.open('/userfs'); q.onsuccess=()=>res(q.result); q.onerror=()=>rej(q.error);});
   const v=await new Promise(res=>{const q=db.transaction('FILE_DATA','readonly').objectStore('FILE_DATA').get(KEY); q.onsuccess=()=>res(q.result);}); db.close();
   if(!v||!v.contents) return null; const env=JSON.parse(new TextDecoder().decode(v.contents)); return JSON.parse(env.payload); },KEY);}catch(e){ return null; } };
 const ring=[]; let recording=true; const recorder=(async()=>{ while(recording){ try{ const buf=await p.screenshot(); ring.push(buf); if(ring.length>10) ring.shift(); }catch(e){} await sleep(250);} })();
 const dumpEvent=(name)=>{ const dir=`${S}/events/${TAG}_${name}`; fs.mkdirSync(dir,{recursive:true}); ring.slice().forEach((b,i)=>fs.writeFileSync(`${dir}/f${String(i).padStart(2,'0')}.png`,b)); console.log('event',name,'frames',ring.length); };
 const active=new Map();
 const send=async(type)=>{ await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:[...active.entries()].map(([id,pt])=>({x:pt.x,y:pt.y,id}))}); };
 const tdown=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchStart'); };
 const tmove=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchMove'); };
 const tup=async(id)=>{ active.delete(id); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[...active.entries()].map(([i,pt])=>({x:pt.x,y:pt.y,id:i}))}); };
 const ttap=async(gx,gy,id=1,ms=80)=>{ await tdown(id,gx,gy); await sleep(ms); await tup(id); };
 const click=async(gx,gy)=>{ if(T) await ttap(gx,gy); else await p.mouse.click(G(gx,gy).x,G(gx,gy).y); };
 const STICK=[126,610];
 const walk=async(ms,dir=1)=>{ if(T){ await tdown(1,STICK[0],STICK[1]); await tmove(1,STICK[0]+110*dir,STICK[1]); await sleep(ms); await tup(1);} else { const kk=dir>0?'d':'a'; await p.keyboard.down(kk); await sleep(ms); await p.keyboard.up(kk); } };
 const act=async()=>{ if(T) await ttap(1162,638,2); else await p.keyboard.press('e'); };
 const hold=async(ms,mid)=>{ if(T){ await tdown(2,1162,638); if(mid){ await sleep(600); await mid(); await sleep(Math.max(0,ms-600)); } else await sleep(ms); await tup(2);} else { await p.keyboard.down('e'); if(mid){ await sleep(600); await mid(); await sleep(Math.max(0,ms-600)); } else await sleep(ms); await p.keyboard.up('e'); } };
 const advance=async()=>{ if(T) await ttap(300,570,3); else await p.keyboard.press('e'); };
 const strikes=T?[[1188,648],[1188,648],[1188,648],[1188,548],[876,548],[1188,648],[1188,648]]:['j','j','j','k','q','j','j'];
 const mp=d=>((d&&d.mission_progress)||{})['1-1']||{};
 await p.goto(`http://localhost:${PORT}/index.html`); await sleep(9000);
 ok('Clean build: no QA hook (window.__qa undefined)',(await p.evaluate(()=>typeof window.__qa))==='undefined');
 await shot('01_first_launch');
 await click(640,480); await sleep(3000);        // onboarding -> mission card
 let d=await readSave(); ok('Fresh save written after onboarding',d&&d.onboarded===true&&d.gold===500&&d.energy===60,d&&('gold '+d.gold+' energy '+d.energy));
 await shot('02_mission_card_fresh');
 await click(468,588); await sleep(3500);
 for(let i=0;i<14;i++){ await advance(); await sleep(900); }
 await sleep(800); await shot('03_exploration_start');
 let reloaded=false, t0=Date.now(), cycles=0, mode='explore', lastStep=undefined, battleSeen=false;
 while(Date.now()-t0<2400000){
  d=await readSave(); const pr=mp(d);
  if(d && (d.completed||[]).includes('1-1')) { dumpEvent('completed'); break; }
  if(pr.step!==undefined && lastStep!==pr.step){ if(lastStep===0&&pr.step===1) dumpEvent('mira_done'); if(lastStep===1&&pr.step===2) dumpEvent('relay_done'); lastStep=pr.step; }
  if(pr.combat_run===true && !battleSeen){ battleSeen=true; dumpEvent('breach_entered'); }
  if(!reloaded && pr.step===1){
   // real-input reload + resume test, right after the Mira conversation
   await sleep(3000); await shot('06_after_mira_talk');
   await p.reload(); await sleep(9000); await shot('07_reloaded_home');
   await click(176,549); await sleep(1500); await shot('08_mission_card_RESUME');
   await click(468,588); await sleep(3500); await shot('09_resumed_exploration');
   d=await readSave(); ok('Reload keeps progress: step 1, energy untouched',mp(d).step===1&&d.energy===60,'step '+mp(d).step+' energy '+d.energy);
   reloaded=true; continue;
  }
  if(pr.combat_run===true){
   if(mode!=='combat'){ mode='combat'; await sleep(1500); await shot('12_soul_realm_battle'); }
   for(let r=0;r<2;r++){ await walk(120,Math.random()<0.5?1:-1); for(const a of strikes){ if(T) await ttap(a[0],a[1],2,60); else await p.keyboard.press(a); await sleep(70); } const dd=await readSave(); if(dd&&(dd.completed||[]).includes('1-1')) break; }
   await advance(); await sleep(400);
   if(cycles++===8) await shot('13_battle_later');
   continue;
  }
  // exploration
  await walk(420); await act();
  await sleep(380);
  await hold(2300);
  for(let i=0;i<3;i++){ await advance(); await sleep(450); }
 }
 d=await readSave(); const done=d&&(d.completed||[]).includes('1-1');
 ok('Episode 1 completed with real input (saved completion)',done,'elapsed '+Math.round((Date.now()-t0)/1000)+' s');
 await sleep(1500); await shot('14_rewards_screen'); await sleep(3500);
 d=await readSave();
 ok('First-clear rewards saved once: +250 gold, +120 XP (level 1 -> 2 with 20 XP left), energy 60 -> 54',d.gold===750&&d.level===2&&d.xp===20&&d.energy===54,`gold ${d.gold} level ${d.level} xp ${d.xp} energy ${d.energy}`);
 ok('Codex has all 6 Episode 1 entries, no duplicates',d.codex.length===6&&new Set(d.codex).size===6,JSON.stringify(d.codex));
 ok('Resume state cleared after completion',!('step' in mp(d))&&!('intro' in mp(d))&&!('combat_run' in mp(d))&&!('battle_won' in mp(d)),JSON.stringify(mp(d)));
 await p.reload(); await sleep(9000); await shot('15_home_after_final_reload');
 const d2=await readSave(); ok('After reload: same save (gold 750, completed once)',d2.gold===750&&d2.completed.filter(x=>x==='1-1').length===1,'gold '+d2.gold);
 await click(176,549); await sleep(1500); await shot('16_mission_card_after_clear');
 recording=false; await recorder;
 ok('No console errors',msgs.length===0,JSON.stringify(msgs).slice(0,300));
 fs.writeFileSync(`${S}/${TAG}_results.json`,JSON.stringify({tag:TAG,viewport:[W,H],mode:MODE,results},null,1));
 console.log('SUMMARY',TAG,results.filter(r=>r.c).length+'/'+results.length);
 await b.close();
})();
