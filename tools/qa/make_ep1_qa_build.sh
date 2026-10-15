#!/bin/bash
# Throwaway QA web build of the current tree: patches the QA state hook into main.gd and seeds an onboarded profile, then exports to $OUT (default /tmp/ep1qa_web).
# Never commit the patched copy. Needs godot 4.4.1 + web export templates (set XDG_DATA_HOME to the folder holding them).
set -e
SRC=${SRC:-$(cd "$(dirname "$0")/../.." && pwd)}; DST=${DST:-/tmp/ep1qa}; OUT=${OUT:-/tmp/ep1qa_web}; G=${G:-godot}
rm -rf $DST $OUT; mkdir -p $DST $OUT
(cd $SRC && tar --exclude=.git --exclude=.godot --exclude=build -cf - .) | tar -xf - -C $DST
python3 - "$SRC" "$DST" <<'PY'
import sys,re
src,dst=sys.argv[1:3]
hook=open(src+"/tools/qa/main_qa_hook.gd.txt").read().split("\n")
a=next(i for i,l in enumerate(hook) if l.startswith("func qa_rect"))
b=next(i for i,l in enumerate(hook) if l.startswith("func _process"))
block="\n".join(hook[a:b])+"\n"
# extra Episode 1 camera/explore telemetry
block=block.replace('   d["busy"]=n.busy\n','   d["busy"]=n.busy\n   if "explore" in n and is_instance_valid(n.explore):\n    d["cam"]=n.explore.cam\n    d["px"]=n.explore.px\n    d["layer"]=n.explore.layers[4].position.x\n    d["ppos"]=n.explore.player.position.x\n    d["locked"]=n.explore.locked\n    d["spot"]=n.explore.active_spot.get("id","") if not n.explore.active_spot.is_empty() else ""\n',1)
p=dst+"/scripts/ui/main.gd"; s=open(p).read()
s=s.replace("func _process(delta:float) -> void:\n",block+"func _process(delta:float) -> void:\n qa_state()\n",1)
open(p,"w").write(s)
p=dst+"/scripts/core/profile.gd"; s=open(p).read()
s=s.replace('"onboarded":false,"level":1','"onboarded":true,"level":4',1)
open(p,"w").write(s)
PY
cd $DST && $G --headless --editor --import --quit >/dev/null 2>&1; $G --headless --path . --export-release Web $OUT/index.html 2>&1 | tail -1
ls -la $OUT/index.pck
