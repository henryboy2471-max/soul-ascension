#!/bin/bash
# wait for the headless regression to finish, then build lossless / S3TC-only / ETC2-only web variants of the RC tree and run the browser matrix
while ! grep -q REGRESSDONE /tmp/regress_rc.log; do sleep 5; done
export XDG_DATA_HOME=/tmp/xdg_h2; G=$HOME/bin/godot; SRC=/home/user/soul-ascension
mk() { # name profile hook desktop mobile mode
  rm -rf /tmp/$1 /tmp/$1_web; mkdir -p /tmp/$1_web
  mkdir /tmp/$1; (cd $SRC && tar --exclude=.git --exclude=.godot -cf - .) | tar -xf - -C /tmp/$1
  cp $3 /tmp/$1/scripts/ui/main.gd; cp $2 /tmp/$1/scripts/core/profile.gd
  sed -i "s#vram_texture_compression/for_desktop=.*#vram_texture_compression/for_desktop=$4#; s#vram_texture_compression/for_mobile=.*#vram_texture_compression/for_mobile=$5#" /tmp/$1/export_presets.cfg
  [ "$6" = lossless ] && sh /tmp/$1/tools/set_cantor_textures.sh lossless >/dev/null
  (cd /tmp/$1 && $G --headless --editor --import --quit >/dev/null 2>&1; $G --headless --path . --export-release Web /tmp/$1_web/index.html >/tmp/$1_export.log 2>&1)
  ls -la /tmp/$1_web/index.pck | awk '{print $5}' > /tmp/$1_pck.txt
}
mk vL /tmp/profile_qa.gd /tmp/main_qa_hook2.gd true false lossless
mk vS /tmp/profile_qa.gd /tmp/main_qa_hook2.gd true false vram
mk vE /tmp/profile_qa.gd /tmp/main_qa_hook2.gd false true vram
mk vL1 /tmp/profile_e1b.gd /tmp/main_qa_hook2.gd true false lossless
for pair in "vL 8780" "vS 8781" "vE 8782" "vL1 8783"; do set -- $pair; (cd /tmp/$1_web && python3 -m http.server $2 >/dev/null 2>&1 &); done
sleep 2
cd /tmp/v21qa; mkdir -p matrix; S=/tmp/v21qa/matrix
PORT=8780 node perf.cjs $S key 1280 720 L_kb > matrix/L_kb.log 2>&1
PORT=8781 node perf.cjs $S key 1280 720 S_kb > matrix/S_kb.log 2>&1
PORT=8782 node perf.cjs $S key 1280 720 E_kb > matrix/E_kb.log 2>&1
PORT=8780 node perf.cjs $S touch 844 390 L_t844 > matrix/L_t844.log 2>&1
PORT=8780 node perf.cjs $S touch 667 375 L_t667 > matrix/L_t667.log 2>&1
PORT=8783 node e1b.cjs $S key 1280 720 kb > matrix/E1_kb.log 2>&1
PORT=8783 node e1b.cjs $S touch 844 390 t844 > matrix/E1_t844.log 2>&1
PORT=8783 node e1b.cjs $S touch 667 375 t667 > matrix/E1_t667.log 2>&1
echo MATRIXDONE > /tmp/matrix_done.txt
