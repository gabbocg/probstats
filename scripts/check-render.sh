#!/usr/bin/env bash
# check-render.sh — acceptance checks for the BMAN10750 seminar deck.
# Guards the failure modes that actually bit us building this:
#   1. a stale render (freeze caching an include-file edit)
#   2. a slide losing its animation stage or gating fragments
#   3. a sim-card missing its layout variant (plot lands under the editor)
#   4. webR chunks silently not reaching the filter
#   5. a sim cell growing past the projection line budget or line length
set -euo pipefail

OUT="${1:-_site/index.html}"
[[ -f "$OUT" ]] || { echo "FAIL: $OUT not found — run quarto render first"; exit 1; }

fail=0
need() {  # need <needle> <label>
  if grep -qF -- "$1" "$OUT"; then echo "OK:   $2"; else echo "FAIL: $2"; fail=1; fi
}

echo "── slides ─────────────────────────────────────────"
for id in s00-how-to-use s00-webr \
          s01-visualisation bins-intuition bins-sim \
          s02-descriptives mm-intuition cheb-sim \
          s03-probability bayes-hook bayes-intuition bayeq-formula monty bayes-sim \
          cond-intuition cond-sim \
          s04-distributions binom-intuition seller-intuition seller-sim \
          pois-intuition expo-intuition \
          memory-sim clt-intuition zstd-intuition pois-sim clt-sim \
          s05-estimation ciflip-intuition cieq-formula \
          ci-intuition ci-sim ci-t-vs-z \
          s06-testing pval-intuition alpha-sim power-sim \
          s07-two-populations pair-intuition pair-sim \
          s08-regression ls-intuition ols-sim ovb-sim \
          s09-forecasting smooth-intuition smooth-sim; do
  need "id=\"$id\"" "slide #$id"
done

echo "── animation stages ───────────────────────────────"
STAGES="bins mm prior bayes bayeq monty ciflip cieq cond binom seller pois expo clt zstd ci pval pair ls smooth"
for s in $STAGES; do
  need "id=\"$s-stage\"" "stage #$s-stage"
done
# Every stage div must carry the shared class (seminars.scss sizes .stage).
# The expected count is derived from STAGES so adding a stage is one edit.
WANT_STAGES=$(wc -w <<< "$STAGES" | tr -d ' ')
STAGE_DIVS=$( { grep -oE '<div id="[a-z0-9]+-stage" class="stage">' "$OUT" || true; } | wc -l | tr -d ' ')
if [[ "$STAGE_DIVS" -eq "$WANT_STAGES" ]]; then echo "OK:   $WANT_STAGES .stage divs"; else echo "FAIL: $STAGE_DIVS .stage divs (want $WANT_STAGES)"; fail=1; fi
need "window.StageKit = " "StageKit included"
need "deck-sim-tune" "sim-tune included"

echo "── gating fragments ───────────────────────────────"
# Each stage's JS listens for these ids; losing one silently freezes a step.
for f in bins-frag-w1 bins-frag-w2 \
         prior-frag-1 prior-frag-2 \
         mm-frag-1 mm-frag-2 \
         bayes-frag-1 bayes-frag-2 bayes-frag-3 bayes-frag-4 \
         bayeq-frag-1 bayeq-frag-2 bayeq-frag-3 bayeq-frag-4 \
         monty-frag-1 monty-frag-2 monty-frag-3 \
         monty-frag-4 monty-frag-5 monty-frag-6 \
         cond-frag-1 cond-frag-2 cond-frag-3 \
         binom-frag-1 binom-frag-2 binom-frag-3 \
         seller-frag-1 seller-frag-2 seller-frag-3 \
         pois-frag-1 pois-frag-2 pois-frag-3 \
         expo-frag-1 expo-frag-2 expo-frag-3 \
         clt-frag-1 clt-frag-2 clt-frag-3 \
         zstd-frag-1 zstd-frag-2 \
         ciflip-frag-1 ciflip-frag-2 ciflip-frag-3 \
         cieq-frag-1 cieq-frag-2 cieq-frag-3 cieq-frag-4 \
         pval-frag-1 pval-frag-2 pval-frag-3 \
         pair-frag-1 pair-frag-2 \
         ls-frag-1 ls-frag-2 \
         smooth-frag-1 smooth-frag-2; do
  need "id=\"$f\"" "fragment $f"
