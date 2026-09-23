# Probability & Statistics

A visual introduction, as a Quarto / reveal.js deck.

**[View it →](https://gabbocg.github.io/probstats/)**

Most ideas arrive as something you step through rather than something
asserted: the mean is the height the bars level off to, conditioning is a
sample space shrinking, the binomial is 20,000 samples piling into the bars
before the formula appears. R runs in the browser, so a reader can change a
number and re-run without installing anything.

## Running it

```bash
quarto render                  # builds _site/
quarto preview                 # live reload while editing
bash scripts/check-render.sh   # acceptance checks
bash scripts/publish.sh        # render, check, deploy to GitHub Pages
```

`check-render.sh` runs against the **rendered** output, not the sources. It
guards the failure modes that actually bit while building this: a stale
render, a slide losing its animation stage or its gating fragments, a
sim-card missing its layout variant, webR chunks not reaching the filter,
and a code cell outgrowing the projection budget (10-14 lines, 48
characters). Run it after every change.

## Layout

| path | what |
|---|---|
| `index.qmd` | front matter and the section includes |
| `sections/` | one file per seminar |
| `assets/theme.scss`, `assets/seminars.scss` | the deck's look |
| `assets/js/stage-kit.html` | shared palette, type scale and stage registry |
| `assets/js/*-anim.html` | one animated stage each, built on StageKit |
| `assets/vendor/` | Monaco and anime.js, vendored |
| `scripts/` | the checks and the deploy |
| `docs/superpowers/` | design specs and plans |

## Things worth knowing before editing

- **Nothing loads from a CDN except MathJax.** Monaco is vendored under
  `assets/vendor/` because quarto-webr hardcodes a jsdelivr URL, and on a bad
  network every code cell renders as an empty box. `check-render.sh` fails if
  that URL reappears, which it does after `quarto update`.
- **Deploy with `scripts/publish.sh`, not `quarto publish gh-pages`.** The
  latter ships only the resources it can discover from `<script src>` and
  `<link href>` in the HTML, so it silently drops 105 of the 107 files under
  `assets/vendor/` — Monaco's `editor.main.js` among them. The editors then
  404 on the deployed site while working perfectly in `quarto preview`.
  `publish.sh` pushes `_site/` verbatim.
- **Adding a new `include-after-body` file needs a clean render**
  (`rm -rf .quarto _site && quarto render`). Quarto silently drops a newly
  added include on an incremental render and still reports success.
- **A slide is 1050 x 700.** Stages draw on a 1000 x 445 canvas at scale 1.05.
  Measure with `offsetTop + offsetHeight`, never `getBoundingClientRect` —
  reveal scales the deck and the rects are in screen pixels.
- **Some slides are commented out** (`<!-- ... -->` in `sections/` and in
  `index.qmd`'s include list). `check-render.sh` knows which, and asserts
  they stay out of the render.
