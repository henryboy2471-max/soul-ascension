// Render-cost experiment: hide one group of exploration nodes at a time (qa_hook cull) and report the mean frame time while idle.
// usage: PORT=8801 node cost_browser.cjs <w> <h> [ep3|ep1]
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const [,, WS = '480', HS = '270'] = process.argv; const W = +WS, H = +HS; const PORT = process.env.PORT || '8801';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2; const G = (x, y) => ({ x: ox + x * kk, y: oy + y * kk });
let page; const S = () => page.evaluate(() => window.__qa || null);
async function waitFor(pred, t, st = 150) { const t0 = Date.now(); while (Date.now() - t0 < t) { const s = await S(); if (s && pred(s)) return s; await sleep(st); } return null; }
async function tapRect(b) { const p = G(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.click(p.x, p.y); await sleep(80); }
(async () => {
  const br = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  page = await (await br.newContext({ viewport: { width: W, height: H } })).newPage();
  await page.goto(`http://localhost:${PORT}/index.html`); await waitFor(s => s.scene === 'home', 90000); await sleep(1200);
  let s = await S(); const b = s.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tapRect(b); await sleep(2500); }
  for (let i = 0; i < 3; i++) { s = await S(); const c = s.buttons.find(x => x.text === 'CLOSE'); if (!c) break; await tapRect(c); await sleep(700); }
  s = await S(); await tapRect(s.buttons.find(x => x.text === 'MISSIONS'));
  s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000); await tapRect(s.buttons.find(b => b.text.startsWith('QA:')));
  await waitFor(s => s.scene === 'episode', 15000);
  for (let i = 0; i < 80; i++) { s = await S(); if (s && s.ep && !s.ep.dialogue && !s.ep.busy && !s.ep.traveling && !s.ep.locked) break; await page.keyboard.press('Enter'); await sleep(300); }
  await sleep(800);
  for (const g of ['none', 'layers', 'props', 'fore', 'fighters', 'atmo', 'floor', 'hud', 'none']) {
    await page.evaluate(g => { window.__qa_cmd = 'hide:' + g; window.__qa_tr = []; }, g); await sleep(1200);
    await page.evaluate(() => { window.__qa_tr = []; }); await sleep(3000);
    const tr = await page.evaluate(() => window.__qa_tr || []); const dt = tr.map(r => r[0]).sort((a, b) => a - b);
    const mean = dt.reduce((a, c) => a + c, 0) / dt.length;
    console.log(g.padEnd(9), 'frames', String(dt.length).padStart(3), 'mean', mean.toFixed(1), 'ms  p95', dt[Math.floor(dt.length * .95)].toFixed(1), ' draws', tr[tr.length - 1][12], ' prims', tr[tr.length - 1][13]);
  }
  await br.close();
})().catch(e => { console.error(e); process.exit(1); });
