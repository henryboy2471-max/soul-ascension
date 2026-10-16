// Browser save regression: reload IMMEDIATELY after a clue, a puzzle move, an objective update (and, in production, onboarding / a setting / Episode 1 progress),
// then verify the saved state. The reload is issued from the page the moment the change is seen (no waiting for IndexedDB), so it races the browser's asynchronous
// IndexedDB write; the game must come back with the change (from its synchronous localStorage copy) and must never have said "saved" before IndexedDB held it.
//   qa   : the "Web QA" export (state hook: clue / puzzle move / objective, plus the "saved means stored" sampler)      PORT=8801
//   prod : the production "Web" export (no hook): onboarding, a setting, Episode 1 progress, verified from browser storage     PORT=8793
// usage: PORT=8801 node save_reload_browser.cjs <qa|prod> <outdir> <key|touch> <w> <h> <tag>
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const fs = require('fs'); const cp = require('child_process');
const [,, FLAVOR, OUT, MODE, WS, HS, TAG] = process.argv; const W = +WS, H = +HS; const PORT = process.env.PORT || '8801';
const T = MODE === 'touch', QA = FLAVOR === 'qa';
const KEY = 'soul_ascension_v1_mirror';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2;
const G = (gx, gy) => ({ x: ox + gx * kk, y: oy + gy * kk });
const results = [], log = []; let T0 = Date.now(), page, cdp, browser, ctx; const msgs = [];
const ok = (n, c, d = '') => { results.push({ n, c: !!c, d }); console.log((c ? 'PASS: ' : 'FAIL: ') + n + (d ? '  (' + d + ')' : '')); };
const note = m => { const l = `[${((Date.now() - T0) / 1000).toFixed(0)}s] ${m}`; log.push(l); console.log(l); };
const shot = async nm => { try { await page.screenshot({ path: `${OUT}/${TAG}_${nm}.png` }); } catch (e) {} };
const S = () => page.evaluate(() => { const q = window.__qa || null; const f = window.__qa_f; if (q && q.ep && f) { q.ep.px = f[0]; if (q.ep.arena) q.ep.arena.dodge = f[1]; } return q; }).catch(() => null);   // null while a navigation is in flight
async function waitFor(pred, timeout, step = 120) { const t = Date.now(); while (Date.now() - t < timeout) { const s = await S(); if (s && pred(s)) return s; await sleep(step); } return null; }
// ---------------------------------------------------------------- input (same primitives as ep3_browser.cjs)
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
  } else { if (moving > 0) await page.keyboard.up('d'); if (moving < 0) await page.keyboard.up('a'); if (dir > 0) await page.keyboard.down('d'); if (dir < 0) await page.keyboard.down('a'); }
  moving = dir;
}
const ACT = G(1162, 638);
async function act() { if (T) await tapG(1162, 638); else await press('Enter', 70); }
async function hold(on) { if (T) { if (on) await touch('touchStart', [{ x: ACT.x, y: ACT.y, id: 2 }]); else await touch('touchEnd', []); } else { if (on) await page.keyboard.down('e'); else await page.keyboard.up('e'); } }
async function advance() { if (T) await tapG(640, 600); else await press('Enter', 50); }
const COAST = 55;
async function walkTo(x, tol = 40) {
  for (let round = 0; round < 14; round++) {
    for (;;) {
      const s = await S(); if (!s || !s.ep || s.ep.dialogue || s.ep.busy || s.ep.traveling || s.ep.puzzle) { await setMove(0); return 'interrupted'; }
      const err = x - s.ep.px; let want = 0; if (Math.abs(err) > (moving ? COAST : tol)) want = err > 0 ? 1 : -1;
      await setMove(want); if (!want) break; await sleep(25);
    }
    await sleep(320); const s = await S(); if (!s || !s.ep) return 'interrupted';
    const err = x - s.ep.px; if (Math.abs(err) <= tol) return 'arrived';
    await setMove(err > 0 ? 1 : -1); await sleep(55); await setMove(0); await sleep(220);
  }
  return 'arrived';
}
async function holdAct(ms) { await hold(true); const t0 = Date.now(); while (Date.now() - t0 < ms) { const s = await S(); if (!s || !s.ep || s.ep.busy || s.ep.dialogue || s.ep.locked) break; await sleep(60); } await hold(false); }
async function useSpot(id) {
  const s = await S(); const sp = s.ep.spots.find(p => p.id === id); if (!sp) return false;
  if (await walkTo(sp.x, Math.min(45, (sp.range || 110) * 0.45)) !== 'arrived') return false;
  if (sp.kind === 'channel') await holdAct(3200); else await act();
  await sleep(450); return true;
}
// ---------------------------------------------------------------- browser storage readers (no game hook needed)
const readStores = () => page.evaluate(async KEY => {
  const out = { mirror: null, idb: null, idbSha: null, mirrorSha: null };
  try { const t = localStorage.getItem(KEY); if (t) { const e = JSON.parse(t); out.mirrorSha = e.sha256; out.mirror = JSON.parse(e.payload); } } catch (e) {}
  try {
    const db = await new Promise((res, rej) => { const r = indexedDB.open('/userfs'); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); });
    const st = db.transaction('FILE_DATA').objectStore('FILE_DATA');
    const keys = await new Promise(res => { const r = st.getAllKeys(); r.onsuccess = () => res(r.result); });
    const k = keys.find(x => x.endsWith('soul_ascension_v1.json'));
    if (k) { const rec = await new Promise(res => { const r = st.get(k); r.onsuccess = () => res(r.result); }); const e = JSON.parse(new TextDecoder().decode(new Uint8Array(rec.contents))); out.idbSha = e.sha256; out.idb = JSON.parse(e.payload); }
    db.close();
  } catch (e) {}
  return out;
}, KEY);
// "saved means stored" sampler, installed in every page load: whenever the game's snapshot says saved for the latest save it wrote, IndexedDB must hold exactly that save
const SAMPLER = KEY => {
  window.__hv = []; window.__hs = 0; window.__hsaving = 0; window.__hunc = 0;
  const shaOf = t => { try { return JSON.parse(t).sha256; } catch (e) { return null; } };
  const idbSha = async () => {
    const db = await new Promise((res, rej) => { const r = indexedDB.open('/userfs'); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); });
    try { const st = db.transaction('FILE_DATA').objectStore('FILE_DATA'); const keys = await new Promise(res => { const r = st.getAllKeys(); r.onsuccess = () => res(r.result); }); const k = keys.find(x => x.endsWith('soul_ascension_v1.json')); if (!k) return null; const rec = await new Promise(res => { const r = st.get(k); r.onsuccess = () => res(r.result); }); return shaOf(new TextDecoder().decode(new Uint8Array(rec.contents))); } finally { db.close(); }
  };
  setInterval(async () => {
    try {
      const q = window.__qa; if (!q || !q.save) return;
      if (q.save.state === 'saving') { window.__hsaving++; return; }
      if (q.save.state === 'unconfirmed') { window.__hunc++; return; }
      if (q.save.state !== 'saved' || !q.save.sha) return;
      const m1 = shaOf(localStorage.getItem(KEY)); if (m1 !== q.save.sha) return;          // a newer save was written after this snapshot
      const idb = await idbSha(); const m2 = shaOf(localStorage.getItem(KEY)); if (m2 !== m1) return;
      window.__hs++; if (idb !== m1) window.__hv.push({ t: Math.round(performance.now()), mirror: m1, idb });
    } catch (e) {}
  }, 50);
};
const harvest = () => page.evaluate(() => ({ viol: window.__hv || [], samples: window.__hs || 0, saving: window.__hsaving || 0, unc: window.__hunc || 0 })).catch(() => ({ viol: [], samples: 0, saving: 0, unc: 0 }));
const tot = { viol: 0, samples: 0, saving: 0, unc: 0 };
async function harvestAdd() { const h = await harvest(); tot.viol += h.viol.length; tot.samples += h.samples; tot.saving += h.saving; tot.unc += h.unc; if (h.viol.length) note('VIOLATION ' + JSON.stringify(h.viol[0])); }
// reload from inside the page, as soon as the change has been seen; reports whether IndexedDB had confirmed it by then
async function reloadNow(label) {
  await harvestAdd();
  const info = await page.evaluate(() => { const p = window.__soul ? { pending: window.__soul.pending, stored: !!window.__soul.stored } : null; setTimeout(() => location.reload(), 0); return p; });
  note(`${label}: reloaded immediately; IndexedDB confirmation pending at that moment: ${info ? info.pending : 'no tracker yet'}`);
  racePending.push({ label, pending: info ? info.pending : null });
  await sleep(500);
}
const racePending = []; const sources = [];
async function bootQA(first) {
  if (first) { await page.addInitScript(SAMPLER, KEY); await page.goto(`http://localhost:${PORT}/index.html`); }   // not first: the in-page reload is already under way
  const s = await waitFor(s => s.scene === 'home', 90000);
  ok(first ? 'Boot: QA build reaches the home screen' : 'Reload: QA build reaches the home screen', !!s); await sleep(1000);
  return s;
}
async function closeModal() { for (let i = 0; i < 3; i++) { const m = await S(); const c = m && m.buttons.find(x => x.text === 'CLOSE'); if (!c) return; await tapRect(c); await sleep(700); } }
async function onboardQA() { const ob = await S(); const b = ob.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tapRect(b); await sleep(2500); } await closeModal(); }
async function openEpisode3() {
  await closeModal(); let s = await S(); await tapRect(s.buttons.find(b => b.text === 'MISSIONS'));
  s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000); if (!s) return false;
  await tapRect(s.buttons.find(b => b.text.startsWith('QA:')));
  return !!(await waitFor(s => s.scene === 'episode', 15000));
}
// play (advance dialogue, walk to the next spot) until pred(state) holds; checks pred before every action so the reload happens right after the change appears
async function playUntil(pred, budgetMs = 240000) {
  const t0 = Date.now();
  while (Date.now() - t0 < budgetMs) {
    const s = await S(); if (!s) { await sleep(150); continue; }
    if (pred(s)) return s;
    const e = s.ep;
    if (!e) { if (s.scene === 'episode') await advance(); await sleep(200); continue; }
    if (e.puzzle) { await sleep(150); continue; }
    if (e.dialogue || e.busy || e.traveling || e.locked) { await advance(); await sleep(160); continue; }
    if (!e.target) { await sleep(250); continue; }
    await useSpot(e.target);
  }
  return null;
}
async function afterReloadChecks(label, expect) {
  const s = await bootQA(false);
  const sv = s && s.save; sources.push({ label, source: sv && sv.source });
  note(`${label}: after reload the game loaded the save from: ${sv && sv.source}`);
  return s;
}
// ---------------------------------------------------------------- QA scenarios
async function runQA() {
  const s0 = await bootQA(true); await onboardQA(); await shot('00_home');
  ok('QA: an episode can be started', await openEpisode3());
  // ---- A: a clue
  const a = await playUntil(s => s.ep && s.ep.clues.includes('tx_1')); ok('A: the first transmission clue (tx_1) was gained', !!a);
  if (!a) return;
  const aStep = a.ep.step, aClues = a.ep.clues.length;
  await reloadNow('A (clue)');
  let s = await afterReloadChecks('A', null);
  ok('A: reload right after the clue: the clue is in the loaded save', !!s && s.progress.clues && s.progress.clues.includes('tx_1'), s ? JSON.stringify(s.progress.clues) : '');
  ok('A: nothing else was lost (clue count not lower)', !!s && (s.progress.clues || []).length >= aClues);
  await shot('01_after_reload_A');
  ok('A: the episode re-enters and the quest step is unchanged', await openEpisode3());
  s = await waitFor(s => s.ep && !s.ep.busy && !s.ep.dialogue, 60000);
  ok('A: resumed with the same quest step and the clue', !!s && s.ep.step === aStep && s.ep.clues.includes('tx_1'), s ? s.ep.step + ' vs ' + aStep : '');
  // ---- B: an objective update (after the third transmission the objective moves to the station terminal)
  const startObj = s.ep.objective;
  const b = await playUntil(x => x.ep && x.ep.step !== 'tx' && x.ep.objective !== startObj && x.ep.clues.includes('tx_3'), 300000);
  ok('B: the third transmission changed the objective', !!b, b ? b.ep.objective : '');
  if (!b) return;
  const bObj = b.ep.objective;
  await reloadNow('B (objective)');
  s = await afterReloadChecks('B', null);
  ok('B: reload right after the objective update: all three transmission clues are in the loaded save', !!s && ['tx_1', 'tx_2', 'tx_3'].every(c => (s.progress.clues || []).includes(c)));
  ok('B: the episode resumes with the updated objective', await openEpisode3());
  s = await waitFor(s => s.ep && !s.ep.busy && !s.ep.dialogue, 60000);
  ok('B: objective text identical after the reload', !!s && s.ep.objective === bObj, s ? s.ep.objective + ' vs ' + bObj : '');
  await shot('02_after_reload_B');
  // ---- C: a puzzle move (tower, signal resonator), from a QA-seeded save
  await closeModal(); await sleep(2500); await harvestAdd(); await page.goto(`http://localhost:${PORT}/index.html`); await sleep(1000); await waitFor(x => x.scene === 'home', 90000); await sleep(800);
  await page.evaluate(() => { window.__qa_cmd = 'seed_tower'; });
  await waitFor(x => x.progress && x.progress.zone === 'tower_1', 10000);
  const seeded = await waitFor(x => x.save.state === 'saved', 60000, 200); ok('C: the QA seed save became durable before the test action', !!seeded);
  ok('C: tower episode starts', await openEpisode3());
  const c0 = await playUntil(x => x.ep && x.ep.puzzle && x.ep.puzzle.kind === 'signal', 240000); ok('C: the signal puzzle opened', !!c0);
  if (!c0) return;
  const f0 = c0.ep.puzzle.state.freq, a0 = c0.ep.puzzle.state.amp;
  if (T) { const arrows = c0.ep.puzzle.buttons.filter(b => b.text === '<' || b.text === '>'); await tapRect(arrows[1]); } else await press('ArrowRight', 50);
  const c = await waitFor(x => x.ep && x.ep.puzzle && x.ep.puzzle.state.freq !== f0, 8000, 40);
  ok('C: one nudge changed the signal frequency', !!c, c ? f0 + ' to ' + c.ep.puzzle.state.freq : '');
  if (!c) return;
  const fNew = c.ep.puzzle.state.freq, aNew = c.ep.puzzle.state.amp;
  await reloadNow('C (puzzle move)');
  s = await afterReloadChecks('C', null);
  const saved = s && s.progress.puzzles && s.progress.puzzles.signal;
  ok('C: reload right after the puzzle move: the loaded save holds the moved board', !!saved && saved.freq === fNew && saved.amp === aNew, saved ? `freq ${saved.freq}/${fNew} amp ${saved.amp}/${aNew}` : 'no puzzle state');
  ok('C: tower episode re-enters', await openEpisode3());
  const c2 = await playUntil(x => x.ep && x.ep.puzzle && x.ep.puzzle.kind === 'signal', 120000);
  ok('C: reopening the resonator shows the moved board', !!c2 && c2.ep.puzzle.state.freq === fNew, c2 ? c2.ep.puzzle.state.freq + ' vs ' + fNew : '');
  await shot('03_after_reload_C');
  // ---- the "saved means stored" sampler, over the whole run
  await sleep(1500); await harvestAdd();
  ok('Report: the game said "saving" while IndexedDB had not confirmed (indicator worked)', tot.saving > 0, `${tot.saving} samples`);
  ok('Report: it never said "saved" while IndexedDB lacked that save', tot.viol === 0, `${tot.samples} saved-claims checked, ${tot.viol} violations`);
  ok('Report: no save stayed unconfirmed', tot.unc === 0, `${tot.unc} unconfirmed samples`);
  const raced = racePending.filter(r => r.pending === true).length;
  note(`race exercised: IndexedDB had NOT confirmed at ${raced} of ${racePending.length} immediate reloads; loaded from localStorage copy at ${sources.filter(x => x.source === 'mirror').length} of ${sources.length}`);
  ok('Report: the race was exercised (at least one immediate reload happened before IndexedDB confirmed)', raced >= 1, JSON.stringify(racePending));
}
// ---------------------------------------------------------------- production scenarios (no hook: verified from browser storage and the screen)
function pixelGold(file, gx, gy) {
  const p = G(gx, gy);
  const out = cp.execFileSync('python3', ['-I', '-c', 'import sys\nfrom PIL import Image\nim=Image.open(sys.argv[1]).convert("RGB")\nw,h=im.size\nsx=w/' + W + '\nx,y=int(float(sys.argv[2])*sx),int(float(sys.argv[3])*sx)\nr,g,b=im.getpixel((x,y))\nprint(r,g,b)', file, String(p.x), String(p.y)]).toString().trim().split(' ').map(Number);
  return out[0] > 200 && out[1] > 170 && out[2] < 190;   // the onboarding "BEGIN YOUR AWAKENING" button is gold
}
async function settle(pred, timeout = 60000) { const t = Date.now(); let st = null; while (Date.now() - t < timeout) { st = await readStores(); if (pred(st)) return st; await sleep(300); } return st; }
async function runProd() {
  await page.addInitScript(SAMPLER, KEY);                      // harmless without a hook (the game exposes no window.__qa in production)
  await page.goto(`http://localhost:${PORT}/index.html`); await sleep(10000);
  ok('Production: no QA hook (window.__qa undefined)', (await page.evaluate(() => typeof window.__qa)) === 'undefined');
  await shot('00_onboarding');
  ok('Production: first launch shows the onboarding button', pixelGold(`${OUT}/${TAG}_00_onboarding.png`, 620, 480));
  // ---- P1: onboarding choice (a save), reload immediately
  const f = G(620, 362); await page.mouse.click(f.x, f.y); await sleep(900); await page.keyboard.press('Control+A'); await sleep(300); await page.keyboard.type('Echolot', { delay: 150 }); await sleep(900); await shot('00b_name_typed');
  await tapG(620, 480);
  await page.waitForFunction(KEY => { try { return !!localStorage.getItem(KEY); } catch (e) { return false; } }, KEY, { timeout: 20000 });
  const p1 = await page.evaluate(() => { const p = window.__soul ? window.__soul.pending : null; setTimeout(() => location.reload(), 0); return p; });
  note(`P1 (onboarding): reloaded immediately; IndexedDB confirmation pending: ${p1}`); racePending.push({ label: 'P1', pending: p1 });
  await sleep(10000); await shot('01_after_onboarding_reload');
  ok('P1: after the reload the onboarding is NOT shown again (the game loaded the saved profile)', !pixelGold(`${OUT}/${TAG}_01_after_onboarding_reload.png`, 620, 480));
  let st = await settle(x => x.idb && x.idb.onboarded === true && x.idb.name === 'Echolot');
  ok('P1: browser storage ends with the chosen name and onboarded=true', !!st.idb && st.idb.onboarded === true && st.idb.name === 'Echolot', st.idb ? st.idb.name : 'none');
  // ---- P2: a setting, reload immediately
  await tapG(911, 597); await sleep(900);       // close the mission modal that opens after onboarding
  await tapG(1180, 53); await sleep(900); await tapG(640, 243); await sleep(150);   // SETTINGS, then the "Sound effects" switch
  await page.waitForFunction(KEY => { try { const e = JSON.parse(localStorage.getItem(KEY)); return JSON.parse(e.payload).settings.sound === false; } catch (e) { return false; } }, KEY, { timeout: 15000 }).catch(() => {});
  const m2 = await readStores(); ok('P2: the toggle was saved (localStorage copy has sound=false)', !!m2.mirror && m2.mirror.settings.sound === false);
  const p2 = await page.evaluate(() => { const p = window.__soul ? window.__soul.pending : null; setTimeout(() => location.reload(), 0); return p; });
  note(`P2 (setting): reloaded immediately; IndexedDB confirmation pending: ${p2}`); racePending.push({ label: 'P2', pending: p2 });
  await sleep(10000);
  st = await settle(x => x.idb && x.idb.settings && x.idb.settings.sound === false);
  ok('P2: browser storage ends with sound=false and the earlier name (nothing older came back)', !!st.idb && st.idb.settings.sound === false && st.idb.name === 'Echolot', st.idb ? JSON.stringify(st.idb.settings) : 'none');
  // ---- P3: Episode 1 progress (intro seen, then the first objective step), reload immediately
  await tapG(911, 597); await sleep(600);
  await tapG(290, 549); await sleep(1500);                                   // PLAY EPISODE (opens the mission card)
  await tapG(468, 588); await sleep(3500);                                   // BEGIN EPISODE 1
  for (let i = 0; i < 16; i++) { await advance(); await sleep(800); }        // title card + intro dialogue
  const step0 = (await readStores()).mirror; note('P3: after the intro the saved progress is ' + JSON.stringify(step0 && step0.mission_progress && step0.mission_progress['1-1']));
  ok('P3: the intro was saved (mission_progress 1-1 intro=true)', !!step0 && !!step0.mission_progress && !!step0.mission_progress['1-1'] && step0.mission_progress['1-1'].intro === true);
  // walk to Mira and talk until the objective step advances (step >= 1), reloading the moment it is seen
  await setMove(1); await sleep(T ? 2300 : 1800); await setMove(0); await sleep(300);
  let step = 0, tries = 0;
  while (step < 1 && tries < 24) { await act(); await sleep(500); for (let i = 0; i < 6; i++) { await advance(); await sleep(350); } const m = (await readStores()).mirror; step = m && m.mission_progress && m.mission_progress['1-1'] ? (m.mission_progress['1-1'].step || 0) : 0; tries++; if (step < 1) { const dir = (tries % 4 < 2) ? 1 : -1; await setMove(dir); await sleep(350); await setMove(0); await sleep(250); } }   // no hook in production: search left and right of the first guess for Mira
  ok('P3: talking to Mira advanced the objective step in the saved progress', step >= 1, 'step ' + step);
  const want = (await readStores()).mirror.mission_progress['1-1'];
  const p3 = await page.evaluate(() => { const p = window.__soul ? window.__soul.pending : null; setTimeout(() => location.reload(), 0); return p; });
  note(`P3 (objective step): reloaded immediately; IndexedDB confirmation pending: ${p3}`); racePending.push({ label: 'P3', pending: p3 });
  await sleep(10000); await shot('02_after_progress_reload');
  st = await settle(x => x.idb && x.idb.mission_progress && x.idb.mission_progress['1-1'] && (x.idb.mission_progress['1-1'].step || 0) >= (want.step || 0));
  const got = st.idb && st.idb.mission_progress && st.idb.mission_progress['1-1'];
  ok('P3: browser storage ends with the same objective step and the intro flag', !!got && (got.step || 0) >= (want.step || 0) && got.intro === true, JSON.stringify(got));
  ok('P3: settings and name from earlier survived too', !!st.idb && st.idb.settings.sound === false && st.idb.name === 'Echolot');
  const raced = racePending.filter(r => r.pending === true).length;
  note(`race exercised: IndexedDB had NOT confirmed at ${raced} of ${racePending.length} immediate reloads`);
  ok('Report: the race was exercised (at least one immediate reload happened before IndexedDB confirmed)', raced >= 1, JSON.stringify(racePending));
}
(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  ctx = await browser.newContext(T ? { viewport: { width: W, height: H }, hasTouch: true, isMobile: true, deviceScaleFactor: 2 } : { viewport: { width: W, height: H } });
  page = await ctx.newPage(); cdp = T ? await ctx.newCDPSession(page) : null;
  page.on('console', m => { if (m.type() === 'error') msgs.push(m.text()); }); page.on('pageerror', e => msgs.push('PAGEERR ' + e.message));
  T0 = Date.now();
  try { if (QA) await runQA(); else await runProd(); } catch (e) { ok('driver ran to the end', false, String(e && e.stack || e).slice(0, 300)); await shot('97_driver_error'); }
  const real = msgs.filter(m => !/Failed to load resource/.test(m));
  ok('No page errors or console errors', real.length === 0, JSON.stringify(real).slice(0, 300));
  await browser.close();
  const fails = results.filter(r => !r.c).length;
  fs.writeFileSync(`${OUT}/${TAG}_results.json`, JSON.stringify({ tag: TAG, flavor: FLAVOR, mode: MODE, w: W, h: H, seconds: Math.round((Date.now() - T0) / 1000), fails, results, log, racePending, sources, sampler: tot }, null, 1));
  console.log(`RESULT ${TAG}: ${fails} failures, ${results.length} checks, ${Math.round((Date.now() - T0) / 1000)}s`);
  process.exit(fails ? 1 : 0);
})();
