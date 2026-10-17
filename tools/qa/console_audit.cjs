// Console audit in Chromium against a "Web QA" export: every console message (all types) plus page errors and failed requests, during boot, the Missions screen and the start of Episodes 1, 2 and 3.
// usage: PORT=8801 node console_audit.cjs
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const PORT = process.env.PORT || '8801'; const W = 800, H = 450; const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720);
(async () => {
  const br = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  const page = await (await br.newContext({ viewport: { width: W, height: H } })).newPage();
  const seen = {}; const note = (t, x) => { const k = t + ': ' + x.replace(/\d+(\.\d+)?/g, 'N').slice(0, 160); seen[k] = (seen[k] || 0) + 1; };
  page.on('console', m => note(m.type(), m.text())); page.on('pageerror', e => note('PAGEERROR', e.message)); page.on('requestfailed', r => note('REQUESTFAILED', r.url().replace(/^.*\//, '') + ' ' + (r.failure() || {}).errorText));
  page.on('response', r => { if (r.status() >= 400) note('HTTP' + r.status(), r.url().replace(/^.*\//, '')); });
  const S = () => page.evaluate(() => window.__qa || null);
  async function waitFor(pred, t) { const t0 = Date.now(); while (Date.now() - t0 < t) { const s = await S(); if (s && pred(s)) return s; await sleep(150); } return null; }
  const tap = async b => { await page.mouse.click((b.x + b.w / 2) * kk, (b.y + b.h / 2) * kk + (H - 720 * kk) / 2); await sleep(150); };
  await page.goto(`http://localhost:${PORT}/index.html`); await waitFor(s => s.scene === 'home', 90000); await sleep(1200);
  let s = await S(); const b = s.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tap(b); await sleep(2500); }
  for (let i = 0; i < 3; i++) { s = await S(); const c = s.buttons.find(x => x.text === 'CLOSE'); if (!c) break; await tap(c); await sleep(700); }
  await page.evaluate(() => { window.__qa_cmd = 'seed_tower'; }); await sleep(1500);
  for (const which of ['PLAY EPISODE 1', 'PLAY EPISODE 2', 'QA: PLAY EPISODE 3']) {
    s = await S(); await tap(s.buttons.find(x => x.text === 'MISSIONS')); s = await waitFor(s => s.buttons.some(b => b.text === which), 8000);
    await tap(s.buttons.find(b => b.text === which)); s = await waitFor(s => s.buttons.some(b => /^(BEGIN EPISODE|REPLAY|START|RESUME)/.test(b.text)) || s.scene === 'episode', 6000);
    const go = s && s.buttons.find(b => /^(BEGIN EPISODE|REPLAY|START|RESUME)/.test(b.text)); if (go) await tap(go);
    await waitFor(s => s.scene === 'episode', 15000);
    for (let i = 0; i < 25; i++) { await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter'); await sleep(350); }
    await page.keyboard.down('d'); await sleep(2000); await page.keyboard.up('d'); await sleep(500);
    console.log('visited', which, 'scene', (await S()).scene);
    // back to home: reload keeps the save and returns to the home screen
    await page.reload(); await waitFor(s => s.scene === 'home', 90000); await sleep(1500); for (let i = 0; i < 3; i++) { s = await S(); const c = s.buttons.find(x => x.text === 'CLOSE'); if (!c) break; await tap(c); await sleep(700); }
  }
  console.log('--- console / page / network messages (numbers normalised):'); for (const [k, v] of Object.entries(seen).sort((a, b) => b[1] - a[1])) console.log(String(v).padStart(4), k);
  await br.close();
})().catch(e => { console.error(e); process.exit(1); });
