# BMAN10750 deck: presence in the room

**Date:** 2026-09-05
**Deck:** `bman10750-slides/` ("Statistics, Simulated", Quarto Reveal.js, 46 slides, nine seminars)
**Status:** design approved in conversation; awaiting spec review

## 1. Goal

The deck is projected by the instructor in a seminar room. It keeps its current look (white ground, Roboto + JetBrains Mono, navy `#325D88` accent, animated SVG stages, live webR cells). What changes is scale and use of the slide: the intuition figures fill the slide instead of a narrow band, every label inside a figure is readable from the back row, code and output are sized for projection, and the two slides that overflow today stop overflowing.

This is project 1 of 2. Project 2 (more intuition and simulation slides for the thin seminars 1, 2, 7 and 9) is out of scope here and will be authored against the system this spec defines.

## 2. Non-goals

- No new palette, fonts, hero illustrations or per-seminar colours. Three divergent directions were mocked up and the user kept the current look.
- No change to what any stage or cell teaches: data, states, captions' meaning, animation timing and fragment order stay as they are.
- No new slides.
- No change to the deck's chrome (footer link, slide numbers, controls, chalkboard, drop terminal).

## 3. Measured baseline

Slide box is 1050×700 at a 36px root (`$presentation-font-size-root`). Measured on `#clt-intuition` in the current render:

| element | today |
|---|---|
| `h2` band | y 0–86, 48.6px |
| `.stage-wrap` | y 136–496, 360px tall |
| stage SVG | 900×360 (canvas 1000×400 at `scale(0.90)`) |
| in-canvas tick labels | 15 canvas units, about 13.5px on the slide |
| in-canvas captions | 17 canvas units, about 15px |
| `.slide-footer` | 20px, grey `--ink-soft`, 780px wide, three lines |
| unused bottom band | about 93px |

Two sim slides exceed 700px (`#clt-sim` 724, `#ci-sim` 725), so the orange `.try-this` box collides with the footer. Fragment gating was checked on `#clt-intuition` and works; it is not a bug to fix.

The stage animations inline the same nine hex colours (`#6E7681`, `#325D88`, `#B94A48`, `#E5E7EB`, `#B0B7C0`, `#3E3F3A`, `#F47C3C`, `#93C54B`, `#FFFFFF`) and two font strings across 18 files, and each file defines its own `el`, `build`, `mount`, `fragState` and `init`.

## 4. Slide grid

### 4.1 Stage slides (`.stage-slide`, 18 slides)

| band | y range | rule |
|---|---|---|
| title | 0–84 | `h2` unchanged in size; its accent bar margin shrinks so the band ends by 84px |
| stage | 92–560 | `.stage-wrap` height 468px; canvas 1000×445 shown at `scale(1.05)` = 1050×467 |
| takeaway | 576–690 | `.slide-footer` at 0.66em (about 24px), colour `--ink`, `max-width: 980px`, at most two lines |

Three stages keep a different canvas because their slides differ:

| stage | canvas | scale | why |
|---|---|---|---|
| `bins` | 1000×445 | 1.05 | was 430; retuned to the standard height |
| `mm` | 1000×445 | 1.05 | was 380; retuned to the standard height |
| `ci` | 1000×330 | 1.05 | the `.claim-pair` sits beneath it; wrap height 347px |

Any `.slide-footer` text that would run to three lines at 24px/980px is shortened during implementation without changing its claim.

### 4.2 In-canvas type scale

Canvas units; at `scale(1.05)` slide pixels are 5% larger.

| role | size | face | examples |
|---|---|---|---|
| tick | 18 | mono | axis numbers |
| label | 20 | sans or mono | panel titles, small annotations |
| caption | 24 | sans | the state caption at the top of a stage |
| readout | 30 bold | mono | `n = 30`, `4 / 23 = 17%`, the shaded-area value |

Nothing inside a figure is smaller than 18. Where a caption no longer fits beside another element (for example the CLT caption next to the orange readout), the layout moves, the text does not shrink.

### 4.3 Sim slides (`.sim-slide`, 17 slides, 19 cells including the intro cell)

| element | today | proposed |
|---|---|---|
| `.slide-kicker` | 0.40em (14px) | 0.46em (about 17px) |
| Monaco editor | 0.74em (about 27px) | 0.72em (about 26px), line height 1.3 |
| text output (`.qwebr-output-code-area pre`) | about 20px | about 26px |
| `.try-this` | 0.58em (21px) | 0.64em (23px) |
| `.lede-min` | 0.78em (28px) | unchanged |

