# BMAN10750 deck: presence in the room

**Date:** 2026-09-05
**Deck:** `bman10750-slides/` ("Statistics, Simulated", Quarto Reveal.js, 46 slides, nine seminars)
**Status:** design approved in conversation; spec reviewer approved after three rounds; awaiting user review

## 1. Goal

The deck is projected by the instructor in a seminar room. It keeps its current look (white ground, Roboto + JetBrains Mono, navy `#325D88` accent, animated SVG stages, live webR cells). What changes is scale and use of the slide: the intuition figures fill the slide instead of a narrow band, every label inside a figure is readable from the back row, code and output are sized for projection, and the two slides that overflow today stop overflowing.

This is project 1 of 2. Project 2 (more intuition and simulation slides for the thin seminars 1, 2, 7 and 9) is out of scope here and will be authored against the system this spec defines.

## 2. Non-goals

- No new palette, fonts, hero illustrations or per-seminar colours. Three divergent directions were mocked up and the user kept the current look.
- No change to what any stage or cell teaches: data, states, the meaning of captions, animation timing and fragment order stay as they are. Where a cell's code is reformatted (§6), its knob line and the numbers it prints are unchanged.
- No new slides.
- No change to the deck's chrome (footer link, slide numbers, controls, chalkboard, drop terminal).
- No edits to `_extensions/` (the quarto-webr and drop extensions are vendored as-is).

## 3. Measured baseline

Slide box is 1050×700 at a 36px root (`$presentation-font-size-root`). Measured in the current render:

| element | today |
|---|---|
| `h2` band | y 0–86, 48.6px |
| `.stage-wrap` on a standard stage | y 136–496, 360px tall |
| stage SVG | 900×360 (canvas 1000×400 at `scale(0.90)`) |
| in-canvas tick labels | 15 canvas units, about 13.5px on the slide |
| in-canvas captions | 17 canvas units, about 15px |
| `.slide-footer` | 20px, grey `--ink-soft`, 780px wide, three lines |
| unused bottom band on stage slides | about 93px |
| Monaco editor font | **13.32px**, line height 20px, word wrap on, editor 563px wide |
| printed output after Run | 18px (inline style set by the extension) |

The editor size is not what `seminars.scss` appears to set. The extension computes `editor-font-scale × computed font-size of the editor div` (`qwebr-cell-elements.js`, `qwebrScaledFontSize`; the `body.reveal` branch never fires in Quarto, so it reads the div's own font-size). With the revealjs default scale of 0.5 and the deck's `.sim-card .qwebr-editor { font-size: 0.74em }` (26.64px), Monaco is created at 13.32px. The output `<pre>` gets the same treatment at run time from the output div's font-size (36px × 0.5 = 18px). So the CSS rules do act, but halved, and any redesign has to set the scale to 1 and then drive sizes from CSS.

Two sim slides exceed 700px (`#clt-sim` 724, `#ci-sim` 725), so the orange `.try-this` box collides with the footer. Fragment gating was checked on `#clt-intuition` and works; it is not a bug to fix.

The stage animations inline the same nine hex colours and two font strings across 18 files, and each file defines its own `el`, `build`, `mount`, `fragState` and `init`. Two of them define `stop(s)` and call it on remount: `binom` to cancel a `setTimeout` replay chain, `seller` to pause the anime tweens it keeps in `s.anims`.

Cell inventory: 17 `webr-r` cells (16 on `.sim-slide` slides plus the intro cell on `#s00-webr`, which carries no slide class). Eight cells sit on slides that also carry a `.lede-min`; one (`power-sim`) sits under a `.claim-pair`; four draw plots (`bins-sim`, `seller-sim`, `clt-sim`, `ci-sim`).

## 4. Slide grid

### 4.1 Stage slides (`.stage-slide`, 18 slides)

| band | y range | rule |
|---|---|---|
| title | 0–80 | `h2` unchanged in size; the accent bar's margin-top drops from 0.55em to 0.4em via `.reveal section.stage-slide > h2::after` (it must out-rank `theme.scss`'s `.reveal section > h2::after`) |
| stage | 88–556 | `.stage-wrap` height 468px; canvas 1000×445 shown at `scale(1.05)` = 1050×467 |
| takeaway | 572–690 | `.slide-footer` at 24px, colour `--ink`, `max-width: 980px`, at most two lines |

