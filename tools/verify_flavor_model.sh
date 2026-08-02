#!/usr/bin/env bash
#
# Parity check for tools/flavor_explorer.html.
#
#   ./tools/verify_flavor_model.sh
#
# The applet is a SECOND implementation of the ADR 0004 scoring contract, and
# will be a third once #9 lands the GDScript evaluator. A second implementation
# that is never re-checked becomes a confidently wrong second opinion, so this
# script exists to make drift detectable rather than silent.
#
# It extracts the applet's own evaluate/band/feedback functions straight out of
# the HTML and compares them against an oracle written from ADR 0004, over
# generated cases including every rating-band edge.
#
# Not part of scripts/check.sh: it needs Node, which is not a declared project
# dependency. Run it whenever ADR 0004 changes, and after #9, when the oracle
# below should be replaced by the real GDScript evaluator to make this a
# genuine parity test rather than a model-to-model one.

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 1

readonly APPLET="tools/flavor_explorer.html"

command -v node >/dev/null 2>&1 || {
	echo "node is required for this check and was not found." >&2
	echo "This is a hard failure, not a skip: an unverifiable model is the" >&2
	echo "problem this script exists to prevent." >&2
	exit 1
}
[ -f "$APPLET" ] || { echo "missing $APPLET" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Extract only the pure functions. Locating them by name keeps this working if
# the file is edited and line numbers move.
start="$(grep -n '^const DIMS' "$APPLET" | head -1 | cut -d: -f1)"
fn_start="$(grep -n '^function evaluate' "$APPLET" | head -1 | cut -d: -f1)"
fn_end="$(awk 'NR>'"$fn_start"' && /^}/ {c++} c==3 {print NR; exit}' "$APPLET")"
[ -n "$start" ] && [ -n "$fn_end" ] || { echo "could not locate functions in $APPLET" >&2; exit 1; }

sed -n "${start}p;${fn_start},${fn_end}p" "$APPLET" >"$work/extracted.js"
cat >>"$work/extracted.js" <<'JS'
const lines = require('fs').readFileSync(0, 'utf8').trim().split('\n');
for (const line of lines) {
	const c = JSON.parse(line);
	const r = evaluate(c.t, c.w, c.d);
	if (r.error) { console.log('ERR'); continue; }
	const f = feedback(r.per);
	console.log([r.score, band(r.score), f.strongest || '-', f.largest || '-'].join('|'));
}
JS
node --check "$work/extracted.js" || { echo "extracted JS does not parse" >&2; exit 1; }

python3 - "$work" <<'PY'
import json, random, subprocess, sys, os
work = sys.argv[1]
DIMS = ["SAVORY", "SPICY", "FRESH", "COMFORT", "ADVENTUROUS"]

def oracle(t, w, d):
    """Written from ADR 0004 sections 3 and 6. Independent of the applet."""
    tp = mp = 0
    per = []
    for x in DIMS:
        wt = w.get(x, 0)
        if wt == 0:
            continue
        tt, aa = t.get(x, 0), d.get(x, 0)
        tp += wt * abs(aa - tt)
        mp += wt * max(tt, 5 - tt)
        per.append((x, wt, wt * abs(aa - tt)))
    if mp <= 0:
        return "ERR"
    s = 100 - (tp * 100) // mp
    b = ("DELIGHTED" if s >= 85 else "SATISFIED" if s >= 65
         else "MIXED" if s >= 40 else "DISSATISFIED")
    strongest = min(per, key=lambda r: (r[2], -r[1], DIMS.index(r[0])))[0]
    worst = max(per, key=lambda r: (r[2], r[1], -DIMS.index(r[0])))
    return f"{s}|{b}|{strongest}|{'-' if worst[2] == 0 else worst[0]}"

cases = []
# Exhaustive single dimension.
for w in range(1, 6):
    for t in range(6):
        for d in range(6):
            cases.append({"t": {"SPICY": t}, "w": {"SPICY": w}, "d": {"SPICY": d}})
# Exhaustive two dimensions at equal weight, which forces the order tie-break.
for t1 in range(6):
    for t2 in range(6):
        for d1 in range(6):
            for d2 in range(6):
                cases.append({"t": {"SAVORY": t1, "SPICY": t2},
                              "w": {"SAVORY": 3, "SPICY": 3},
                              "d": {"SAVORY": d1, "SPICY": d2}})
random.seed(20260801)
for _ in range(6000):
    t = {k: random.randint(0, 5) for k in DIMS}
    w = {k: random.randint(0, 5) for k in DIMS}
    if sum(w.values()) == 0:
        w[DIMS[0]] = 1
    d = {k: random.randint(0, 5) for k in DIMS}
    cases.append({"t": t, "w": w, "d": d})

payload = "\n".join(json.dumps(c) for c in cases)
out = subprocess.run(["node", os.path.join(work, "extracted.js")],
                     input=payload, capture_output=True, text=True)
if out.returncode != 0:
    print(out.stderr, file=sys.stderr)
    sys.exit(1)

got = out.stdout.strip().split("\n")
mismatches = []
edges = 0
for c, j in zip(cases, got):
    o = oracle(c["t"], c["w"], c["d"])
    if o != "ERR" and int(o.split("|")[0]) in (39, 40, 64, 65, 84, 85):
        edges += 1
    if o != j:
        mismatches.append((c, o, j))

print(f"  cases compared : {len(cases)}")
print(f"  band-edge cases: {edges}")
print(f"  mismatches     : {len(mismatches)}")
for c, o, j in mismatches[:5]:
    print(f"    {c}\n      oracle: {o}\n      applet: {j}")

if mismatches:
    print("\n\033[31mFAIL\033[0m applet has drifted from the ADR 0004 contract")
    sys.exit(1)
print("\n\033[32mPASS\033[0m applet matches the ADR 0004 contract")
PY
