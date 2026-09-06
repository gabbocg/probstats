# Seminar 3 rebuilt on the 3Blue1Brown Bayes lesson

**Date:** 2026-09-06
**Deck:** `bman10750-slides/` ("Statistics, Simulated"), section `sections/03-probability.qmd`
**Depends on:** `2026-09-05-projection-presence-design.md` (the stage kit, the slide grid, the sim-cell limits). Implemented after that project.
**Status:** design approved in conversation; review round 1 fixes verified by exact counts (round 2 reviewer was cut off by a rate limit); awaiting user review
**Source lesson:** 3Blue1Brown, "Bayes theorem, the geometry of changing beliefs" (https://www.3blue1brown.com/lessons/bayes-theorem)

## 1. Goal

Rebuild the probability section so it follows the lesson's arc: the Steve question as Kahneman and Tversky posed it, a representative sample of people, the sample redrawn as a unit square with the prior as a width and the likelihoods as heights, the formula read off that square, the two lessons (evidence updates rather than determines; equal likelihoods change nothing), the Linda experiment as the reason to think in counts, and the worksheet's office-manager problem as the same square. Nine slides replace the current six.

The visual language, palette and slide types are the deck's existing ones as sized by the presence spec. Nothing here introduces a new look.

## 2. Non-goals

- No change to any other seminar.
- No change to the office-manager numbers (80% buy; 40% and 10% upgrade; 32/34) or to the "count the managers" cell's code.
- No embedding of the video or its assets. The deck reuses the lesson's numbers and argument; every drawing and every word is the deck's own.
- No new palette colours: navy is the hypothesis, grey its complement, orange the evidence, brick the posterior.

## 3. Numbers

The lesson's numbers replace the deck's. One script, `assets/js/bayes-data.html`, defines `window.BayesData` from four inputs and derives the rest; the three Steve stages and the check in §8 read from it, and nothing about Steve is typed anywhere else.

| quantity | value | derivation |
|---|---|---|
| librarians in the sample | 10 | input |
| farmers in the sample | 200 | input (20 farmers per librarian) |
| P(description \| librarian) | 0.40 | input |
| P(description \| farmer) | 0.10 | input |
| sample size | 210 | 10 + 200 |
| prior P(L) | 1/21 ≈ 0.0476 | 10/210 |
| librarians who fit | 4 | 10 × 0.40 |
| farmers who fit | 20 | 200 × 0.10 |
| everyone who fits | 24 | 4 + 20 |
| posterior P(L \| D) | 4/24 = 0.1667 | count |
| numerator as probability | 0.01905 | (1/21) × 0.40 |
| grey term as probability | 0.09524 | (20/21) × 0.10 |
| denominator P(D) | 0.11429 | sum |

The script asserts that `numerator / denominator` equals `4 / 24` to 12 decimal places and throws on load if a future edit breaks it. The grid is 21 columns × 10 rows; the librarian column is column 0; the fitting librarians are rows 1, 3, 6, 8; the fitting farmer in column c is row `(3c + 2) mod 10`, so the marks do not read as a ruled line.

The current deck uses 200 people and 4/23 = 17%; those numbers disappear with the old files.

## 4. The nine slides

All ids below are the ones `check-render.sh` will look for. Fragment ids follow the deck convention (`<stage>-frag-<k>`, invisible `.fi-frag` spans, state k = k fragments visible) for the stages; the two claim-pair slides use ordinary visible `.fragment` classes on the `.claim-pair` container (and, on the hook, on the `.slide-footer`), never on individual cells.

| # | id | class | stage / cell | fragments |
|---|---|---|---|---|
| 1 | `s03-probability` | `.hero` | | |
| 2 | `bayes-hook` | (plain) | claim pair | `hook-frag-1`, `hook-frag-2` (visible) |
| 3 | `bayes-grid` | `.stage-slide` | `#bayes-grid-stage` | `bayes-grid-frag-1..4` |
| 4 | `bayes-square` | `.stage-slide` | `#bayes-square-stage` | `bayes-square-frag-1..4` |
| 5 | `bayeq-formula` | `.stage-slide` | `#bayeq-stage` | `bayeq-frag-1..5` |
| 6 | `bayes-sim` | `.sim-slide` | text cell, 8 lines | |
| 7 | `linda` | (plain) | claim pair | `linda-frag-1` (visible) |
| 8 | `cond-intuition` | `.stage-slide` | `#cond-stage` (kept) | `cond-frag-1..3` (kept) |
| 9 | `cond-sim` | `.sim-slide` | text cell (kept) | |

### 4.1 Hero

Kept. The tagline becomes "Evidence should not determine beliefs. It should update them." The lede: every tree diagram and every "given that" on the worksheet is one move, discard the part of the world you now know did not happen and rescale what is left; drawn as areas, Bayes' theorem stops being a formula to memorise.

### 4.2 Hook

Title: "Librarian or farmer?" Body, top to bottom:

- Steve's description in `.lede-min`: shy and withdrawn, a meek and tidy soul with a need for order and structure and a passion for detail. (Paraphrased in the deck's words; a quotation is not needed.)
- `.claim-pair` carrying `.fragment` and the id `hook-frag-1` on the container itself, so one step reveals both cells and the id is unique (Reveal's own fragment rule applies to any element; no CSS is needed):
  - left, tagged **Most people**: "Librarian." Kahneman and Tversky put this question to people and most chose librarian; they called it irrational.
  - right, tagged **Nobody asks**: how many farmers are there? About twenty for every librarian.
- `.slide-footer` carrying `.fragment` and the id `hook-frag-2`: the psychologists' complaint is that the base rate never entered anyone's head. The argument since has been about whether 20 to 1 is the right prior here; it has never been about what to do with a prior once you have one. That is the next three slides.

The claim-cell tags reuse the existing `.claim-tag` style but neither cell is "wrong" or "right"; both use a neutral navy variant `.claim-neutral`, two rules in `seminars.scss` mirroring `.claim-wrong` (the cell's left border and the tag's tint).

### 4.3 Grid stage

`assets/js/bayes-grid-anim.html` replaces `bayes-anim.html`. Canvas 1000×445 at the standard wrap. Grid of 21×10 cells, 24 units square on a 27-unit pitch (564×267), left edge at x = 218, top at y = 52 (bottom at 319); caption at (40, 28) in the `caption` role. Vertical budget below the grid, all in canvas units: gather row y 352–376; a navy bracket under the first four row cells at y 382–392 (no label, the readout names it); readout baseline y 432 in the `readout` role, whose cap height (about 22) leaves an 18-unit gap above it.

| state | move | caption |
|---|---|---|
| 0 | 210 grey cells, Steve is one of them | 210 people who could be Steve |
| 1 | column 0 fills navy | 10 librarians, 200 farmers: the prior |
| 2 | orange rings on 4 navy and 20 grey cells | 40% of librarians fit, 10% of farmers: the likelihoods |
| 3 | unringed cells fade to 12% | keep only the people who fit: 24 remain |
| 4 | the 24 survivors slide into one row at y = 352, 4 navy then 20 grey on the 27-unit pitch (645 wide, centred at x 178–823); the navy bracket appears; the readout assembles: `P(librarian | description) = 4 / 24 = 16.7%` with the 4 in navy and the 24 in ink | the answer is a ratio |

There is no second bracket: the row's total is carried by the readout's "24", so the two spans never have to share a tier. Motion: cells move with `outCubic` over 620ms and a 12ms stagger. `.slide-footer`: almost everyone says librarian; the description does fit librarians four times better, and Steve is still five times more likely to be a farmer, because there are twenty times as many of them. Both facts are in the picture at once.

### 4.4 Square stage

`assets/js/bayes-square-anim.html`, new. Canvas 1000×445. Regions, left to right:

| region | x | contents |
|---|---|---|
| left gutter | 150–195 | the 0.40 height bracket beside the navy strip, label in the `label` role |
| the square | 200–540, y 60–400 | 340×340; column c is a strip 340/21 ≈ 16.19 wide at x = 200 + c·16.19; row r is a band 34 tall at y = 60 + r·34 |
| right gutter | 545–590 | the 0.10 height bracket beside the grey band |
| readout | 620–980 (360 wide) | three tiers, see state 4 |
| below the square | y 405–445 | width bracket under the navy strip at y 405–415, label `P(L) = 1/21` at baseline 438 in the `label` role, left-anchored at x = 200 |

The navy strip is column 0, the leftmost, so its height bracket sits on its left; the grey band's bracket sits on the square's right edge. Every tile's melt target is computed from `BayesData` and the square constants, not typed.

| state | move | caption |
|---|---|---|
| 0 | the grid at exactly the geometry of `bayes-grid` state 2 (all 210 cells at x = 218, y = 52 on the 27 pitch; navy column; orange rings). The presenter sees the gathered row from the previous slide snap back into the grid at the slide change; the caption owns that | back to all 210 people |
| 1 | **melt**: every cell tweens `x, y, width, height` into its tile of the square; gaps close; the navy strip is now visibly thin | drawn as area: the librarian strip is 1/21 wide |
| 2 | **shade**: inside every column the ringed tiles slide to the bottom of the strip and fuse into one orange block (rings disappear, fill turns orange): 4 tiles = 0.40 of the navy strip, 1 tile = 0.10 of each grey strip; the grey blocks fuse sideways into one band 20 strips wide | the likelihoods are heights: 0.40 and 0.10 |
| 3 | **cut away**: unshaded tiles fade to 8%; the three brackets appear (left gutter 0.40, right gutter 0.10, width bracket below) | throw away everyone who does not fit |
| 4 | **read**: the readout assembles in its region as three tiers, top to bottom: (i) `navy area` over `all shaded` as a fraction in the `label` role; (ii) `1/21 × 0.40` over `1/21 × 0.40 + 20/21 × 0.10` in the `label` role (the denominator is 26 characters, 312 units at 12 per character, inside the 360); (iii) `= 4/24 = 16.7%` in the `readout` role (14 characters, 252 units) | the posterior is the navy share of what is left |

Melt and shade tween positions and sizes over 800ms `outCubic` with a 4ms stagger across 210 tiles. Under reduced motion every state snaps. `.slide-footer`: nothing was recomputed. The strip's width is the prior, the shaded heights are the likelihoods, and dividing one shaded area by all of it is the rescaling the grid did with counts. Areas are counts that forgot how to be whole numbers.

### 4.5 Formula stage

`assets/js/bayeq-anim.html` rewritten (same file name, same stage id `bayeq-stage`, fragments now five). Canvas 1000×445. Left: the square in its state-3 form scaled to 260×260 at x = 60..320, y = 90..350 with the three brackets. Right, x = 380..980 (600 wide): the formula in the `readout` role (mono 30, 18 units per character), with the left-hand side on its own line so the fraction has the full width:

```
P(L|D) =
            P(L) · P(D|L)
   ─────────────────────────────
   P(L)·P(D|L) + P(F)·P(D|F)
```

The denominator is 25 characters, 450 units, plus 16-unit bar overhangs: 482 of the 600. The arithmetic line sits beneath in the `label` role: `0.0190 / (0.0190 + 0.0952) = 0.167 = 4/24` (41 characters, 492 units), assembled term by term.

| state | lights up in the formula | lights up on the square | note (label role, coloured to match) |
|---|---|---|---|
| 1 | `P(L)` navy | the strip's width bracket | the prior is a width |
| 2 | `P(D\|L)` orange | the navy block's height bracket | the likelihood is a height |
| 3 | `P(L)·P(D\|L)` boxed | the navy block itself pulses | width × height: the navy area, 0.0190 |
| 4 | the whole denominator boxed | both blocks pulse together | everyone who fits: 0.0190 + 0.0952 |
| 5 | `P(L\|D)` brick | navy block over both blocks, drawn as a small ratio glyph | the navy share: 4/24 |

`.slide-footer`: the formula is the picture written down. Numerator, one rectangle; denominator, every rectangle that survived the evidence; and 0.0190/0.1143 is 4/24 exactly, because the areas are the counts divided by 210.

### 4.6 Two knobs cell

`bayes-sim` keeps its id and its slide; the cell becomes:

```r
prior    <- 1/21     # <-- P(librarian)
fit_lib  <- 0.40     # <-- P(desc | librarian)
fit_farm <- 0.10     # <-- P(desc | farmer)
n <- 300000
lib <- runif(n) < prior
fit <- runif(n) < ifelse(lib, fit_lib, fit_farm)
round(c(prior = prior,
        posterior = mean(lib[fit])), 3)
```

Eight lines, longest 48 characters (the `fit <-` line, exactly), prints two numbers (0.048 and about 0.167). Kicker: "Seminar 3 · the knobs". `.try-this`: set `fit_farm <- 0.40` and run: the description now says nothing about profession and the posterior lands back on the prior. That is the worksheet's independence test, P(E | H) = P(E), seen from the other side. Put it back, then move the prior to 0.50 and watch the same evidence give 0.80.

### 4.7 Linda

Title: "Which is more probable?" Body:

- `.lede-min`: Linda is 31, single, outspoken and bright; she majored in philosophy and cared deeply about discrimination and social justice.
- `.claim-pair` carrying `.fragment` and the id `linda-frag-1` on the container:
  - left, tagged **As probabilities**: (a) Linda is a bank teller. (b) Linda is a bank teller and active in the feminist movement. 85% of people chose (b), which cannot be more probable than (a) because it is part of (a).
  - right, tagged **As counts**: 100 people fit this description. How many are bank tellers? How many are bank tellers and feminists? Asked this way, nobody puts the second number above the first.
- `.slide-footer`: "40 out of 100" kicks intuition into gear where "40%" does not. So the next cell does what the square did with areas, with people you can count.

Both tags use `.claim-neutral`.

### 4.8 Manager square

`cond-anim.html` is kept (retuned to the kit by the presence project) and only its four captions change, to the lesson's vocabulary:

| state | caption |
|---|---|
| 0 | width is P(buy) = 0.80 |
| 1 | heights: 40% of buyers upgrade, 10% of the rest |
| 2 | cut away: 66% of managers are gone |
| 3 | the posterior is the buyers' share of what is left: 32/34 = 94% |

Title: "Your worksheet's Exercise 5, as the same square". `.slide-footer`: the tree diagram on the worksheet is this square with the branches drawn as lines instead of edges. Counting people, drawing a tree or splitting a unit square is one operation, and the answer is always a ratio of what survived.

### 4.9 Count the managers

Cell unchanged. Kicker unchanged. `.lede-min` becomes Linda's lesson in one line: count people and the error disappears, so here are 200,000 managers, and we count the ones we care about.

## 5. Files

| file | action |
|---|---|
| `sections/03-probability.qmd` | rewritten to the nine slides above |
| `assets/js/bayes-data.html` | new; `window.BayesData` with the assertion |
| `assets/js/bayes-grid-anim.html` | new (replaces `bayes-anim.html`, which is deleted) |
| `assets/js/bayes-square-anim.html` | new |
| `assets/js/bayeq-anim.html` | rewritten in place |
| `assets/js/cond-anim.html` | captions only |
| `_quarto.yml` | `include-after-body`: `bayes-data.html` before the three Steve stages; `bayes-anim.html` removed; `bayes-grid-anim.html` and `bayes-square-anim.html` added |
| `assets/seminars.scss` | `.claim-neutral`: two rules mirroring `.claim-wrong` (navy left border on the cell, navy tint on the tag). No fragment CSS: Reveal's own rule covers the two claim-pair containers |
| `scripts/check-render.sh` | slide ids, stage ids and fragment ids updated per the table in §4; the `class="stage"` count goes from 18 to **19** (one stage replaced by two); the intro webR cell count stays as computed from the sources |
| `scripts/probe-overflow.js` | its fragment check counts `.fi-frag` spans, not every `.fragment`, so the two claim-pair slides do not trip it |

All three Steve stages register through `StageKit.register` and use `StageKit.PAL`, `FONT`, `TYPE`, `txt` and `canvas`; none defines its own helpers.

## 6. Presence spec adjustments

Recorded here and mirrored in the presence spec:

- `bayes-anim.html` and `bayeq-anim.html` are **not retuned** in the presence project; they are replaced here. Until this project lands they keep their old code, get `class="stage"` and the standard wrap so the shared CSS applies, and render at 1000×400 inside the 468px wrap (slightly smaller than the retuned stages, for the interim only).
- The presence project retunes 16 stages, not 18, and `check-render.sh` keeps the old `bayes` and `bayeq` ids until this project changes them.
- After this project the deck has 19 stages (the Steve grid and the square are two), so the presence spec's "exactly 18 `class="stage"` divs" check and its "all 18 stages" fragment walk become 19.
- The presence spec's overflow probe counts `.fi-frag` spans rather than every `.fragment`.

## 7. Verification

- `bayes-data.html` throws on load if the algebra and the count disagree; the browser console is checked for that after render.
- `check-render.sh` passes with the new ids; the two cells stay within the presence spec's limits (8 lines, 48 characters; the manager cell unchanged).
- Fragment walk forward and backward on `bayes-grid`, `bayes-square`, `bayeq-formula` and `cond-intuition`; state 0 of `bayes-square` is geometrically identical to state 2 of `bayes-grid` (same cell positions, sizes, fills and rings, checked by comparing the two SVGs' cell attributes in the probe); the melt and shade play under normal motion and snap under `prefers-reduced-motion`.
- Run of `bayes-sim` at the defaults (posterior near 0.167), with `fit_farm <- 0.40` (posterior near 0.048), and with `prior <- 0.50` (near 0.80); run of `cond-sim` (0.94).
- Screenshots at 1280×720 of slides 2, 4 (final state), 5 (final state) and 7, saved to the scratchpad and summarised in the final report.

## 8. Out of scope

Any other seminar; the content project for seminars 1, 2, 7 and 9, which follows this one.
