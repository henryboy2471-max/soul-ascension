#!/bin/bash
# Runs every tests/test_*.gd (headless Godot) plus the Python self-tests; one summary line per test in $OUT/suite.txt.
# Discovery is a glob, and a final guard fails the run if any discovered test has no result line or exited non-zero / reported FAIL.
# Usage: tools/run_tests.sh [OUT_DIR]     (godot 4.4.1 on PATH; saves go to a throwaway XDG_DATA_HOME per test)
cd "$(dirname "$0")/.." || exit 2
OUT=${1:-${TMPDIR:-/tmp}/soul_tests}; mkdir -p "$OUT"; : > "$OUT/suite.txt"
G=${GODOT:-godot}; bad=0; ran=0; found=0
for t in tests/test_*.gd; do
 found=$((found+1)); n=$(basename "$t" .gd)
 XDG_DATA_HOME="$OUT/xdg_$n" timeout 900 "$G" --headless --path . --script "res://$t" > "$OUT/$n.log" 2>&1; rc=$?
 fails=$(grep -cE '^FAIL|SCRIPT ERROR|Parse Error' "$OUT/$n.log")
 echo "$n rc=$rc $fails FAIL-lines | $(grep -E '^RESULT|LIVE AUTO' "$OUT/$n.log" | tail -1 | cut -c1-100)" >> "$OUT/suite.txt"
 ran=$((ran+1)); { [ $rc -ne 0 ] || [ "$fails" -ne 0 ]; } && bad=$((bad+1))
done
for t in tools/test_*.py; do
 python3 "$t" > "$OUT/$(basename "$t").log" 2>&1; rc=$?; echo "$t rc=$rc | $(tail -1 "$OUT/$(basename "$t").log" | cut -c1-100)" >> "$OUT/suite.txt"; [ $rc -ne 0 ] && bad=$((bad+1))
done
listed=$(grep -c '^test_' "$OUT/suite.txt")
echo "discovered $found, ran $ran, listed $listed, failing $bad" | tee -a "$OUT/suite.txt"
[ "$found" -eq "$listed" ] && [ "$bad" -eq 0 ]
