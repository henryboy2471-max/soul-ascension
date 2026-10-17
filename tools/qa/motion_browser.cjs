// Movement-smoothness probe in Chromium against a "Web QA" export. Records, per rendered frame, the engine delta and the on-screen positions (scripts/qa/qa_hook.gd probe),
// plus the browser's own requestAnimationFrame intervals, while the Hero walks in every direction in an Episode 1 and an Episode 3 exploration scene.
// usage: PORT=8801 EP=3|1 node motion_browser.cjs <outdir> <tag> [w h] [cpu-throttle]     (writes <outdir>/<tag>_motion.json, then run tools/qa/motion_report.py on it)
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const fs = require('fs');
const [,, OUT, TAG, WS = '1280', HS = '720', THR = '1'] = process.argv; const W = +WS, H = +HS; const PORT = process.env.PORT || '8801';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2;
const G = (gx, gy) => ({ x: ox + gx * kk, y: oy + gy * kk });
let page, cdp;
const S = () => page.evaluate(() => window.__qa || null);
async function waitFor(pred, timeout, step = 150) { const t = Date.now(); while (Date.now() - t < timeout) { const s = await S(); if (s && pred(s)) return s; await sleep(step); } return null; }
async function tapRect(b) { const p = G(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.click(p.x, p.y); await sleep(80); }
async function closeModal() { for (let i = 0; i < 3; i++) { const m = await S(); const c = m && m.buttons.find(x => x.text === 'CLOSE'); if (!c) return; await tapRect(c); await sleep(700); } }
async function hold(keys, ms) { for (const k of keys) await page.keyboard.down(k); await sleep(ms); for (const k of keys) await page.keyboard.up(k); }
async function advanceUntilFree(timeout = 40000) {
  const t = Date.now();
  while (Date.now() - t < timeout) {
    const s = await S();
    if (s && s.ep && !s.ep.dialogue && !s.ep.busy && !s.ep.traveling && !s.ep.locked && !s.ep.puzzle) return s;
    await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter'); await sleep(250);
  }
  return null;
}
// one scripted walk: right, stop, idle, left, stop, idle, diagonal up-right, down-left, stop
async function walkScript(label, out) {
  const rec = async (name, fn) => { await page.evaluate(n => { window.__qa_tr = []; window.__raf = []; window.__seg = n; }, name); await fn(); await sleep(700); const d = await page.evaluate(() => ({ tr: window.__qa_tr || [], raf: window.__raf || [] })); out.push({ scene: label, seg: name, ...d }); };
  await rec('idle_start', () => sleep(1500));
  await rec('right', () => hold(['d'], 2600));
  await rec('idle_after_right', () => sleep(1500));
  await rec('left', () => hold(['a'], 2600));
  await rec('idle_after_left', () => sleep(1500));
  await rec('diag_up_right', () => hold(['d', 'w'], 1800));
  await rec('diag_down_left', () => hold(['a', 's'], 1800));
  await rec('travel', () => hold(['d'], 5000));   // 5 s of walking right: real distance covered per second
  await rec('stop_and_go', async () => { for (let i = 0; i < 4; i++) { await hold(['d'], 350); await sleep(250); } });
}
(async () => {
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  const ctx = await browser.newContext({ viewport: { width: W, height: H } });
  page = await ctx.newPage();
  cdp = await ctx.newCDPSession(page);
  if (+THR > 1) await cdp.send('Emulation.setCPUThrottlingRate', { rate: +THR });
  await page.addInitScript(() => { window.__raf = []; let last = performance.now(); const tick = t => { window.__raf.push(+(t - last).toFixed(2)); last = t; requestAnimationFrame(tick); }; requestAnimationFrame(tick); });
  const msgs = []; page.on('console', m => { if (m.type() === 'error') msgs.push(m.text()); }); page.on('pageerror', e => msgs.push('PAGEERR ' + e.message));
  await page.goto(`http://localhost:${PORT}/index.html`);
  let s = await waitFor(s => s.scene === 'home', 90000); if (!s) throw new Error('no home');
  await sleep(1200);
  const ob = await S(); const b = ob.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tapRect(b); await sleep(2500); }
  await closeModal();
  const out = [];
  const m = (await S()).buttons.find(b => b.text === 'MISSIONS'); await tapRect(m);
  s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000);
  fs.writeFileSync(`${OUT}/${TAG}_missions_buttons.json`, JSON.stringify(s.buttons));
  const EP = process.env.EP || '3';
  if (EP === '3') {
    await tapRect(s.buttons.find(b => b.text.startsWith('QA:')));
    await waitFor(s => s.scene === 'episode', 15000);
    s = await advanceUntilFree(60000);
    if (!s) throw new Error('episode 3 never became walkable');
  } else {
    // Episode 1 has no state snapshot in the hook: it is walkable once the frame probe reports an unlocked exploration scene
    await tapRect(s.buttons.find(b => b.text === 'PLAY EPISODE 1'));
    s = await waitFor(s => s.buttons.some(b => b.text === 'BEGIN EPISODE 1'), 8000);
    await tapRect(s.buttons.find(b => b.text === 'BEGIN EPISODE 1'));
    await waitFor(s => s.scene === 'episode', 15000);
    let free = false;
    for (let i = 0; i < 120 && !free; i++) {
      await page.evaluate(() => { window.__qa_tr = []; }); await sleep(900);
      const tr = await page.evaluate(() => window.__qa_tr || []);
      free = tr.length > 5 && tr.every(r => r[15] === 0);
      if (!free) { await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter'); }
    }
    if (!free) throw new Error('episode 1 never became walkable');
    s = { ep: { zone: 'ep1' } };
  }
  await sleep(800);
  await walkScript('episode' + EP + '_' + s.ep.zone, out);
  fs.writeFileSync(`${OUT}/${TAG}_motion.json`, JSON.stringify({ W, H, thr: +THR, out, msgs }));
  console.log('wrote', out.length, 'segments; console errors:', msgs.length);
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