Three stages keep a different canvas because their slides differ:

| stage | canvas today | canvas after | wrap height | note |
|---|---|---|---|---|
| `bins` | 1000×430 | 1000×445 | 468 | retuned to the standard height |
| `mm` | 1000×380 | 1000×445 | 468 | retuned to the standard height |
| `ci` | 1000×470 | 1000×330 | 347 | the `.claim-pair` sits beneath it; this is a re-layout (20 interval rows at a 17-unit step must fit 330 with 18-unit labels), planned as its own task |

Any `.slide-footer` text that would run to three lines at 24px/980px is shortened during implementation without changing its claim.

### 4.2 In-canvas type scale

Canvas units; at `scale(1.05)` slide pixels are 5% larger.

| role | size | face | examples |
|---|---|---|---|
| tick | 18 | mono | axis numbers |
| label | 20 | sans or mono | panel titles, small annotations |
| caption | 24 | sans | the state caption at the top of a stage |
| readout | 30 bold | mono | `n = 30`, `4 / 23 = 17%`, the shaded-area value |

Nothing inside a figure is smaller than 18. Today 18 text nodes are at 12–14 and jump to 18. Where a caption no longer fits beside another element (for example the CLT caption next to the orange readout), the layout moves; the text does not shrink.

### 4.3 Sim slides (`.sim-slide`, 16 slides, plus the intro cell)

**Mechanism.** `_quarto.yml` gains `webr: cell-options: editor-font-scale: 1`, so the extension uses the CSS font-size of the editor div and the output div unchanged. `seminars.scss` then sets them in px (the slide is a fixed 1050×700 coordinate space, so px is the honest unit):

| element | today | proposed |
|---|---|---|
| `.slide-kicker` | 14px | 17px |
| Monaco editor (`.sim-card .qwebr-editor` font-size) | 13.32px, line height 20 | **20px**, line height **27** |
| printed output (`.sim-card .qwebr-output-code-area` font-size) | 18px | **22px**, line height 1.25 |
| `.try-this` | 21px | 23px |
| `.lede-min` | 28px | unchanged |
| `.claim-cell` | 21.6px | unchanged |

Monaco options that CSS cannot reach are set from a new `assets/js/sim-tune.html`: it polls the extension's global `qwebrEditorInstances` four times a second, calls `updateOptions({ lineHeight: 27, lineNumbers: 'off', glyphMargin: false, folding: false, lineDecorationsWidth: 0, lineNumbersMinChars: 0 })` on each instance it has not tuned yet, and stops once every `.qwebr-editor` on the page has an instance or after 60 seconds. Word wrap stays on as a safety net; the line-length limits below mean it never triggers in practice. Line numbers are dropped because the gutter costs 50px of a code column and nothing in the deck refers to a line number.

**Columns.** The card's inner width is 1014px (1050 minus 2×18 padding); the grid gap is 16px.

| cell type | grid | code column | chars at 12px/char | output or plot column |
|---|---|---|---|---|
| `.sim-text` | 1.5fr / 1fr | 599px | 49 | 399px: 30 characters of 22px mono |
| `.sim-plot` | 1.25fr / 1fr | 554px | 46 | 444px plot |

**Limits, enforced by `check-render.sh` (§8.1) on the source cells. `#|` option lines are excluded from every count, and cells carrying `#| context: setup` are excluded entirely (they are hidden, so no limit applies):**

