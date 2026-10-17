// Stillness footage in Chromium against a "Web QA" export: the Hero (and Mira in Episode 3) stands still while the page is photographed repeatedly.
// Writes <outdir>/<tag>_NN.png crops (hero, then companion) plus <tag>_stats.json, read by tools/qa/idle_report.py. Also records the engine's per-frame node positions (QA hook probe).
// usage: PORT=8801 EP=1|2|3 [DPR=2] [WALK=1|TRANS=1] [ZONE=station] SECS=30 node idle_footage.cjs <outdir> <tag> [w h]
const { chromium } = require(process.env.PW || '/home/user/my-app/node_modules/@playwright/test');
const fs = require('fs');
const [,, OUT, TAG, WS = '640', HS = '360'] = process.argv; const W = +WS, H = +HS; const PORT = process.env.PORT || '8801'; const EP = process.env.EP || '3'; const SECS = +(process.env.SECS || 30);
const sleep = ms => new Promise(r => setTimeout(r, ms));
const kk = Math.min(W / 1280, H / 720), ox = (W - 1280 * kk) / 2, oy = (H - 720 * kk) / 2; const G = (x, y) => ({ x: ox + x * kk, y: oy + y * kk });
let page; const S = () => page.evaluate(() => window.__qa || null);
async function waitFor(pred, t, st = 150) { const t0 = Date.now(); while (Date.now() - t0 < t) { const s = await S(); if (s && pred(s)) return s; await sleep(st); } return null; }
async function tapRect(b) { const p = G(b.x + b.w / 2, b.y + b.h / 2); await page.mouse.click(p.x, p.y); await sleep(80); }
(async () => {
  const br = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });
  const ctx = await br.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: +(process.env.DPR || 1), recordVideo: { dir: OUT, size: { width: W, height: H } } });
  page = await ctx.newPage();
  await page.goto(`http://localhost:${PORT}/index.html`); await waitFor(s => s.scene === 'home', 90000); await sleep(1200);
  let s = await S(); const b = s.buttons.find(x => x.text.startsWith('BEGIN YOUR')); if (b) { await tapRect(b); await sleep(2500); }
  for (let i = 0; i < 3; i++) { s = await S(); const c = s.buttons.find(x => x.text === 'CLOSE'); if (!c) break; await tapRect(c); await sleep(700); }
  s = await S(); await tapRect(s.buttons.find(x => x.text === 'MISSIONS'));
  s = await waitFor(s => s.buttons.some(b => b.text.startsWith('QA:')), 8000);
  if (EP === '2') {   // Episode 2 needs 1-1 cleared: the QA hook's seed (Episodes 1-2 cleared) through the normal Profile API
    await page.evaluate(() => { window.__qa_cmd = 'seed_tower'; }); await sleep(1500);
    s = await S(); await tapRect(s.buttons.find(x => x.text === 'CLOSE')); await sleep(800);   // reopen the list so it shows the seeded progress
    s = await S(); await tapRect(s.buttons.find(x => x.text === 'MISSIONS')); await sleep(1500); s = await S();
    await tapRect(s.buttons.find(b => b.text === 'PLAY EPISODE 2')); s = await waitFor(s => s.buttons.some(b => /^BEGIN EPISODE|^PLAY|^RESUME|^REPLAY|^START/.test(b.text)), 8000);
    const go = s && s.buttons.find(b => /^(BEGIN EPISODE 2|REPLAY|START|RESUME)/.test(b.text)); if (go) await tapRect(go);
  } else if (EP === '3') { await tapRect(s.buttons.find(b => b.text.startsWith('QA:'))); }
  else if (EP === '1') { await tapRect(s.buttons.find(b => b.text === 'PLAY EPISODE 1')); s = await waitFor(s => s.buttons.some(b => b.text === 'BEGIN EPISODE 1'), 8000); await tapRect(s.buttons.find(b => b.text === 'BEGIN EPISODE 1')); }
  await waitFor(s => s.scene === 'episode', 15000);
  for (let i = 0; i < 120; i++) {   // advance dialogue until the probe reports an unlocked exploration scene
    await page.evaluate(() => { window.__qa_tr = []; }); await sleep(900);
    const tr = await page.evaluate(() => window.__qa_tr || []);
    if (tr.length > 5 && tr.every(r => r[15] === 0)) break;
    await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter');
  }
  await sleep(3000);   // let the camera settle
  await page.evaluate(() => { window.__qa_tr = []; });
  if (process.env.ZONE) { await page.evaluate(z => { window.__qa_cmd = 'zone:' + z; }, process.env.ZONE); await sleep(2500); for (let i = 0; i < 40; i++) { const t = await page.evaluate(() => window.__qa_tr || []); if (t.length > 3 && t.every(r => r[15] === 0)) break; await page.keyboard.down('Enter'); await sleep(50); await page.keyboard.up('Enter'); await sleep(500); } await sleep(2500); }
  // WALK=1: hold D (walk right) for 9 s first, so the camera is following, and record the walk instead of standing
  if (process.env.WALK === '1') { await page.keyboard.down('d'); await sleep(9000); }
  // the Hero stands still: one probe read for where to crop, then the page is simply recorded for SECS seconds
  await sleep(900);   // the probe refills its batch every 0.5 s
  const tr0 = await page.evaluate(() => window.__qa_tr || []); const last = tr0[tr0.length - 1];
  const hx = last[3] * kk + ox, hy = last[4] * kk + oy, mx = last[5] * kk + ox;
  const wide = process.env.WALK === '1' ? 1.6 : 1; const rect = { x: Math.max(0, Math.round(hx - 70 * wide * kk)), y: Math.max(0, Math.round(hy - 230 * kk)), width: Math.round(150 * wide * kk), height: Math.round(250 * kk) };
  if (process.env.TRANS === '1' || process.env.WALK === '1') { rect.x = Math.max(0, Math.round(hx - 60 * kk)); rect.width = Math.round(330 * kk); }   // the Hero walks ~135 px during the sequence
  const nx = last[16] !== undefined && last[16] > 0 ? last[16] * kk + ox : null;   // first extra NPC (Anselm, Teo, the Warden) when the zone has one
  const rectNpc = nx === null ? null : { x: Math.max(0, Math.round(nx - 70 * kk)), y: rect.y, width: rect.width, height: rect.height };
  const rectMira = { x: Math.max(0, Math.round(mx - 70 * kk)), y: rect.y, width: rect.width, height: rect.height };
  await page.evaluate(() => { window.__qa_tr = []; }); const tStart = Date.now(); const events = [];
  if (process.env.TRANS === '1') {
    // stand 1 s, walk right 1.5 s, stop, stand 1.5 s, walk left 1.5 s (turn), stop, stand 1.5 s: transitions for tools/qa/transition_report.py
    const at = n => events.push({ t: (Date.now() - tStart) / 1000, n });
    await sleep(1000); at('walk right'); await page.keyboard.down('d'); await sleep(1500); at('stop'); await page.keyboard.up('d');
    await sleep(1500); at('walk left (turn)'); await page.keyboard.down('a'); await sleep(1500); at('stop'); await page.keyboard.up('a'); await sleep(1500);
    fs.writeFileSync(`${OUT}/${TAG}_events.json`, JSON.stringify(events));
  } else await sleep(SECS * 1000);
  const tr = await page.evaluate(() => window.__qa_tr || []);
  if (process.env.WALK === '1') await page.keyboard.up('d');
  const vpath = await page.video().path();
  await ctx.close();
  fs.renameSync(vpath, `${OUT}/${TAG}.webm`);
  fs.writeFileSync(`${OUT}/${TAG}_stats.json`, JSON.stringify({ W, H, EP, SECS, rect, rectMira, rectNpc, startedMs: tStart, trace: tr }));
  console.log('recorded', SECS, 's; trace rows', tr.length, 'hero crop', JSON.stringify(rect));
  await br.close();
})().catch(e => { console.error(e); process.exit(1); });
