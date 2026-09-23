#!/usr/bin/env bash
# check-render.sh — acceptance checks for the BMAN10750 seminar deck.
# Guards the failure modes that actually bit us building this:
#   1. a stale render (freeze caching an include-file edit)
#   2. a slide losing its animation stage or gating fragments
#   3. a sim-card missing its layout variant (plot lands under the editor)
#   4. webR chunks silently not reaching the filter
#   5. a sim cell growing past the projection line budget or line length
set -euo pipefail

OUT_RAW="${1:-_site/index.html}"
[[ -f "$OUT_RAW" ]] || { echo "FAIL: $OUT_RAW not found — run quarto render first"; exit 1; }

# A commented-out .qmd block reaches the HTML verbatim, so <div id="x-stage">
# inside <!-- --> is still greppable even though nothing renders it. Every
# check here asks "is this on the deck", so they all read a stripped copy.
# Stripped with a non-greedy match over the WHOLE file: a line-based scan for
# <!-- / --> swallowed the rest of index.html, because Quarto's own one-line
# comments open and close on the same line.
strip_comments() { perl -0777 -pe 's/<!--.*?-->//gs' "$@"; }

OUT=$(mktemp); SRC=$(mktemp); trap 'rm -f "$OUT" "$SRC"' EXIT
strip_comments "$OUT_RAW" > "$OUT"

# Only the sections index.qmd actually includes; a commented-out include ships
# no cells, so its cells must not be counted against the render either. SRC is
# those sections with their own commented-out blocks removed.
SECTIONS=$(strip_comments index.qmd | grep -o 'sections/[A-Za-z0-9._-]*\.qmd')
strip_comments $SECTIONS > "$SRC"

fail=0
need() {  # need <needle> <label>
  if grep -qF -- "$1" "$OUT"; then echo "OK:   $2"; else echo "FAIL: $2"; fail=1; fi
}

echo "── slides ─────────────────────────────────────────"
for id in s00b-me s00b-about s00-how-to-use s00-webr \
          s01-visualisation chart-choice \
          s02-descriptives mm-intuition cheb-sim \
          s03-probability prob-count combinatorics bayes-hook bayes-intuition bayeq-formula monty bayes-sim \
          space-intuition setops-intuition venn-intuition set-formal \
          conditional-probabilities cond-intuition total-probability \
          s04-distributions random-variables distribution-fn binom-intuition seller-intuition laplace-intuition \
          pois-intuition pois-formal \
          likelihood-live binom-formal \
          pois-intuition expo-intuition expo-formal \
          normal-intuition box-normal funcrv pois-sim; do
  need "id=\"$id\"" "slide #$id"
done

# Commented out in the sources on 2026-09-23 (slides 8, 9, 42 and 44-67 of the
# then 67-slide deck). Asserted ABSENT rather than deleted from this file: if
# one reappears the comment markers have been broken, and if the blocks are
# uncommented again this list is where the ids come back from.
for id in bins-intuition bins-sim dist-questions \
          clt-intuition clt-sim zstd-intuition \
          s05-estimation ciflip-intuition cieq-formula \
          ci-intuition ci-sim ci-t-vs-z \
          s06-testing pval-intuition alpha-sim power-sim \
          s07-two-populations pair-intuition pair-sim \
          s08-regression ls-intuition ols-sim ovb-sim \
          s09-forecasting smooth-intuition smooth-sim; do
  if grep -qF "id=\"$id\"" "$OUT"; then
    echo "FAIL: slide #$id is commented out in sections/ but rendered anyway"; fail=1
  fi
done
echo "OK:   26 commented-out slides stayed out"

echo "── animation stages ───────────────────────────────"
# pois and expo dropped: #pois-intuition and #expo-intuition are {ojs}
# slides now, not stages.
# bins, clt, zstd, ciflip, cieq, ci, pval, pair, ls and smooth belong to
# slides commented out on 2026-09-23; put them back here when those return.
STAGES="about dicegrid mm space setops venn prior bayes bayeq monty cond binom seller laplace"
for s in $STAGES; do
  need "id=\"$s-stage\"" "stage #$s-stage"
done
# Every stage div must carry the shared class (seminars.scss sizes .stage).
# The expected count is derived from STAGES so adding a stage is one edit.
WANT_STAGES=$(wc -w <<< "$STAGES" | tr -d ' ')
STAGE_DIVS=$( { grep -oE '<div id="[a-z0-9]+-stage" class="stage">' "$OUT" || true; } | wc -l | tr -d ' ')
if [[ "$STAGE_DIVS" -eq "$WANT_STAGES" ]]; then echo "OK:   $WANT_STAGES .stage divs"; else echo "FAIL: $STAGE_DIVS .stage divs (want $WANT_STAGES)"; fail=1; fi
# A stage div with no registered animation is a blank slide. The div comes from
# the .qmd but the JS comes from an include-after-body file, and Quarto has been
# seen to silently drop a NEWLY ADDED include on an incremental render — the
# render still reports success and every other check here still passes, so the
# first sign is a stage that draws nothing in the lecture. If this fails, run
# `rm -rf .quarto _site && quarto render`.
# Counted rather than pattern-matched on the registration call, because
# bayes-anim.html and bayeq-anim.html predate StageKit and wire themselves up.
# One mention is the <div> from the .qmd alone, which means the JS is missing.
for s in $STAGES; do
  n=$( { grep -o "$s-stage" "$OUT" || true; } | wc -l | tr -d ' ')
  if [[ "$n" -ge 2 ]]; then
    echo "OK:   animation JS reached the page for #$s-stage"
  else
    echo "FAIL: #$s-stage has its div but no animation JS ($n mention) — stale include, run 'rm -rf .quarto _site && quarto render'"
    fail=1
  fi