- max source line length: **48** characters in text cells, **44** in plot cells (so no line wraps and source lines equal visual lines);
- line budget, derived from the vertical stack (title 80, kicker 44, card padding 26, toolbar 40, 27px per line, gap 16, `.try-this` two lines 91; plot cells also carry the printed value under the editor, about 62px; lede slides carry about 123px of `.lede-min`; the claim pair on `power-sim` carries about 170px):

| slide shape | budget |
|---|---|
| text cell, no lede | 14 lines |
| text cell with `.lede-min` | 10 lines |
| plot cell | 12 lines |
| `power-sim` (claim pair above the card) | 8 lines |

- printed output no wider than 30 characters, checked by running every cell in the browser pass (§8.3), not statically.

### 4.4 Hero slides (10 slides)

| element | today | proposed |
|---|---|---|
| `.sem-mark::before` numeral | 2.6em at 22% navy | 4.4em (about 160px) at 18% navy, same position |
| tagline (`section.hero > p`) | 1.15em | 1.3em |
| `.lede` | italic, `--ink-soft` | italic, `--ink` |

Nothing else on the hero changes. The "How this deck works" hero uses `.section-badge` instead of `.sem-mark` and only gets the tagline and lede changes.

## 5. Stage kit

New file `assets/js/stage-kit.html`, listed in `_quarto.yml` `include-after-body` **before** `assets/animations.html` and all `*-anim.html` files. It defines `window.StageKit` (a plain object; no build step, no modules):

```js
StageKit.PAL      // see the mapping below
StageKit.FONT     // { mono: 'JetBrains Mono, monospace', sans: 'Roboto, sans-serif' }
StageKit.TYPE     // { tick: 18, label: 20, caption: 24, readout: 30 }
StageKit.REDUCE            // prefers-reduced-motion, evaluated once
StageKit.animeReady()      // true when window.anime.animate exists
StageKit.el(name, attrs)   // createElementNS + setAttribute loop (the helper every file has today)
StageKit.txt(x, y, str, { size, face, fill, anchor, weight, cls })  // <text> using TYPE/FONT/PAL names
StageKit.canvas(stage, W, H)   // clears the stage div, appends <svg viewBox="0 0 W H" width=W height=H>, returns it
StageKit.registry          // { 'clt-stage': { frags: [...] }, ... } filled by register(); read by the probe (§8.2)
StageKit.register({
  stage:  'clt-stage',                                   // id of the stage div
  frags:  ['clt-frag-1', 'clt-frag-2', 'clt-frag-3'],    // in order; state k = k fragments visible
  build:  function (stageEl) { ... return s; },          // draws state 0, returns the handle
  place:  function (s, state, instant) { ... },          // moves the handle to `state`
  stop:   function (s) { ... }                           // optional; cancels timers/animations before a rebuild
});
```

Palette mapping, one name per hex used today:

| hex | name | | hex | name |
|---|---|---|---|---|
| `#325D88` | `navy` | | `#3E3F3A` | `ink` |
| `#93C54B` | `olive` | | `#6E7681` | `inkSoft` |
| `#F47C3C` | `orange` | | `#B0B7C0` | `dim` |
| `#B94A48` | `brick` | | `#E5E7EB` | `rule` |
| `#FFFFFF` | `white` | | | |

`register` does what every file's `init`/`mount`/`fragState` does today, once:

- on `Reveal` `ready` and `slidechanged`: if a handle exists and the registration has `stop`, call `stop(s)`; then find the stage div in the current slide; if present, call `build`, count visible fragments among `frags`, and if non-zero call `place(s, count, true)` (snap, do not animate);
- on `fragmentshown` with a registered id at index `i`, `place(s, i + 1, false)`; on `fragmenthidden`, `place(s, i, false)`;
- retry until `Reveal` exists, as the files do now.

Stages with no fragments (`ci`) register with `frags: []` and only get `build`. All 17 fragment files already use "state k = k visible fragments", so no file needs a different contract.

