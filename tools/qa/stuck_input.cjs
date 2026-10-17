// Stuck-input check in Chromium against a "Web QA" export (Episode 3): does the Hero keep walking after (a) a touch is CANCELLED (ChromeOS palm rejection), (b) the window loses focus while a key is held, (c) the tab is hidden?
// usage: PORT=8801 node stuck_input.cjs
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const PORT = process.env.PORT || '8801'; const W = 844, H = 390; const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2; const G = (x, y) => ({ x: ox + x * kk, y: oy + y * kk });
(async () => {
  const br = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  const ctx = await br.newContext({ viewport: { width: W, height: H }, hasTouch: true, isMobile: true, deviceScaleFactor: 1 }); const page = await ctx.newPage(); const cdp = await ctx.newCDPSession(page);
  const S = () => page.evaluate(() => window.__qa || null); const vel = async () => { await page.evaluate(() => { window.__qa_tr = []; }); await sleep(1300); const t = await page.evaluate(() => window.__qa_tr || []); return t.length ? Math.abs(t[t.length - 1][10]) : NaN; };
  const tapRect = async b => { const p = G(b.x + b.w / 2, b.y + b.h / 2); await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: p.x, y: p.y, id: 1 }] }); await sleep(80); await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] }); await sleep(120); };
  async function waitFor(pred, t) { const t0 = Date.now(); while (Date.now() - t0 < t) { const s = await S(); if (s && pred(s)) return s; await sleep(150); } return null; }
  await page.goto(`http://localhost:${PORT}/index.html`); await waitFor(s => s.scene === 'home', 90000); await sleep(1200);
  let s = await S(); const b = s.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tapRect(b); await sleep(2500); }
  for (let i = 0; i < 3; i++) { s = await S(); const c = s.buttons.find(x => x.text === 'CLOSE'); if (!c) break; await tapRect(c); await sleep(700); }
  s = await S(); await tapRect(s.buttons.find(x => x.text === 'MISSIONS')); s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000); await tapRect(s.buttons.find(b => b.text.startsWith('QA:')));
  await waitFor(s => s.scene === 'episode', 15000);
  for (let i = 0; i < 120; i++) { await page.evaluate(() => { window.__qa_tr = []; }); await sleep(900); const tr = await page.evaluate(() => window.__qa_tr || []); if (tr.length > 5 && tr.every(r => r[15] === 0)) break; await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter'); }
  await sleep(1500);
  const res = [];
  const check = (name, v, expectStopped) => { const ok = expectStopped ? v < 3 : v > 60; res.push({ name, v, ok }); console.log((ok ? 'PASS: ' : 'FAIL: ') + name + `  (hero speed ${v.toFixed(1)} px/s)`); };
  // (a) touch: drag the stick, confirm walking, then CANCEL the touch (no touchEnd)
  const c = G(126, 610), t = G(186, 610);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: c.x, y: c.y, id: 1 }] }); await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: t.x, y: t.y, id: 1 }] });
  check('touch drag walks the Hero', await vel(), false);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchCancel', touchPoints: [] });
  check('after the touch is CANCELLED (palm rejection) the Hero stops', await vel(), true);
  // (b) keyboard: hold D, then lose window focus without a keyup
  await page.keyboard.down('d'); check('holding D walks the Hero', await vel(), false);
  // the window loses focus while it stays visible (a ChromeOS overlay, a notification, alt-tab on a large window): a real keyup would never reach the game
  await page.evaluate(() => { window.dispatchEvent(new Event('blur')); const c = document.querySelector('canvas'); if (c) c.dispatchEvent(new Event('blur')); });
  check('after the window loses focus with D still down the Hero stops (input released on focus loss)', await vel(), true);
  await page.keyboard.up('d');
  await br.close(); const bad = res.filter(r => !r.ok).length; console.log(bad ? `${bad} stuck-input problem(s)` : 'no stuck input'); process.exit(bad ? 1 : 0);
})().catch(e => { console.error(e); process.exit(2); });
