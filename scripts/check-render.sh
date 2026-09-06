#!/usr/bin/env bash
# check-render.sh — acceptance checks for the BMAN10750 seminar deck.
# Guards the failure modes that actually bit us building this:
#   1. a stale render (freeze caching an include-file edit)
#   2. a slide losing its animation stage or gating fragments
#   3. a sim-card missing its layout variant (plot lands under the editor)
#   4. webR chunks silently not reaching the filter
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
          s03-probability bayes-intuition bayeq-formula bayes-sim \
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
for s in bins mm bayes bayeq ciflip cieq cond binom seller pois expo clt zstd ci pval pair ls smooth; do
  need "id=\"$s-stage\"" "stage #$s-stage"
done

echo "── gating fragments ───────────────────────────────"
# Each stage's JS listens for these ids; losing one silently freezes a step.
for f in bins-frag-w1 bins-frag-w2 \
         mm-frag-1 mm-frag-2 \
         bayes-frag-1 bayes-frag-2 bayes-frag-3 bayes-frag-4 \
         bayeq-frag-1 bayeq-frag-2 bayeq-frag-3 bayeq-frag-4 \
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
want=$(grep -ho '```{webr-r}' sections/*.qmd | wc -l | tr -d ' ')
# Require at least one digit: the extension's own JS carries a bare
# "qwebr-insertion-location-" template string that would otherwise be counted.
got=$(grep -o 'qwebr-insertion-location-[0-9][0-9]*' "$OUT" | sort -u | wc -l | tr -d ' ')
if [[ "$got" -eq "$want" ]]; then
  echo "OK:   $got webR cells (matches $want in sections/)"
else
  echo "FAIL: $got webR cells rendered but $want in sections/ — stale render?"; fail=1
fi

echo "───────────────────────────────────────────────────"
[[ "$fail" -eq 0 ]] && echo "All checks passed." || { echo "Checks FAILED."; exit 1; }