The kit does not own animation: each file keeps its `anime.animate` calls and its instant fallback. `place` implementations test `instant || StageKit.REDUCE || !StageKit.animeReady()` exactly as they test their local copies today.

### 5.1 Per-file retune

Each of the 18 files keeps its data, geometry constants, `build` and its state-moving function (named `place` in most files, `render` in `bayes`, `cond`, `ciflip` and `seller`). The mechanical changes:

1. Delete the local `REDUCE`, `NS`, `el`, `fragState`, `init`, `mount`, the `Reveal.on` block, and the fragment-id map (`ORDER`/`STATES` in most files; `ORDER` and `FRAGS` in `zstd`, whose `STATES` is frame data and stays). Replace with one `StageKit.register({...})` call; `binom` and `seller` pass their existing `stop`.
2. Replace every hex literal with the `StageKit.PAL` name from the table above and every font string with `StageKit.FONT`.
3. Replace every `'font-size': N` by role: tick marks and axis numbers → `tick`; panel titles and small annotations → `label`; the state caption → `caption`; the headline number → `readout`. Or use `StageKit.txt`.
4. Change `H` from 400 to 445 (bins from 430, mm from 380) and re-space the vertical constants (`BASE`, `AXIS_Y`, `FOOT_Y`, panel tops) so the drawing uses the new height rather than leaving a gap at the bottom.
5. Re-check that larger text does not collide: captions that sat beside a readout at 17 may need the readout moved right or the caption onto its own line.

`ci` (470 → 330) is the exception: it is a re-layout, not a retune, and is planned as its own task.

The comment header of each file (the teaching-point paragraph) stays; it is the documentation.

### 5.2 Markup and CSS

- Each `<div id="xxx-stage"></div>` in `sections/*.qmd` becomes `<div id="xxx-stage" class="stage"></div>`.
- In `seminars.scss`, the 18-id selectors become `.stage` (width 1000px, `transform-origin: top center`, `transform: scale(1.05)`, `display: block`) and `.stage svg { display: block }`. Per-stage heights become two classes on `.stage-wrap`: `.stage-wrap-std` (468px) and `.stage-wrap-ci` (347px). `.stage-wrap-bins`, `.stage-wrap-mm` and `.stage-wrap-400` are removed and the qmd updated.

## 6. Sim cells

### 6.1 Cells to edit

Thirteen cells need editing to meet §4.3. "Rewrap" means breaking a line at a comma or operator; it never changes the expression. Line counts exclude `#|` option lines.

| cell | lines | longest | shape | budget | action |
|---|---|---|---|---|---|
| `s00-webr` | 3 | 37 | text + lede | 10 | none |
| `bins-sim` | 9 | 65 | plot | 12 | rewrap the two long `hist()` lines to 44 → about 11 |
| `cheb-sim` | 11 | 49 | text + lede | 10 | drop the blank line; rewrap the one 49-char line → 10 |
| `bayes-sim` | 9 | 56 | text | 14 | rewrap two lines → 11 |
| `cond-sim` | 10 | 44 | text + lede | 10 | none |
| `seller-sim` | 13 | 58 | plot | 12 | `rel` and `good` as compact one-line functions within 44; `plot()` over three lines; `round(c(...))` over two; drop blank lines → 12 |
| `memory-sim` | 8 | 54 | text + lede | 10 | rewrap two lines → 10 |
| `pois-sim` | 10 | 46 | text + lede | 10 | none |
| `clt-sim` | 15 | 42 | plot | 12 | drop the three blank lines → 12 |
| `ci-sim` | 16 | 50 | plot | 12 | the largest edit: `mu`, `sigma`, `reps` on one line, `n`, `conf` (the knobs) on the next; drop the blank line; `plot(NA, ...)`, `abline()` and `segments()` rewrapped to 44; drop `las = 1` if still over → 12 |
| `ci-t-vs-z` | 15 | 63 | text | 14 | `coverage` as a single-expression function around `mean(replicate(...))`; `z_rule`/`t_rule` rewrapped; drop blank lines → about 10 |
| `alpha-sim` | 10 | 50 | text + lede | 10 | rewrap the one 50-char line, drop one blank line → 10 |
| `power-sim` | 8 | 49 | claim pair | 8 | move the 51-char `# H0 is FALSE ...` comment into the kicker ("Seminar 6 · the other error · H₀ false, true mean 105") → 7 |
| `pair-sim` | 10 | 51 | text | 14 | print as a 2×2 matrix (`rbind(independent = c(t, p), paired = c(t, p))`) so the output fits 30 characters; rewrap → about 12 |
| `ols-sim` | 10 | 44 | text | 14 | none |
| `ovb-sim` | 11 | 53 | text + lede | 10 | `unname()` the two extracted coefficients so the printed header is `truth full omitted`; rewrap two lines; drop blank lines → 10 |
| `smooth-sim` | 13 | 47 | text + lede | 10 | move `# F2 is given` into the lede sentence; `err` as a compact function; shorten the `cat()` labels so each printed line is under 30 characters; drop blank lines → 10 |

