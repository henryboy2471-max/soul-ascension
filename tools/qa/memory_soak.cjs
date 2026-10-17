// Memory-growth check in Chromium against a "Web QA" export: stand in an exploration scene, then walk back and forth, sampling the renderer process RSS and JS heap.
// usage: PORT=8801 EP=1|3 MINUTES=3 node memory_soak.cjs <outdir> [w h]
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const { execSync } = require('child_process'); const fs = require('fs');
const [,, OUT, WS = '480', HS = '270'] = process.argv; const W = +WS, H = +HS; const PORT = process.env.PORT || '8801'; const EP = process.env.EP || '3'; const MIN = +(process.env.MINUTES || 3);
const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2; const G = (x, y) => ({ x: ox + x * kk, y: oy + y * kk });
let page; const S = () => page.evaluate(() => window.__qa || null);
async function waitFor(pred, t, st = 150) { const t0 = Date.now(); while (Date.now() - t0 < t) { const s = await S(); if (s && pred(s)) return s; await sleep(st); } return null; }
async function tapRect(b) { const p = G(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.click(p.x, p.y); await sleep(80); }
function rssMB() { try { return +execSync("ps -eo rss,args | grep '[c]hrome-linux/chrome' | grep -- '--type=renderer' | sort -rn | head -1 | awk '{print $1}'").toString().trim() / 1024; } catch (e) { return NaN; } }
(async () => {
  const br = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  page = await (await br.newContext({ viewport: { width: W, height: H } })).newPage(); const cdp = await page.context().newCDPSession(page);
  await page.goto(`http://localhost:${PORT}/index.html`); await waitFor(s => s.scene === 'home', 90000); await sleep(1200);
  let s = await S(); const b = s.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tapRect(b); await sleep(2500); }
  for (let i = 0; i < 3; i++) { s = await S(); const c = s.buttons.find(x => x.text === 'CLOSE'); if (!c) break; await tapRect(c); await sleep(700); }
  s = await S(); await tapRect(s.buttons.find(x => x.text === 'MISSIONS')); s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000);
  if (EP === '3') await tapRect(s.buttons.find(b => b.text.startsWith('QA:'))); else { await tapRect(s.buttons.find(b => b.text === 'PLAY EPISODE 1')); s = await waitFor(s => s.buttons.some(b => b.text === 'BEGIN EPISODE 1'), 8000); await tapRect(s.buttons.find(b => b.text === 'BEGIN EPISODE 1')); }
  await waitFor(s => s.scene === 'episode', 15000);
  for (let i = 0; i < 120; i++) { await page.evaluate(() => { window.__qa_tr = []; }); await sleep(900); const tr = await page.evaluate(() => window.__qa_tr || []); if (tr.length > 5 && tr.every(r => r[15] === 0)) break; await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter'); }
  const rows = []; const t0 = Date.now(); let dir = 'd';
  while ((Date.now() - t0) / 60000 < MIN) {
    const m = await cdp.send('Performance.getMetrics').catch(() => null); const heap = m ? m.metrics.find(x => x.name === 'JSHeapUsedSize').value / 1048576 : NaN;
    rows.push({ t: Math.round((Date.now() - t0) / 1000), rss_mb: Math.round(rssMB()), js_heap_mb: +heap.toFixed(1) });
    // alternate 6 s standing and 3 s walking (turning each time) so the transition code runs repeatedly
    await sleep(6000); await page.keyboard.down(dir); await sleep(3000); await page.keyboard.up(dir); dir = dir === 'd' ? 'a' : 'd';
  }
  fs.writeFileSync(`${OUT}/memory_ep${EP}.json`, JSON.stringify(rows)); console.log(rows.map(r => `${r.t}s rss ${r.rss_mb} MB heap ${r.js_heap_mb} MB`).join('\n'));
  await br.close();
})().catch(e => { console.error(e); process.exit(1); });
