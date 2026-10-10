// RC verification harness. node rc.cjs SCRATCH MODE(key|touch) W H TAG
const { chromium } = require('/home/user/my-app/node_modules/@playwright/test');
const [,, S, MODE, WS, HS, TAG] = process.argv; const W=+WS, H=+HS;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const k=Math.min(W/1280,H/720), ox=(W-1280*k)/2, oy=(H-720*k)/2;
const G=(gx,gy)=>({x:ox+gx*k,y:oy+gy*k});
const log=(...a)=>console.log(new Date().toISOString().slice(11,19),...a);
(async()=>{
 const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--no-sandbox']});
 const ctx = await b.newContext(MODE==='touch'?{viewport:{width:W,height:H},hasTouch:true,isMobile:true,deviceScaleFactor:2}:{viewport:{width:W,height:H}});
 const p = await ctx.newPage();
 const cdp = MODE==='touch'? await ctx.newCDPSession(p):null;
 const msgs=[]; p.on('console',m=>{ if(m.type()==='error'||m.type()==='warning') msgs.push(m.type()+': '+m.text()) }); p.on('pageerror',e=>msgs.push('PAGEERR '+e.message));
 const q=async()=>await p.evaluate(()=>window.__qa||{});
 let n=0; const shot=async(name)=>{ await p.screenshot({path:`${S}/v21_${TAG}_${String(++n).padStart(2,'0')}_${name}.png`}); log('shot',name); };
 // in-page sampler: records every 25 ms while a battle HUD exists
 await p.addInitScript(()=>{
  window.__samples=[];
  const inter=(a,b)=>a&&b&&a[0]<b[0]+b[2]&&b[0]<a[0]+a[2]&&a[1]<b[1]+b[3]&&b[1]<a[1]+a[3];
  setInterval(()=>{
   const s=window.__qa; if(!s||s.scene!=='battle'||!s.card) return;
   const ra=s.radio?s.radio.a:0, ca=s.card.a, sa=s.sub.a;
   const vis={radio:ra>0.05,card:ca>0.05,sub:sa>0.05,ult:s.ult.a>0.05&&s.ult.text!==''};
   const out={t:performance.now(),phase:s.phase,tc:s.tc,sup:s.sup,ra,ca,sa,txt:s.card.text,rt:s.radio?s.radio.text.slice(0,14):'' ,ov:[]};
   if(vis.radio){
    if(vis.card) out.ov.push('radio~card');
    if(vis.sub) out.ov.push('radio~sub');
    if(inter(s.radio.r,s.card.r)&&vis.card) out.ov.push('radio#card-rect');
    if(inter(s.radio.r,s.sub.r)&&vis.sub) out.ov.push('radio#sub-rect');
    if(inter(s.radio.r,s.foepanel)) out.ov.push('radio#foepanel');
    s.ctl.forEach((c,i)=>{ if(inter(s.radio.r,c)) out.ov.push('radio#control'+i); });
    if(inter(s.radio.r,s.stick)) out.ov.push('radio#stick');
    if(vis.ult) out.ov.push('radio~ultimate-title(player used ULT)');
    out.ulta=s.ult.a;
   }
   if(vis.card){ if(inter(s.card.r,s.foepanel)) out.ov.push('banner#foepanel'); s.ctl.forEach((c,i)=>{ if(inter(s.card.r,c)) out.ov.push('banner#control'+i); }); }
   if(vis.sub){ if(inter(s.sub.r,s.foepanel)) out.ov.push('bannersub#foepanel'); s.ctl.forEach((c,i)=>{ if(inter(s.sub.r,c)) out.ov.push('bannersub#control'+i); }); }
   if(ra>0.05||ca>0.05||s.phase===2) window.__samples.push(out);
  },25);
 });
 // input layer ---------------------------------------------------------------------------------
 const active=new Map();
 const send=async(type)=>{ await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:[...active.entries()].map(([id,pt])=>({x:pt.x,y:pt.y,id}))}); };
 const tdown=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchStart'); };
 const tmove=async(id,gx,gy)=>{ active.set(id,G(gx,gy)); await send('touchMove'); };
 const tup=async(id)=>{ active.delete(id); await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[...active.entries()].map(([i,pt])=>({x:pt.x,y:pt.y,id:i}))}); };
 const ttap=async(gx,gy,id=1,ms=80)=>{ await tdown(id,gx,gy); await sleep(ms); await tup(id); };
 const STICK=[126,610];
 const T=MODE==='touch';
 const walk=async(ms,dir=1)=>{ if(T){ await tdown(1,STICK[0],STICK[1]); await tmove(1,STICK[0]+110*dir,STICK[1]); await sleep(ms); await tup(1);} else { await p.keyboard.down(dir>0?'d':'a'); await sleep(ms); await p.keyboard.up(dir>0?'d':'a'); } };
 const act=async()=>{ if(T) await ttap(1162,638,2); else await p.keyboard.press('e'); };
 const hold=async(ms)=>{ if(T){ await tdown(2,1162,638); await sleep(ms); await tup(2);} else { await p.keyboard.down('e'); await sleep(ms); await p.keyboard.up('e'); } };
 const advance=async()=>{ if(T) await ttap(300,570,3); else await p.keyboard.press('e'); };
 const confirmPrompt=async()=>{ if(T) await ttap(486,450); else await p.keyboard.press('Enter'); };
 const clickResultNext=async()=>{ if(T) await ttap(465,567); else await p.mouse.click(465,567); };
 // ---------------------------------------------------------------------------------------------
 await p.goto('http://localhost:8770/index.html');
 for(let i=0;i<120;i++){ await sleep(500); if((await q()).scene==='home') break; }
 await shot('home');
 if(T){ await ttap(176,549); await sleep(1200); await ttap(468,588); } else { await p.mouse.click(176,549); await sleep(1200); await p.mouse.click(468,588); }
 await sleep(1200);
 for(let i=0;i<12;i++){ await advance(); await sleep(1000); }
 log('explore',JSON.stringify(await q()).slice(0,200));
 for(let c=0;c<220;c++){
  const s=await q();
  if(s.step===4&&!s.busy) break;
  if(s.busy){ await advance(); await sleep(450); continue; }
  await walk(420); await act(); await sleep(380); await hold(2300); await sleep(200);
 }
 log('breach step',JSON.stringify((await q()).mp));
 for(let i=0;i<40;i++){ await walk(360); const s=await q(); if(s.prompt) break; await act(); await sleep(450); if((await q()).prompt) break; }
 for(let i=0;i<20;i++){ if((await q()).prompt) break; await sleep(300); }
 await sleep(500);
 const e0=(await q()).energy;
 await shot('prompt');
 await confirmPrompt();
 for(let i=0;i<40;i++){ if((await q()).scene==='battle') break; await sleep(300); }
 let st=await q();
 log('battle entered',JSON.stringify({scene:st.scene,energyBefore:e0,energy:st.energy,run:st.run}));
 let art=''; const caps={}; const cap=async(name)=>{ if(!caps[name]){ caps[name]=true; await shot(name); } };
 let mend=null, usedF=false; let bgStop=false;
 const bg=(async()=>{ while(!bgStop){ try{ const s=await q();
   if(s.scene==='battle' && s.wave===1 && !s.dead){
    if(s.phase===1 && s.swing>0.17 && s.anim==='attack1') await cap('cantor_attack_phase1');
    if(s.phase===2 && s.swing>0.17 && s.anim==='attack1') await cap('cantor_attack_phase2');
   }
   if(s.wave===1 && s.dead && s.anim==='defeat'){ await sleep(350); await cap('cantor_defeat_b'); }
  }catch(e){} await sleep(15);} })();
 const t0=Date.now();
 const strike=T?[[1188,648],[1188,648],[1188,648],[1188,548],[876,548],[1188,648],[1188,648]]:['j','j','j','k','q','j','j'];
 const watch=async()=>{
  const s=await q();
  if(s.card && s.card.text==='THE CHORUS RISES' && s.card.a>0.75) await cap('phase2_banner');
  if(s.radio && s.radio.a>0.9 && s.card && s.card.a<0.05) await cap('radio_line_after_banner');
  if(s.radio && s.radio.a>0.9 && s.phase===2) await cap('phase2_hud_with_radio');
  if(s.wave===1 && s.phase===1 && s.telegraph>0.35 && !s.dead) await cap('cantor_telegraph');
  if(s.phase===2 && s.telegraph>0.2 && !s.dead) await cap('cantor_telegraph_phase2');
  if(s.wave===1 && s.dead && s.anim==='defeat'){ await cap('cantor_defeat_a'); }
  if(s.wave===1) art=s.art+' scale='+s.foescale.toFixed(2)+' tint='+s.tint+' phase='+s.phase;
  return s;
 };
 while(Date.now()-t0<480000){
  st=await watch();
  if(st.scene==='ending'||st.scene==='result') break;
  if(st.scene!=='battle'){ await sleep(400); continue; }
  if(st.intro>0){ await sleep(300); continue; }
  if(st.wave===1) await cap('cantor_phase1');
  if(T && !(mend && mend.after.cd>0) && st.phase===2 && st.aether>=30){ const before={hero:st.hero,aether:st.aether,cd:st.mend_cd}; await ttap(1084,548,2,80); await sleep(200); const a=await q(); mend={before,after:{hero:a.hero,aether:a.aether,cd:a.mend_cd},max:st.heromax}; log('MEND attempt',JSON.stringify(mend)); }
  if(caps['phase2_hud_with_radio'] && !caps['phase2_hud_after_radio']){
   // hold fire in Phase 2 until Mira's line has faded, so the Phase 2 HUD can be captured on its own
   const sx=await q();
   if(sx.radio && sx.radio.a<0.02 && sx.card.a<0.02){ await cap('phase2_hud_after_radio'); }
   await sleep(120); continue;
  }
  await walk(120,Math.random()<0.5?1:-1);
  for(const a of strike){ if(T) await ttap(a[0],a[1],2,60); else { await p.keyboard.press(a); } await sleep(70); await watch(); }
  // ultimate only outside the Mira radio window, so the player's own ULT title never stacks on the line
  const s2=await q();
  if(!usedF && !(s2.radio&&s2.radio.a>0.02) && s2.phase!==2 && s2.wave===0){ if(T) await ttap(746,642,2,60); else await p.keyboard.press('f'); }
 }
 bgStop=true; await bg;
 st=await q();
 log('battle over',JSON.stringify({scene:st.scene,energy:st.energy,tc:st.tc,sup:st.sup}));
 // ending
 const t1=Date.now(); let seen={};
 while(Date.now()-t1<150000){
  st=await q();
  if(st.scene==='result') break;
  if(st.completed.includes('1-2')&&st.scene==='ending') log('FAIL completed during ending');
  const d=st.dlg||'';
  if(d.startsWith('Echo. Say something')&&!seen.a){ seen.a=1; await sleep(1800); await shot('calm_soul_realm_mira'); }
  if(d.startsWith("I'm here. It wasn't")&&!seen.b){ seen.b=1; await sleep(2000); await shot('calm_soul_realm_echo'); }
  if(d.startsWith('Citizens of Neon')&&!seen.v){ seen.v=1; await sleep(2200); await shot('vaust_broadcast'); }
  if(d.startsWith('The breach folds')&&!seen.f){ seen.f=1; await sleep(1500); await shot('quarter_aftermath'); }
  await advance(); await sleep(650);
 }
 st=await q();
 log('rewards',JSON.stringify({scene:st.scene,gold:st.gold,xp:st.xp,level:st.level,energy:st.energy,run:st.run,completed:st.completed,codex:st.codex.includes('hollow_cantor'),flags:st.mp['1-2'].flags,pending:st.mp['1-2'].battle_won,combat:st.mp['1-2'].combat_run}));
 await sleep(900); await shot('rewards');
 const rw={gold:st.gold,xp:st.xp,level:st.level};
 await clickResultNext(); await sleep(1800); st=await q(); log('after NEXT EPISODE',st.scene); await shot('episode3_teaser');
 for(let i=0;i<40;i++){ st=await q(); if(st.scene==='home') break; await sleep(500); }
 await sleep(900); st=await q();
 log('home again',JSON.stringify({scene:st.scene,energy:st.energy,gold:st.gold,xp:st.xp,level:st.level,completed:st.completed}));
 await shot('home_after');
 // sampler analysis
 const samples=await p.evaluate(()=>window.__samples);
 const radioOn=samples.filter(s=>s.ra>0.05), bannerOn=samples.filter(s=>s.ca>0.05&&s.txt==='THE CHORUS RISES');
 const lastBanner=Math.max(...bannerOn.map(s=>s.t),0), firstRadio=Math.min(...radioOn.map(s=>s.t),1e12);
 const ovs={}; samples.forEach(s=>s.ov.forEach(o=>ovs[o]=(ovs[o]||0)+1));
 const out={samples:samples.length,bannerSamples:bannerOn.length,radioSamples:radioOn.length,
  radioStartsAfterBannerClears:radioOn.length>0&&firstRadio>=lastBanner,gapMs:Math.round(firstRadio-lastBanner),
  maxTransformCount:Math.max(...samples.map(s=>s.tc),0),maxSupportCount:Math.max(...samples.map(s=>s.sup),0),
  overlaps:ovs,radioText:(radioOn[0]||{}).rt};
 console.log('ANALYSIS',JSON.stringify(out));
 console.log('MEND',JSON.stringify(mend));
 console.log('REWARD_DELTA',JSON.stringify({before:{gold:500,xp:0,level:4},afterRewards:rw,afterHome:{gold:st.gold,xp:st.xp,level:st.level},energyBeforeRun:e0,energyAfter:st.energy}));
 console.log('ART',art);
 console.log('CONSOLE', JSON.stringify(msgs));
 await b.close();
})();