`pair-sim` and `ovb-sim` change the *shape* of what they print, not the values; their `.try-this` text is re-read against the new output during implementation. Every other cell prints exactly what it prints today.

If a cell cannot reach its budget without harming readability, the fallback is to move its `.lede-min` sentence into the `.try-this` prompt and use the no-lede budget.

### 6.2 R plot text

A hidden setup cell placed on the **`#s00-webr` slide, after the `.try-this` block and before the `.slide-footer`**, so its stub lands on a slide that already exists. Its one line is longer than 48 characters, which is why setup cells are exempt from the §4.3 limits:

````
```{webr-r}
#| context: setup
setHook("before.plot.new", function() par(cex = 1.4, mar = c(4.2, 4.2, 2, 1)))
```
````

The extension renders a setup cell as a visible "Loading webR…" stub until the hidden-cell pass has run; `seminars.scss` adds `.qwebr-noninteractive-setup-area { display: none }` so it never shows. The hook runs at every `plot.new()`, so `hist()` and `plot()` in the four plot cells inherit larger text with no visible line in the teaching code.

**Fallback** if the hook does not fire inside webR's canvas device: one explicit `par(cex = 1.4)` line at the top of each of the four plot cells. That puts `seller-sim`, `clt-sim` and `ci-sim` at 13 lines against a budget of 12; the room is recovered by lowering the plot cells' Monaco line height from 27 to 25 in `sim-tune.html` (plot cells are identifiable by the `.sim-plot` ancestor). `bins-sim` stays within budget either way.

The four plot cells also set:

```
#| fig-width: 4.6
#| fig-height: 3.7
#| dpi: 144
```

That is a 662×533 canvas scaled down into the 444px plot column, so the bitmap is crisp on a projector and the 12pt base text lands near 16px on the slide before the `cex` multiplier and near 22px after it. On-screen text size depends on figure inches and column width, not on `dpi`; `dpi` only removes the upscaling blur.

## 7. Change list outside the animations

`_quarto.yml`:

- `webr: cell-options: editor-font-scale: 1`.
- `include-after-body`: add `assets/js/stage-kit.html` first and `assets/js/sim-tune.html` last.

