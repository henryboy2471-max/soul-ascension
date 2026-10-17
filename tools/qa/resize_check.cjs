// Window-resize check in Chromium against a "Web QA" export (Episode 3): resize mid-play (16:9 laptop, 4:3, portrait tablet), screenshot each, report console errors and whether the Hero keeps its on-screen place.
// usage: PORT=8801 node resize_check.cjs <outdir>
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const PORT = process.env.PORT || '8801'; const OUT = process.argv[2]; const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const br = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  const page = await (await br.newContext({ viewport: { width: 640, height: 360 } })).newPage();
  const msgs = []; page.on('console', m => { if (m.type() === 'error') msgs.push(m.text()); }); page.on('pageerror', e => msgs.push('PAGEERR ' + e.message));
  const S = () => page.evaluate(() => window.__qa || null);
  async function waitFor(pred, t) { const t0 = Date.now(); while (Date.now() - t0 < t) { const s = await S(); if (s && pred(s)) return s; await sleep(150); } return null; }
  let W = 640, H = 360; const tap = async b => { const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2; await page.mouse.click(ox + (b.x + b.w / 2) * kk, oy + (b.y + b.h / 2) * kk); await sleep(120); };
  await page.goto(`http://localhost:${PORT}/index.html`); await waitFor(s => s.scene === 'home', 90000); await sleep(1200);
  let s = await S(); const b = s.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tap(b); await sleep(2500); }
  for (let i = 0; i < 3; i++) { s = await S(); const c = s.buttons.find(x => x.text === 'CLOSE'); if (!c) break; await tap(c); await sleep(700); }
  s = await S(); await tap(s.buttons.find(x => x.text === 'MISSIONS')); s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000); await tap(s.buttons.find(b => b.text.startsWith('QA:')));
  await waitFor(s => s.scene === 'episode', 15000);
  for (let i = 0; i < 120; i++) { await page.evaluate(() => { window.__qa_tr = []; }); await sleep(900); const tr = await page.evaluate(() => window.__qa_tr || []); if (tr.length > 5 && tr.every(r => r[15] === 0)) break; await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter'); }
  await page.keyboard.down('d'); await sleep(1200);   // walking while the window changes size
  for (const [w, h, name] of [[1024, 576, '16x9_1024'], [800, 600, '4x3_800x600'], [600, 960, 'portrait_600x960'], [1366, 768, 'laptop_1366x768']]) {
    W = w; H = h; await page.setViewportSize({ width: w, height: h }); await sleep(2500);
    const tr = await page.evaluate(() => window.__qa_tr || []); const last = tr[tr.length - 1];
    await page.screenshot({ path: `${OUT}/resize_${name}.png` });
    console.log(`${name}: hero screen x ${last ? last[3].toFixed(1) : 'n/a'} y ${last ? last[4].toFixed(1) : 'n/a'}, speed ${last ? Math.abs(last[10]).toFixed(1) : 'n/a'}`);
    await page.evaluate(() => { window.__qa_tr = []; });
  }
  await page.keyboard.up('d'); await br.close(); console.log('console errors:', msgs.length, msgs.slice(0, 3));
})().catch(e => { console.error(e); process.exit(1); });
