#!/usr/bin/env python3
"""Release-gate guard: the production Web preset can never carry the QA flavor, and the release workflow can only build that production preset.
Checks export_presets.cfg and .github/workflows/*.yml (static; no Godot needed). Exit 0 = all good."""
import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
bad = []
def check(ok, msg):
    print(("PASS: " if ok else "FAIL: ") + msg)
    if not ok: bad.append(msg)
cfg = (root / "export_presets.cfg").read_text()
presets = {}
for m in re.finditer(r'\[preset\.(\d+)\]\n(.*?)(?=\n\[preset\.\d+\.options\])', cfg, re.S):
    kv = dict(re.findall(r'^(\w+)="(.*)"$', m.group(2), re.M))
    presets[kv.get("name")] = kv
prod, qa = presets.get("Web"), presets.get("Web QA")
check(prod is not None and qa is not None, 'both a production "Web" and a "Web QA" preset exist')
if prod and qa:
    check("qa_unlock" not in prod["custom_features"], 'production "Web" preset does not carry the qa_unlock feature')
    check("qa_unlock" in qa["custom_features"].split(","), '"Web QA" preset carries qa_unlock')
    check("scripts/qa/*" in prod["exclude_filter"].split(","), 'production "Web" preset excludes scripts/qa/* (the QA hook is not packaged)')
    check("scripts/qa/*" not in qa["exclude_filter"].split(","), '"Web QA" preset packages scripts/qa/*')
    check(prod["export_path"] == "build/web/index.html", 'production preset exports to build/web (what the Pages workflow uploads)')
    check(qa["export_path"].startswith("build/web_qa/") and not qa["export_path"].startswith("build/web/"), '"Web QA" exports to build/web_qa, never into the published build/web')
for n, kv in presets.items():
    if n not in ("Web QA",):
        check("qa_unlock" not in kv.get("custom_features", ""), f'preset "{n}" is free of the qa_unlock feature')
wf = sorted((root / ".github" / "workflows").glob("*.y*ml"))
check(len(wf) > 0, "workflow files found")
for f in wf:
    t = f.read_text()
    check("Web QA" not in t and "web_qa" not in t and "qa_unlock" not in t, f"{f.name} never mentions the QA flavor")
    for m in re.finditer(r'--export-(\w+)\s+"([^"]+)"', t):
        android_debug = f.name == "android-debug-apk.yml" and m.group(1) == "debug" and m.group(2) == "Android"
        check(m.group(2) in ("Web",) or android_debug, f'{f.name}: export preset "{m.group(2)}" is the production preset or the Android debug build')
apk = root / ".github/workflows/android-debug-apk.yml"
if apk.exists():
    t = apk.read_text()
    check(not re.search(r"pages:\s*write|id-token:\s*write|deploy-pages|upload-pages-artifact|\$\{\{\s*secrets\.", t), "android-debug-apk.yml has no Pages, deploy or secrets access")
pages = (root / ".github/workflows/web-preview.yml").read_text()
check('--export-release "Web"' in pages and "--export-debug" not in pages, 'web-preview.yml exports the production preset with --export-release only')
check("path: build/web" in pages.replace("'", "").replace('"', "") or "build/web" in pages, "web-preview.yml publishes build/web")
check("test_release_gate.py" in pages, "web-preview.yml runs this guard before exporting")
sys.exit(1 if bad else 0)