`assets/seminars.scss` (all overrides live here; `assets/theme.scss` is shared with the intro-r deck's history and is not edited):

- `.reveal section.stage-slide > h2::after { margin-top: 0.4em }` (specificity 0,2,3, so it beats the base theme's 0,1,3 rule; a bare `.stage-slide h2::after` would silently lose).
- `.stage-wrap-std`, `.stage-wrap-ci`, `.stage`, `.stage svg` (§5.2); the 18 id selectors and the three old wrap classes removed.
- `.slide-footer` on `.stage-slide`: 24px, `--ink`, `max-width: 980px`.
- `.slide-kicker`: 17px.
- `.sim-card .qwebr-editor { font-size: 20px }`; `.sim-card .qwebr-output-code-area { font-size: 22px }` and its `pre` at line height 1.25; the existing `0.95em` rule on the `pre` removed.
- `.sim-card.sim-text .qwebr-console-area { grid-template-columns: 1.5fr 1fr }` (was 1.3fr 1fr); `.sim-plot` split unchanged at 1.25fr 1fr.
- `.try-this`: 23px.
- `.sem-mark::before`: 4.4em, 18% alpha. `.reveal section.hero > p`: 1.3em. `.reveal section.hero .lede { color: var(--ink) }`.
- `.qwebr-noninteractive-setup-area { display: none }`.

`sections/*.qmd`: `class="stage"` on 18 stage divs; wrap classes renamed; the setup cell on `#s00-webr`; `#|` options on the four plot cells; the thirteen cell edits in §6.1; the `power-sim` kicker; the `smooth-sim` lede.

`scripts/check-render.sh` and new `scripts/probe-overflow.js` (§8).

## 8. Verification

### 8.1 `scripts/check-render.sh` additions

- `StageKit.register` appears in the render (kit included) and `sim-tune` is present.
- exactly 18 `class="stage"` divs.
- `editor-font-scale: 1` present in `_quarto.yml`.
- for every `webr-r` cell in `sections/*.qmd` except cells containing `#| context: setup`, with `#|` lines excluded: line count within the budget for its slide shape (14 / 10 with `.lede-min` / 12 with `.sim-plot` / 8 for `power-sim`), and no line longer than 48 (44 in `.sim-plot` cells). An awk pass keyed on the `## ` heading, the same shape as the count used to write §6.1.
- the setup cell is present (`context: setup` in the sources).
- all existing checks kept.

### 8.2 `scripts/probe-overflow.js`

A console snippet, run once in the browser after render, that reports:

- every leaf slide whose `scrollHeight` exceeds 700px (measured with the slide forced visible), expected: none;
- every `.stage` whose containing slide has a `.fragment` count different from `StageKit.registry[id].frags.length` (the `.fi-frag` spans are siblings of `.stage-wrap`, not children of `.stage`; no slide carries a non-gating fragment), expected: none;
- the computed font size of the smallest `<text>` in each stage SVG, expected: at least 18;
- for every Monaco instance, `fontSize`, `lineHeight` and the number of view lines versus the model's line count (a difference means a line wrapped), expected: 20, 27, and equal.

### 8.3 Browser pass

At 1024×768, 1280×720 and 1920×1080: one hero, one stage at its final fragment, one text sim after Run, one plot sim after Run. Then, at one size: a forward and backward fragment walk on all 18 stages; a Run of all 17 cells checking that no printed line exceeds 30 characters and no card overflows; a Run of the four plot cells to confirm the hook enlarged the plot text (compare against a Run with the setup cell disabled). Screenshots saved to the scratchpad and summarised in the final report.

## 9. Risks and fallbacks

| risk | fallback |
|---|---|
| `before.plot.new` hook does not fire in webR's canvas device | explicit `par()` line per plot cell and line height 25 in plot cells (§6.2) |
| `updateOptions` runs before an instance exists, or the extension recreates instances on theme switch | `sim-tune` re-polls and tunes any untuned instance; the probe (§8.2) reports the final `fontSize`/`lineHeight` |
| a stage's larger labels collide at 445 height | move elements, do not shrink text; if a caption must go, fold it into the `.slide-footer` |
| `ci` cannot fit 20 rows plus labels in 330 | reduce to 16 rows (the coverage count in its readout is recomputed; the claim pair is unchanged) |
| `quarto render` picks up a stale include | `freeze: false` is already set; `check-render.sh` compares cell counts |

## 10. Out of scope, deferred to project 2

New intuition and simulation slides for seminars 1, 2, 7 and 9; any pedagogy review of existing slides beyond keeping them intact through the retune.
