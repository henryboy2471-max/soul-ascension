#!/bin/bash
# Local-only server for the QA Web export (Episode 3 unlocked), for a device pass on your own network. NEVER publish or deploy this build.
# usage: tools/qa/serve_qa_local.sh [--build] [PORT]     (--build re-exports "Web QA" first; needs godot 4.4.1 and the Web export templates)
cd "$(dirname "$0")/../.." || exit 2
BUILD=0; [ "$1" = "--build" ] && { BUILD=1; shift; }
PORT=${1:-8801}
if [ $BUILD -eq 1 ]; then
 mkdir -p build/web_qa && godot --headless --editor --import --quit >/dev/null 2>&1
 godot --headless --export-release "Web QA" build/web_qa/index.html || { echo "export failed"; exit 1; }
fi
[ -f build/web_qa/index.html ] || { echo "no build/web_qa/index.html; run with --build"; exit 1; }
echo "QA BUILD (Episode 3 unlocked, not for release). Open http://<this-machine-LAN-IP>:$PORT/index.html on the device. Ctrl+C to stop."
cd build/web_qa && exec python3 -m http.server "$PORT" --bind 0.0.0.0
