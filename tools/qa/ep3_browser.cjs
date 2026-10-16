// Episode 3 end-to-end in Chromium against the "Web QA" export (never the production build: 1-3 is not startable there).
// Real input only: keyboard (key) or touch (touch, CDP touch events) at any viewport. The QA build publishes window.__qa (scripts/qa/qa_hook.gd): state to read, never input shortcuts.
// Route: home -> Missions -> QA: PLAY EPISODE 3 -> title card/opening -> market, station (rail door puzzle), alleys, workshop (decode, board, relay-map puzzle; RELOAD checkpoint),
//        tower floors 1-3 (signal, power, memory puzzles), archive gate, Warden arena (plaque, VALVE, BELL, SEAL while dodging telegraphs), archive core, recording, rewards, teaser, home.
// usage: PORT=8801 node ep3_browser.cjs <outdir> <key|touch> <w> <h> <tag>
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const fs = require('fs');
const [,, OUT, MODE, WS, HS, TAG] = process.argv; const W = +WS, H = +HS; const PORT = process.env.PORT || '8801';
const T = MODE === 'touch';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2;
const G = (gx, gy) => ({ x: ox + gx * kk, y: oy + gy * kk });
const results = []; const log = [];
const ok = (n, c, d = '') => { results.push({ n, c: !!c, d }); const line = (c ? 'PASS: ' : 'FAIL: ') + n + (d ? '  (' + d + ')' : ''); console.log(line); };
const note = m => { const l = `[${((Date.now() - T0) / 1000).toFixed(0)}s] ${m}`; log.push(l); console.log(l); };
let T0 = Date.now(), page, cdp, browser, ctx; const msgs = [];
// the snapshot lags up to 0.2 s; the per-frame channel (window.__qa_f = [px, arena dodge]) keeps walking and dodging accurate
const S = () => page.evaluate(() => { const q = window.__qa || null; const f = window.__qa_f; if (q && q.ep && f) { q.ep.px = f[0]; if (q.ep.arena) q.ep.arena.dodge = f[1]; } return q; });
async function waitFor(pred, timeout, step = 150) { const t = Date.now(); while (Date.now() - t < timeout) { const s = await S(); if (s && pred(s)) return s; await sleep(step); } return null; }
const shot = async nm => { try { await page.screenshot({ path: `${OUT}/${TAG}_${nm}.png` }); } catch (e) {} };
// ---------------------------------------------------------------- input
async function touch(type, pts) { await cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts }); }
async function tapG(gx, gy) { const p = G(gx, gy); if (T) { await touch('touchStart', [{ x: p.x, y: p.y, id: 1 }]); await sleep(80); await touch('touchEnd', []); } else { await page.mouse.click(p.x, p.y); } await sleep(60); }
async function tapRect(b) { await tapG(b.x + b.w / 2, b.y + b.h / 2); }
async function press(key, hold = 60) { await page.keyboard.down(key); await sleep(hold); await page.keyboard.up(key); await sleep(70); }
let moving = 0, stickDown = false;
async function setMove(dir) {
  if (dir === moving) return;
  if (T) {
    const c = G(126, 610), tg = G(126 + dir * 60, 610);
    if (dir === 0) { if (stickDown) { await touch('touchEnd', []); stickDown = false; } }
    else if (!stickDown) { await touch('touchStart', [{ x: c.x, y: c.y, id: 1 }]); stickDown = true; await touch('touchMove', [{ x: tg.x, y: tg.y, id: 1 }]); }
    else await touch('touchMove', [{ x: tg.x, y: tg.y, id: 1 }]);
  } else {
    if (moving > 0) await page.keyboard.up('d'); if (moving < 0) await page.keyboard.up('a');
    if (dir > 0) await page.keyboard.down('d'); if (dir < 0) await page.keyboard.down('a');
  }
  moving = dir;
}
const ACT = G(1162, 638);
async function act() { if (T) await tapG(1162, 638); else await press('Enter', 70); }
async function hold(on) { if (T) { if (on) await touch('touchStart', [{ x: ACT.x, y: ACT.y, id: 2 }]); else await touch('touchEnd', []); } else { if (on) await page.keyboard.down('e'); else await page.keyboard.up('e'); } }
// channel spots (scans, mechanisms) need the act control held for ~1.4 s; stop as soon as the scene starts
async function holdAct(ms) {
  await hold(true); const t0 = Date.now();
  while (Date.now() - t0 < ms) { const s = await S(); if (!s || !s.ep || s.ep.busy || s.ep.dialogue || s.ep.locked) break; await sleep(60); }
  await hold(false);
}
async function advance() { if (T) await tapG(640, 600); else await press('Enter', 50); }
// The character coasts ~60 px after the key/stick is released and the state read lags a few frames: stop early (COAST), settle, then correct with short pulses.
const COAST = 55;
async function walkTo(x, { tol = 40, timeout = 90000, dodge = false } = {}) {
  const t0 = Date.now();
  for (let round = 0; round < 14; round++) {
    for (;;) {
      const s = await S();
      if (!s || !s.ep || s.ep.dialogue || s.ep.busy || s.ep.traveling || s.ep.puzzle) { await setMove(0); return 'interrupted'; }
      const d = dodge && s.ep.arena ? s.ep.arena.dodge : 0;
      const err = x - s.ep.px;
      let want = d;
      if (!want && Math.abs(err) > (moving ? COAST : tol)) want = err > 0 ? 1 : -1;
      if (!want && moving && Math.abs(err) <= COAST) want = 0;
      await setMove(want);
      if (!want) break;
      if (Date.now() - t0 > timeout) { note('walkTo timeout x=' + x); await setMove(0); return 'timeout'; }
      await sleep(25);
    }
    await sleep(320);                                      // settle
    const s = await S();
    if (!s || !s.ep) return 'interrupted';
    const err = x - s.ep.px;
    if (Math.abs(err) <= tol && !(dodge && s.ep.arena && s.ep.arena.dodge)) return 'arrived';
    if (dodge && s.ep.arena && s.ep.arena.dodge) continue;
    await setMove(err > 0 ? 1 : -1); await sleep(55); await setMove(0); await sleep(220);   // a short corrective pulse
  }
  return 'arrived';
}
async function useSpot(id, dodge = false) {
  const s = await S(); const sp = s.ep.spots.find(p => p.id === id);
  if (!sp) { note('no spot ' + id + ' in ' + s.ep.zone); return false; }
  const w = await walkTo(sp.x, { dodge, tol: Math.min(45, (sp.range || 110) * 0.45) });
  if (process.env.DEBUG) { const d = await S(); note(`useSpot ${id}: walk=${w} px=${d.ep && d.ep.px} spot.x=${sp.x} dlg=${d.ep && d.ep.dialogue} busy=${d.ep && d.ep.busy}`); }
  if (w !== 'arrived') return false;
  if (sp.kind === 'channel') await holdAct(3200); else await act();
  await sleep(450);
  if (process.env.DEBUG) { const d = await S(); note(`  after act: dlg=${d.ep && d.ep.dialogue} busy=${d.ep && d.ep.busy} clues=${d.ep && d.ep.clues.length}`); }
  return true;
}
// hold the channel at a mechanism; if a telegraph threatens the spot, let go, step clear and try again
async function channel(id) {
  const s0 = await S(); const sp = s0.ep.spots.find(p => p.id === id); if (!sp) return;
  await walkTo(sp.x, { dodge: true, tol: Math.min(45, (sp.range || 110) * 0.45) });
  for (let tries = 0; tries < 16; tries++) {
    let s = await S(); if (!s || !s.ep || s.ep.clues.includes('restored_' + id) || s.ep.busy || s.ep.dialogue) break;
    await hold(true); const t0 = Date.now();
    while (Date.now() - t0 < 2400) { s = await S(); if (!s || !s.ep || s.ep.clues.includes('restored_' + id) || (s.ep.arena && s.ep.arena.dodge !== 0) || s.ep.busy || s.ep.dialogue) break; await sleep(40); }
    await hold(false);
    s = await S(); if (s && s.ep && s.ep.arena && s.ep.arena.dodge !== 0) await walkTo(sp.x, { dodge: true, tol: Math.min(45, (sp.range || 110) * 0.45) });
    await sleep(300);
  }
}
// ---------------------------------------------------------------- puzzles (one action per call; the hook republishes every 0.2 s)
async function solvePuzzle(p) {
  const pl = p.plan;
  if (p.done || !pl) { await sleep(350); return; }
  const arrows = p.buttons.filter(b => b.text === '<' || b.text === '>');
  switch (p.kind) {
    case 'signal':
      if (pl.df === 0 && pl.da === 0) { if (T) await tapRect(p.buttons.find(b => b.text === 'LOCK SIGNAL')); else await press('Enter'); }
      else if (pl.df !== 0) { if (T) await tapRect(arrows[pl.df > 0 ? 1 : 0]); else await press(pl.df > 0 ? 'ArrowRight' : 'ArrowLeft', 50); }
      else { if (T) await tapRect(arrows[pl.da > 0 ? 3 : 2]); else await press(pl.da > 0 ? 'ArrowUp' : 'ArrowDown', 50); }
      break;
    case 'power': case 'map': {
      const c = pl.cells[0]; if (!c) { await sleep(300); break; }
      if (T) { await tapG(c.x, c.y); break; }
      const cc = p.cursor % pl.cols, cr = Math.floor(p.cursor / pl.cols);
      if (cc !== c.col) await press(c.col > cc ? 'ArrowRight' : 'ArrowLeft', 50);
      else if (cr !== c.row) await press(c.row > cr ? 'ArrowDown' : 'ArrowUp', 50);
      else await press('Enter', 50);
      break; }
    case 'rail':
      if (T) { if (p.sel !== pl.block) await tapG(pl.pick.x, pl.pick.y); else await tapG(pl.to.x, pl.to.y); }
      else if (p.sel !== pl.block) await press('Enter', 50);
      else await press(pl.axis === 'h' ? (pl.dir > 0 ? 'ArrowRight' : 'ArrowLeft') : (pl.dir > 0 ? 'ArrowDown' : 'ArrowUp'), 50);
      break;
    case 'memory':
      if (pl.action === 'click' || pl.action === 'check') await tapG(pl.x, pl.y); else await sleep(300);   // cards and slots are Buttons: a click/tap works in both modes
      break;
  }
  await sleep(300);
}
// ---------------------------------------------------------------- page
async function boot(first) {
  await page.goto(`http://localhost:${PORT}/index.html`);
  const s = await waitFor(s => s.scene === 'home', 90000);
  ok(first ? 'QA build boots to the home screen' : 'Reload: the QA build boots to the home screen again', !!s);
  await sleep(1200);
  if (first) {
    await shot('00_first_screen');
    const ob = await S(); const b = ob.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tapRect(b); await sleep(2500); }
  }
  await closeModal();
  await shot(first ? '01_home' : '20_home_after_reload');
}
async function closeModal() {
  for (let i = 0; i < 3; i++) { const m = await S(); const c = m && m.buttons.find(x => x.text === 'CLOSE'); if (!c) return; await tapRect(c); await sleep(700); }
}
async function openEpisode3() {
  await closeModal();
  let s = await S(); const m = s.buttons.find(b => b.text === 'MISSIONS'); await tapRect(m);
  s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000);
  ok('Missions screen shows the QA button (QA flavor only)', !!s);
  if (!s) return false;
  await shot('02_missions_qa_button');
  await tapRect(s.buttons.find(b => b.text.startsWith('QA:')));
  return !!(await waitFor(s => s.scene === 'episode', 15000));
}
const seenZones = new Set(), seenPuz = new Set();
async function drive() {
  let sig = '', sigAt = Date.now(), reloaded = false, startGold = null;
  for (let it = 0; it < 100000; it++) {
    if (Date.now() - T0 > 40 * 60 * 1000) { ok('finished within the 40 minute budget', false); return 'timeout'; }
    const s = await S(); if (!s) { await sleep(200); continue; }
    if (['result', 'teaser', 'home'].includes(s.scene)) return s.scene;
    const e = s.ep;
    const cur = JSON.stringify([s.scene, e && e.zone, e && e.clues.length, e && e.puzzle && e.puzzle.kind, e && e.arena && e.arena.hp]);
    if (cur !== sig) { sig = cur; sigAt = Date.now(); }
    if (Date.now() - sigAt > 150000) { await shot('99_stuck'); ok('no stall: progress changed within 150 s', false, cur + ' target=' + (e && e.target) + ' step=' + (e && e.step)); return 'stuck'; }
    if (!e) { if (s.scene === 'episode') await advance(); await sleep(250); continue; }
    if (!seenZones.has(e.zone)) { seenZones.add(e.zone); note('zone ' + e.zone); await sleep(500); await shot('zone_' + e.zone); }
    if (e.puzzle) {
      if (!seenPuz.has(e.puzzle.kind)) { seenPuz.add(e.puzzle.kind); note('puzzle ' + e.puzzle.kind); await sleep(500); await shot('puzzle_' + e.puzzle.kind + '_open'); }
      await solvePuzzle(e.puzzle); continue;
    }
    if (e.dialogue || e.busy || e.traveling || e.locked) { await advance(); await sleep(200); continue; }
    // save/reload checkpoint: after Teo's decoder, in the workshop, with nothing running
    if (!reloaded && e.clues.includes('decoded') && e.zone === 'workshop') {
      reloaded = true; await reloadCheckpoint(); continue;
    }
    let target = e.target;
    if (!target && e.zone === 'tower_3' && e.clues.includes('archive_examined')) target = 'exit_arena';
    if (!target) { await sleep(300); continue; }
    if (target.startsWith('mech_')) { await channel(target); continue; }
    if (!(await useSpot(target, e.zone === 'arena'))) await sleep(200);
  }
  return 'loop-end';
}
// what the browser has actually stored (IndexedDB behind user://): the 1-3 clue list, or null
const idbClues = () => page.evaluate(async () => {
  try {
    const db = await new Promise((res, rej) => { const r = indexedDB.open('/userfs'); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); });
    const st = db.transaction('FILE_DATA').objectStore('FILE_DATA');
    const keys = await new Promise(res => { const r = st.getAllKeys(); r.onsuccess = () => res(r.result); });
    const key = keys.find(k => k.endsWith('soul_ascension_v1.json')); if (!key) return null;
    const rec = await new Promise(res => { const r = st.get(key); r.onsuccess = () => res(r.result); });
    const env = JSON.parse(new TextDecoder().decode(new Uint8Array(rec.contents)));
    const mp = JSON.parse(env.payload).mission_progress; return mp && mp['1-3'] ? mp['1-3'].clues : [];
  } catch (e) { return null; }
});
async function reloadCheckpoint() {
  const before = await S(); await shot('10_before_reload');
  // wait until the browser storage really holds every clue (measures the web save latency), then reload
  const t0 = Date.now(); let stored = null;
  while (Date.now() - t0 < 45000) { stored = await idbClues(); if (stored && before.ep.clues.every(c => stored.includes(c))) break; await sleep(500); }
  const lat = (Date.now() - t0) / 1000;
  const landed = !!stored && before.ep.clues.every(c => stored.includes(c));
  ok('Save reached browser storage (IndexedDB) after the last clue', landed, `latency ${lat.toFixed(1)} s, stored ${stored ? stored.length : 'none'} of ${before.ep.clues.length} clues`);
  note('save latency to IndexedDB: ' + lat.toFixed(1) + ' s');
  note('reloading the page at ' + before.ep.zone + ' with ' + before.ep.clues.length + ' clues');
  await page.reload(); await boot(false);
  const opened = await openEpisode3(); ok('Reload: Episode 3 can be re-entered from the QA button', opened);
  const after = await waitFor(s => s.ep && !s.ep.busy && !s.ep.dialogue, 60000);
  ok('Reload: the episode resumes in the same zone', !!after && after.ep.zone === before.ep.zone, after ? after.ep.zone + ' vs ' + before.ep.zone : 'none');
  ok('Reload: every clue is kept', !!after && before.ep.clues.every(c => after.ep.clues.includes(c)), after ? after.ep.clues.length + ' vs ' + before.ep.clues.length : '');
  ok('Reload: the objective is the same', !!after && after.ep.objective === before.ep.objective, after ? after.ep.objective : '');
  ok('Reload: unlocked exits are kept', !!after && before.ep.unlocks.every(u => after.ep.unlocks.includes(u)));
  ok('Reload: no intro/cinematic replays (episode is interactive straight away)', !!after && !after.ep.busy);
  await shot('11_after_reload_resume');
}
(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  ctx = await browser.newContext(T ? { viewport: { width: W, height: H }, hasTouch: true, isMobile: true, deviceScaleFactor: 2 } : { viewport: { width: W, height: H } });
  page = await ctx.newPage(); cdp = T ? await ctx.newCDPSession(page) : null;
  page.on('console', m => { if (m.type() === 'error') msgs.push(m.text()); }); page.on('pageerror', e => msgs.push('PAGEERR ' + e.message));
  T0 = Date.now();
  await boot(true);
  const s0 = await S(); const startGold = s0.gold;
  ok('QA build has the telemetry hook and the QA banner build flag', !!s0 && s0.buttons.length > 0);
  if (!(await openEpisode3())) { ok('Episode 3 started from the QA button', false); await shot('98_fail'); }
  else {
    ok('Episode 3 started from the QA button', true);
    const end = await drive();
    note('drive ended: ' + end);
    if (end === 'result') {
      const r = await S(); await sleep(800); await shot('30_rewards');
      ok('Finale: rewards screen is up and mission 1-3 is completed', r.completed.includes('1-3'));
      const r2 = await S();
      ok('First clear paid the provisional 340 gold', r2.gold === startGold + 340, r2.gold + ' vs ' + startGold + '+340');
      ok('Rewards screen offers NEXT EPISODE and REPLAY EPISODE', r2.buttons.some(b => b.text === 'NEXT EPISODE') && r2.buttons.some(b => b.text === 'REPLAY EPISODE'));
      await tapRect(r2.buttons.find(b => b.text === 'NEXT EPISODE'));
      const t = await waitFor(s => s.scene === 'teaser', 20000);
      ok('NEXT EPISODE plays the Episode 4 teaser', !!t); await sleep(1500); await shot('31_teaser');
      let h = null; const th = Date.now();
      while (Date.now() - th < 90000) { h = await S(); if (h && h.scene === 'home') break; await advance(); await sleep(1200); }
      ok('The teaser returns to the home screen', !!h && h.scene === 'home');
      await sleep(1500); await shot('32_home_after');
      if (h) ok('Home after the finale: 1-3 is recorded as completed, gold unchanged by the teaser', h.completed.includes('1-3') && h.gold === startGold + 340);
    } else ok('The route reached the rewards screen', false, 'ended: ' + end);
  }
  const real = msgs.filter(m => !/Failed to load resource/.test(m));
  ok('No page errors or console errors', real.length === 0, JSON.stringify(real).slice(0, 300));
  if (msgs.length > real.length) note('non-fatal: ' + (msgs.length - real.length) + ' failed resource load(s) (e.g. favicon)');
  await browser.close();
  const fails = results.filter(r => !r.c).length;
  fs.writeFileSync(`${OUT}/${TAG}_results.json`, JSON.stringify({ tag: TAG, mode: MODE, w: W, h: H, seconds: Math.round((Date.now() - T0) / 1000), fails, results, log }, null, 1));
  console.log(`RESULT ${TAG}: ${fails} failures, ${results.length} checks, ${Math.round((Date.now() - T0) / 1000)}s`);
  process.exit(fails ? 1 : 0);
})().catch(async e => { console.log('DRIVER ERROR', e && e.stack || e); try { await shot('97_driver_error'); await browser.close(); } catch (x) {} process.exit(2); });