done

echo "── layout + webR ──────────────────────────────────"
# A .sim-card with no .sim-plot / .sim-text variant renders the plot under
# the editor instead of beside it. Bare class="sim-card" means it is missing.
if grep -qF 'class="sim-card"' "$OUT"; then
  echo "FAIL: a .sim-card is missing its .sim-plot / .sim-text variant"; fail=1
else
  echo "OK:   all sim-cards carry a layout variant"
fi

# Count qwebr-insertion-location-N: the filter emits exactly one per chunk.
# (Do NOT count .qwebr-console-area — that DOM is built at runtime by JS and
# its static occurrences have nothing to do with how many cells exist.)
want=$( { grep -ho '```{webr-r}' sections/*.qmd || true; } | wc -l | tr -d ' ')
# Require at least one digit: the extension's own JS carries a bare
# "qwebr-insertion-location-" template string that would otherwise be counted.
got=$( { grep -o 'qwebr-insertion-location-[0-9][0-9]*' "$OUT" || true; } | sort -u | wc -l | tr -d ' ')
if [[ "$got" -eq "$want" ]]; then
  echo "OK:   $got webR cells (matches $want in sections/)"
else
  echo "FAIL: $got webR cells rendered but $want in sections/ — stale render?"; fail=1
fi

if grep -qE '^\s*editor-font-scale:\s*1\s*$' _quarto.yml; then
  echo "OK:   editor-font-scale: 1 in _quarto.yml"
else
  echo "FAIL: editor-font-scale: 1 missing from _quarto.yml (Monaco will be half size)"; fail=1
fi
if grep -qE '^#\| context: setup' sections/00-how-to-use.qmd; then
  echo "OK:   plot-text setup cell present"
else
  echo "FAIL: plot-text setup cell missing from sections/00-how-to-use.qmd"; fail=1
fi

echo "── sim-cell budgets (spec §4.3) ───────────────────"
# Budget by slide shape: 14 lines plain, 10 with a .lede-min, 12 with a plot,
# 8 on power-sim (claim pair above the card). 48 characters max everywhere.
# `#|` option lines never count; a `#| context: setup` cell is exempt.
budget_out=$(awk '
  !inchunk && /^## / { id=$0; sub(/.*#/,"",id); sub(/\}.*/,"",id); lede=0; plot=0 }
  /\.lede-min/ { lede=1 }
  /\.sim-plot/ { plot=1 }
  /^```\{webr-r\}/ { inchunk=1; n=0; mx=0; setup=0; next }
  inchunk && /^```$/ {
    inchunk=0
    if (setup) next
    budget = plot ? 12 : (lede ? 10 : 14); if (id == "power-sim") budget = 8
    status = (n <= budget && mx <= 48) ? "OK:  " : "FAIL:"
    if (status == "FAIL:") bad = 1
    printf "%s %-11s lines %2d/%-2d longest %2d/48\n", status, id, n, budget, mx
    next }
  inchunk && /^#\|/ { if ($0 ~ /context: *setup/) setup=1; next }
  # BSD awk length() counts bytes: a non-ASCII character in a cell line counts as 2+. Cells are ASCII today; keep them so.
  inchunk { n++; if (length($0) > mx) mx = length($0) }
  END { exit bad ? 1 : 0 }
' sections/*.qmd) || fail=1
echo "$budget_out"

echo "───────────────────────────────────────────────────"
[[ "$fail" -eq 0 ]] && echo "All checks passed." || { echo "Checks FAILED."; exit 1; }
