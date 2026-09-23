# Probability & Statistics

A visual introduction, built as a Quarto / reveal.js deck. R runs in the
browser, so a reader can change a number and re-run without installing
anything.

**[View it →](https://gabbocg.github.io/probstats/)**

## Running it

```bash
quarto render                  # builds _site/
quarto preview                 # live reload while editing
bash scripts/check-render.sh   # acceptance checks, run after every change
bash scripts/publish.sh        # render, check, deploy to GitHub Pages
```

Deploy with `scripts/publish.sh`, not `quarto publish gh-pages` — the latter
drops most of `assets/vendor/`, and the code editors then 404 on the
deployed site while working fine locally.

## Layout

| path | what |
|---|---|
| `index.qmd` | front matter and the section includes |
| `sections/` | one file per seminar |
| `assets/*.scss` | the deck's look |
| `assets/js/stage-kit.html` | shared palette, type scale and stage registry |
| `assets/js/*-anim.html` | one animated stage each |
| `assets/vendor/` | Monaco and anime.js, vendored so nothing needs a CDN |
| `scripts/` | the checks and the deploy |