done
need "window.StageKit = " "StageKit included"

# ...and that each one survives being LOADED. A stage file that throws on the
# way in passes every check above — the JS is in the page and the div is in the
# .qmd — but dies before K.register(), so the slide draws nothing.
if command -v node >/dev/null 2>&1; then
  if node "$(dirname "$0")/check-anims.js" | grep -q '^FAIL'; then
    node "$(dirname "$0")/check-anims.js" | grep '^FAIL'
    fail=1
  else
    echo "OK:   every *-anim.html loads without throwing"
  fi
else
  echo "SKIP: node not found, cannot load-test the animations"
fi
need "deck-sim-tune" "sim-tune included"

echo "── gating fragments ───────────────────────────────"
# Each stage's JS listens for these ids; losing one silently freezes a step.
for f in prior-frag-1 prior-frag-2 \
         mm-frag-1 mm-frag-2 \
         bayes-frag-1 bayes-frag-2 bayes-frag-3 bayes-frag-4 \
         bayeq-frag-1 bayeq-frag-2 bayeq-frag-3 bayeq-frag-4 \
         monty-frag-1 monty-frag-2 monty-frag-3 \
         monty-frag-4 monty-frag-5 monty-frag-6 \
         cond-frag-1 cond-frag-2 cond-frag-3 \
         space-frag-1 space-frag-2 space-frag-3 \
         setops-frag-1 setops-frag-2 setops-frag-3 \
         venn-frag-1 venn-frag-2 venn-frag-3 \
         binom-frag-1 binom-frag-2 binom-frag-3 \
         seller-frag-1 seller-frag-2 seller-frag-3 \
         laplace-frag-1 laplace-frag-2 laplace-frag-3; do
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
# Commented-out blocks are not rendered, so they must not be counted either.
want=$( { grep -c '^```{webr-r}' "$SRC" || true; } | tr -d ' ')
# Require at least one digit: the extension's own JS carries a bare
# "qwebr-insertion-location-" template string that would otherwise be counted.
got=$( { grep -o 'qwebr-insertion-location-[0-9][0-9]*' "$OUT" || true; } | sort -u | wc -l | tr -d ' ')
if [[ "$got" -eq "$want" ]]; then
  echo "OK:   $got webR cells (matches $want in sections/)"
else
  echo "FAIL: $got webR cells rendered but $want in sections/ — stale render?"; fail=1
fi

# Monaco must come from assets/vendor, never the CDN. Upstream quarto-webr
# hardcodes a jsdelivr URL in qwebr-monaco-editor-init.html; a `quarto update`
# of the extension silently restores it, and then the {webr-r} cells render as
# empty boxes on any machine with slow or blocked network. See
# assets/vendor/monaco/README.md.
if grep -qF 'jsdelivr.net/npm/monaco-editor' "$OUT"; then
  echo "FAIL: Monaco is being loaded from the CDN — re-apply the local path in _extensions/coatless/webr/qwebr-monaco-editor-init.html"; fail=1
else
  echo "OK:   Monaco loaded locally, not from a CDN"
fi
if [[ -f assets/vendor/monaco/vs/loader.js ]]; then
  echo "OK:   vendored Monaco present"
else
  echo "FAIL: assets/vendor/monaco/vs/loader.js missing — see assets/vendor/monaco/README.md"; fail=1
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
# 8 on power-sim (claim pair above the card), 11 on mm-sim (its vector is
# wrapped over three lines and the slide measures 608/700). 48 chars max.
# `#|` option lines never count; a `#| context: setup` cell is exempt.
budget_out=$(awk '
  !inchunk && /^## / { id=$0; sub(/.*#/,"",id); sub(/\}.*/,"",id); lede=0; plot=0 }
  /\.lede-min/ { lede=1 }
  /\.sim-plot/ { plot=1 }
  /^```\{webr-r\}/ { inchunk=1; n=0; mx=0; setup=0; next }
  inchunk && /^```$/ {
    inchunk=0
    if (setup) next
    budget = plot ? 12 : (lede ? 10 : 14); if (id == "power-sim") budget = 8; if (id == "mm-sim") budget = 11
    status = (n <= budget && mx <= 48) ? "OK:  " : "FAIL:"
    if (status == "FAIL:") bad = 1
    printf "%s %-11s lines %2d/%-2d longest %2d/48\n", status, id, n, budget, mx
    next }
  inchunk && /^#\|/ { if ($0 ~ /context: *setup/) setup=1; next }
  # BSD awk length() counts bytes: a non-ASCII character in a cell line counts as 2+. Cells are ASCII today; keep them so.
  inchunk { n++; if (length($0) > mx) mx = length($0) }
  END { exit bad ? 1 : 0 }
' "$SRC") || fail=1
echo "$budget_out"

echo "───────────────────────────────────────────────────"
[[ "$fail" -eq 0 ]] && echo "All checks passed." || { echo "Checks FAILED."; exit 1; }