Line budget per cell, so that the slide fits 700px with these sizes: **11 lines** on a slide without a `.lede-min`, **9 lines** on a slide with one. Blank lines count.

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
StageKit.PAL   // { navy, navyDeep, olive, orange, brick, ink, inkSoft, dim, rule, ruleSoft, white }
StageKit.FONT  // { mono: 'JetBrains Mono, monospace', sans: 'Roboto, sans-serif' }
StageKit.TYPE  // { tick: 18, label: 20, caption: 24, readout: 30 }
StageKit.REDUCE            // prefers-reduced-motion, evaluated once
StageKit.animeReady()      // true when window.anime.animate exists
StageKit.el(name, attrs)   // createElementNS + setAttribute loop (the helper every file has today)
StageKit.txt(x, y, str, { size, face, fill, anchor, weight, cls })  // <text> with the scale applied
StageKit.canvas(stage, W, H)   // clears the stage div, appends an <svg viewBox="0 0 W H" width=W height=H>, returns it
StageKit.register({
  stage:  'clt-stage',                       // id of the stage div
  frags:  ['clt-frag-1', 'clt-frag-2', 'clt-frag-3'],   // in order; state k = k fragments visible
  build:  function (stageEl) { ... return s; },          // draws state 0, returns the handle
  place:  function (s, state, instant) { ... }           // moves the handle to `state`
});
```

`register` does what every file's `init`/`mount`/`fragState` does today, once:

- on `Reveal` `ready` and `slidechanged`, find the stage div in the current slide; if present, call `build`, count visible fragments, and if non-zero call `place(s, count, true)` (snap, do not animate);
- on `fragmentshown` with a registered id, `place(s, index + 1, false)`; on `fragmenthidden`, `place(s, index, false)`;
- retry until `Reveal` exists, as the files do now.

Stages with no fragments (`ci`) register with `frags: []` and only get `build`.

The kit does not own animation: each file keeps its `anime.animate` calls and its instant fallback. `place` implementations test `instant || StageKit.REDUCE || !StageKit.animeReady()` exactly as they test their local copies today.

### 5.1 Per-file retune

Each of the 18 files keeps its data, geometry constants, `build` and `place`. The mechanical changes:

1. Delete the local `REDUCE`, `NS`, `el`, `fragState`, `init`, `mount`, the `Reveal.on` block, and the `ORDER`/`STATES` maps; replace with one `StageKit.register({...})` call.
2. Replace every hex literal with the matching `StageKit.PAL` name and every font string with `StageKit.FONT`.
3. Replace every `'font-size': N` with the nearest `StageKit.TYPE` role (15 → tick, 17 → caption, 22 → readout, etc.), or use `StageKit.txt`.
4. Change `H` from 400 to 445 (bins from 430, mm from 380, ci from 470 to 330) and re-space the vertical constants (`BASE`, `AXIS_Y`, `FOOT_Y`, panel tops) so the drawing uses the new height rather than leaving a gap at the bottom.
5. Re-check that larger text does not collide: captions that sat beside a readout at 17 may need the readout moved right or the caption onto its own line.

The comment header of each file (the teaching-point paragraph) stays; it is the documentation.

### 5.2 Markup and CSS

- Each `<div id="xxx-stage"></div>` in `sections/*.qmd` becomes `<div id="xxx-stage" class="stage"></div>`.
- In `seminars.scss`, the 18-id selectors become `.stage` (width 1000px, `transform-origin: top center`, `transform: scale(1.05)`, `display: block`) and `.stage svg { display: block }`. Per-stage heights stay as three classes on `.stage-wrap`: `.stage-wrap-std` (468px), `.stage-wrap-ci` (347px). `.stage-wrap-bins`, `.stage-wrap-mm` and `.stage-wrap-400` are removed and the qmd updated.

## 6. Sim cells

### 6.1 Cells to trim

Ten cells exceed the budget in §4.3. Six are over by one or two lines and lose blank lines or a comment the prompt already states; four need a real edit. In every case the knob line (`# <--`) and the printed result stay identical.

| cell | lines | lede | budget | how |
|---|---|---|---|---|
| `cheb-sim` | 11 | yes | 9 | drop the blank line and merge `mu`/`s` onto the line that already declares both |
| `cond-sim` | 10 | yes | 9 | drop one blank line |
| `seller-sim` | 13 | no | 11 | fold `rel` and `good` into one-line definitions |
| `pois-sim` | 10 | yes | 9 | drop one blank line |
| `clt-sim` | 15 | no | 11 | `pop` and `sigma` on one line; `hist` call on two lines instead of three; drop blank lines |
| `ci-sim` | 16 | no | 11 | combine `mu`/`sigma`/`n`/`conf` into two lines; `plot(NA, ...)` on one line; `abline` and `segments` tightened |
| `ci-t-vs-z` | 15 | no | 11 | `coverage` as a two-line function; drop blank lines |
| `alpha-sim` | 10 | yes | 9 | drop one blank line |
| `ovb-sim` | 11 | yes | 9 | drop blank lines |
| `smooth-sim` | 13 | yes | 9 | move the `F2 is given` comment into the lede; `err` as a two-line function; drop blank lines |

If a cell cannot reach budget without harming readability, the fallback is to move its `.lede-min` sentence into the `.try-this` prompt (which is below the card and sized for it) and use the 11-line budget.

### 6.2 R plot text

A hidden cell at the top of `sections/00-how-to-use.qmd`:

````
```{webr-r}
#| context: setup
setHook("before.plot.new", function() par(cex = 1.4, mar = c(4.2, 4.2, 2, 1)))
```
````

`context: setup` cells are hidden and autorun by the quarto-webr filter. The hook runs at every `plot.new()`, so `hist()` and `plot()` in the four plot cells inherit larger text with no visible line in the teaching code. **Fallback** if the hook does not fire inside webR's canvas device: one explicit `par(cex = 1.4)` line at the top of each of the four plot cells (`bins-sim`, `seller-sim`, `clt-sim`, `ci-sim`), counted against their line budget.

The four plot cells also set:

```
#| fig-width: 4.6
#| fig-height: 3.7
```

At the filter's default 72 dpi that is a 331×266px canvas, scaled up into the roughly 400px plot column, so the 12pt base text lands near 15px before the `cex` multiplier and near 21px after it.

## 7. CSS change list

`assets/seminars.scss`:

- `.stage-wrap` heights and the `.stage` class (§5.2).
- `.slide-footer` override: 0.66em, `--ink`, 980px, margin-top 0.45em.
- `.slide-kicker` override: 0.46em.
- `.sim-card .qwebr-editor`: 0.72em; Monaco line height 1.3 via the extension's `editor-font-scale` if it controls line height, else a CSS override on `.monaco-editor .view-lines`.
- `.sim-card .qwebr-output-code-area pre`: 0.72em of the slide root (about 26px), line height 1.2.
- `.try-this`: 0.64em.
- `.sem-mark::before`: 4.4em, 18% alpha.
- `.reveal section.hero > p`: 1.3em. `.reveal section.hero .lede`: colour `--ink`.

`assets/theme.scss` is shared with the intro-r deck's history and is not edited; every override lives in `seminars.scss`.

## 8. Verification

### 8.1 `scripts/check-render.sh` additions

- `StageKit.register` appears in the render (kit included).
- exactly 18 `class="stage"` divs.
- no `webr-r` cell in `sections/*.qmd` exceeds 11 lines; none on a slide containing `.lede-min` exceeds 9 (an awk pass over the sources, same as the count used to write §6.1).
- the setup cell is present (`context: setup` in the sources; a hidden qwebr cell in the render).
- all existing checks kept.

### 8.2 `scripts/probe-overflow.js`

A console snippet, run once in the browser after render, that reports:

- every leaf slide whose `scrollHeight` exceeds 700px (measured with the slide forced visible), expected: none;
- every `.stage` whose `.fragment` count differs from what its kit registration declared (the kit exposes `StageKit.registry` for this), expected: none;
- the computed font size of the smallest `<text>` in each stage SVG, expected: at least 18.

### 8.3 Browser pass

At 1024×768, 1280×720 and 1920×1080: one hero, one stage at its final fragment, one text sim after Run, one plot sim after Run. Then a forward and backward fragment walk on all 18 stages, and a Run of all four plot cells at one size. Screenshots saved to the scratchpad and summarised in the final report.

## 9. Risks and fallbacks

| risk | fallback |
|---|---|
| `before.plot.new` hook does not fire in webR's canvas device | explicit `par()` line per plot cell (§6.2) |
| Monaco ignores a CSS line-height override | keep 1.4 and lower the editor to 0.68em; budget stays 11/9 |
| a stage's larger labels collide at 445 height | move elements, do not shrink text; if a caption must go, fold it into the `.slide-footer` |
| `quarto render` picks up a stale include | `freeze: false` is already set; `check-render.sh` compares cell counts |

## 10. Out of scope, deferred to project 2

New intuition and simulation slides for seminars 1, 2, 7 and 9; any pedagogy review of existing slides beyond keeping them intact through the retune.
