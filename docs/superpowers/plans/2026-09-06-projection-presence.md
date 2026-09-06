# BMAN10750 Deck: Projection Presence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Size the BMAN10750 Reveal.js deck for a projected seminar room without changing its look: stages fill the slide with labels of at least 18 canvas units, code and output are readable from the back row, and no slide overflows 700px.

**Architecture:** A shared `StageKit` script replaces the boilerplate that 18 SVG animation files duplicate (palette, fonts, type scale, `el`, canvas builder, Reveal fragment wiring); each animation is then retuned to a taller 1000×445 canvas. Sim cells are resized through the webR extension's `editor-font-scale` plus CSS and a small Monaco tuning script, and every cell is held to a line budget and a 48-character line limit enforced by `scripts/check-render.sh`. Two Seminar 3 stages (`bayes`, `bayeq`) are deliberately not retuned; a following project replaces them.

**Tech Stack:** Quarto 1.9 revealjs, quarto-webr extension (vendored, not edited), anime.js v4 (already loaded), plain ES5 JavaScript in `include-after-body` HTML fragments, SCSS via Quarto's theme pipeline, bash + awk for checks.

**Spec:** `bman10750-slides/docs/superpowers/specs/2026-09-05-projection-presence-design.md` (read it first; section numbers below refer to it).

---

## Working context (read before Task 0)

- Deck root: `/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz/bman10750-slides/`. All relative paths below are from this directory unless they start with the repo root. The repo root is one level up and is a git repository on branch `main`.
- **Git state warning.** The repo root has a large uncommitted restructure (164 deleted files, three untracked directories) that belongs to the user. Never run `git add -A`, `git add .` at the root, `git stash`, `git checkout -- .`, or `git reset`. Only ever `git add` the specific paths named in a task. Task 0 commits the deck directory as a baseline so later diffs are meaningful.
- Every commit message ends with these two trailer lines:
  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L
  ```
- **Render:** `quarto render` (about 20 seconds, writes `_site/index.html`). Nothing executes at render time; every code cell is `webr-r` and runs in the browser. `freeze: false` is already set, so include-file edits are always picked up.
- **Static checks:** `bash scripts/check-render.sh` after every render. It must print `All checks passed.`
- **Browser checks:** serve the render and open it in Chrome:
  ```bash
  python3 -m http.server 8765 --bind 127.0.0.1 -d _site &
  # open http://127.0.0.1:8765/index.html#/<slide-id>
  ```
  Slides are addressed by id, e.g. `#/clt-intuition`. Fragments advance with the Right arrow. Use the Claude-in-Chrome tools if available (`tabs_context_mcp`, `navigate`, `computer` for screenshots and keys, `javascript_tool` for the probe); otherwise do it by hand. Kill the server with `pkill -f "http.server 8765"` when done.
- **Reveal geometry:** the slide is a fixed 1050×700 box scaled to the viewport; `Reveal.getScale()` gives the factor. All px values in this plan are slide px (canvas units for SVG stages, which are shown at `scale(1.05)`).
- The user is not available for questions during execution. Where a task says "adjust until", use judgement and record what you chose in the commit message.

## File map

| file | responsibility | task |
|---|---|---|
| `_quarto.yml` | webR document options; include order (kit first, sim-tune last) | 1 |
| `assets/js/stage-kit.html` (new) | palette, fonts, type scale, `el`/`txt`/`canvas`, `register` with Reveal wiring, `registry` | 2 |
| `assets/js/sim-tune.html` (new) | Monaco `updateOptions` (line height, no gutter) | 3 |
| `assets/seminars.scss` | every CSS change: stage classes, sim sizes, chrome, hero | 4 |
| `sections/*.qmd` | `class="stage"`, wrap classes, setup cell, plot options, 13 cell rewrites, two copy edits | 4, 6, 7, 8 |
| `scripts/check-render.sh` | static checks incl. cell budgets | 5 |
| `scripts/probe-overflow.js` (new) | browser console probe | 5 |
| `assets/js/bins-anim.html` | first retune, fully rewritten as the worked example | 9 |
| `assets/js/{mm,binom,cieq,ciflip,clt,cond,expo,ls,pair,pois,pval,seller,smooth,zstd}-anim.html` | retunes on the kit | 10–23 |
| `assets/js/ci-anim.html` | re-layout to 1000×330 | 24 |
| `assets/js/bayes-anim.html`, `assets/js/bayeq-anim.html` | **not touched** (replaced by the next project); their divs still get `class="stage"` in Task 4 | — |

---

### Task 0: Baseline commit of the deck

**Files:** everything under `bman10750-slides/` except ignored build output.

- [ ] **Step 1: Confirm what will be added**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git status --short bman10750-slides | head -5
git check-ignore -v bman10750-slides/_site/index.html bman10750-slides/.quarto
```
Expected: `?? bman10750-slides/...` lines; the check-ignore lines show `_site/` and `.quarto/` are ignored (from the root `.gitignore`).

- [ ] **Step 2: Add only the deck directory and commit**

```bash
git add bman10750-slides
git status --short | grep -v '^A  bman10750-slides/' | grep -v '^ D ' | grep -v '^??' ; echo "(anything printed above is unexpected)"
git commit -m "chore: track the BMAN10750 seminar deck baseline

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```
Expected: one commit; `git show --stat HEAD | tail -1` reports about 60 files, none under `_site/`.

---

### Task 1: `_quarto.yml` — font scale and include order

**Files:**
- Modify: `_quarto.yml`

- [ ] **Step 1: Replace the file with this content**

```yaml
project:
  type: default
  render: ["index.qmd"]
  output-dir: _site
  resources:
    - assets/vendor/

filters:
  - webr

webr:
  packages: []
  show-startup-message: false
  autoload-packages: true
  # The extension multiplies each cell's CSS font-size by this. The revealjs
  # default is 0.5, which silently halved every size seminars.scss set.
  cell-options:
    editor-font-scale: 1

format:
  revealjs:
    theme: [default, assets/theme.scss, assets/seminars.scss]
    slide-number: c/t
    revealjs-plugins:
      - drop
    progress: true
    controls: true
    controls-layout: edges
    controls-back-arrows: visible
    navigation-mode: linear
    footer: "[gcabrerag.rbind.io](https://gcabrerag.rbind.io)"
    transition: fade
    transition-speed: fast
    history: true
    chalkboard:
      buttons: true
    menu:
      side: left
      numbers: true
    include-in-header:
      - file: assets/head.html
    include-after-body:
      # stage-kit must precede every *-anim.html: they read window.StageKit at load.
      - file: assets/js/stage-kit.html
      - file: assets/animations.html
      - file: assets/js/bins-anim.html
      - file: assets/js/mm-anim.html
      - file: assets/js/bayes-anim.html
      - file: assets/js/bayeq-anim.html
      - file: assets/js/cond-anim.html
      - file: assets/js/binom-anim.html
      - file: assets/js/seller-anim.html
      - file: assets/js/pois-anim.html
      - file: assets/js/expo-anim.html
      - file: assets/js/clt-anim.html
      - file: assets/js/zstd-anim.html
      - file: assets/js/ciflip-anim.html
      - file: assets/js/cieq-anim.html
      - file: assets/js/ci-anim.html
      - file: assets/js/pval-anim.html
      - file: assets/js/pair-anim.html
      - file: assets/js/ls-anim.html
      - file: assets/js/smooth-anim.html
      - file: assets/js/sim-tune.html
    code-line-numbers: false
    code-copy: false
    highlight-style: assets/syntax.theme

execute:
  echo: true
  warning: false
  message: false
  # NOT `freeze: auto`. Freeze keys its cache on index.qmd alone, so edits to
  # the {{< include >}}d files in sections/ silently render stale slides.
  # Nothing here executes at render time anyway — every chunk is `webr-r`,
  # which runs client-side — so there is no cost to leaving freeze off.
  freeze: false

knitr:
  opts_chunk:
    dev: "svg"
    fig.width: 7
    fig.height: 4.2
    fig.align: "center"
```

- [ ] **Step 2: Create empty placeholders so the render does not fail on missing includes**

```bash
printf '<script>/* stage-kit placeholder, replaced in Task 2 */</script>\n' > assets/js/stage-kit.html
printf '<script>/* sim-tune placeholder, replaced in Task 3 */</script>\n' > assets/js/sim-tune.html
```

- [ ] **Step 3: Render and check the scale reached the page**

```bash
quarto render 2>&1 | tail -2 && bash scripts/check-render.sh | tail -1
grep -c '"editor-font-scale":"1"' _site/index.html
```
Expected: `Output created: _site/index.html`, `All checks passed.`, and a count of 17 (the merged option is serialised into every cell's JSON as the string `"1"`; a bare `editor-font-scale` grep would also match the default `"0.5"` and prove nothing).

- [ ] **Step 4: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/_quarto.yml bman10750-slides/assets/js/stage-kit.html bman10750-slides/assets/js/sim-tune.html
git commit -m "feat(deck): set editor-font-scale 1 and wire kit/sim-tune includes

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 2: The stage kit

**Files:**
- Create (overwrite the placeholder): `assets/js/stage-kit.html`

- [ ] **Step 1: Write the kit**

```html
<script>
/*
  StageKit — the shared runtime for the deck's SVG stage animations.

  Every *-anim.html used to carry its own copy of: the palette as hex
  literals, the two font strings, an `el()` helper, and forty lines of
  Reveal wiring (mount on slide change, snap to the right state when the
  slide is entered via a #hash or by stepping backwards, forward/backward
  fragment handling). This file owns all of that once.

  Contract for a stage file:
    StageKit.register({
      stage: 'clt-stage',                       // id of the stage div
      frags: ['clt-frag-1', 'clt-frag-2'],      // in order; state k = k visible
      build: function (stageEl) { ... return handle; },   // draws state 0
      place: function (handle, state, instant) { ... },   // moves to `state`
      stop:  function (handle) { ... }          // optional: cancel timers/tweens
    });
  `place` is called with instant=true on mount (always, including state 0),
  and with instant=false on fragment changes. A stage with no fragments
  registers frags: [] and may omit place.

  Type roles (canvas units; the stage is shown at scale(1.05)):
    tick 18 · label 20 · caption 24 · readout 30
  Nothing drawn inside a stage may be smaller than `tick`.
*/
(function () {
  var NS = 'http://www.w3.org/2000/svg';

  var PAL = {
    navy:    '#325D88',   // the hypothesis, the deck's voice
    olive:   '#93C54B',   // output / success
    orange:  '#F47C3C',   // attention, the student's turn, the evidence
    brick:   '#B94A48',   // the posterior, misses, the null's tail
    ink:     '#3E3F3A',
    inkSoft: '#6E7681',
    dim:     '#B0B7C0',
    rule:    '#E5E7EB',
    white:   '#FFFFFF'
  };
  var FONT = { mono: 'JetBrains Mono, monospace', sans: 'Roboto, sans-serif' };
  var TYPE = { tick: 18, label: 20, caption: 24, readout: 30 };
  var REDUCE = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function animeReady() {
    return typeof window.anime !== 'undefined' &&
           typeof window.anime.animate === 'function';
  }

  function el(name, attrs) {
    var e = document.createElementNS(NS, name);
    for (var k in attrs) {
      if (attrs[k] !== undefined && attrs[k] !== null) e.setAttribute(k, attrs[k]);
    }
    return e;
  }

  // txt(x, y, 'string', { size: 'tick'|'label'|'caption'|'readout',
  //                       face: 'mono'|'sans', fill: PAL name or hex,
  //                       anchor: 'start'|'middle'|'end', weight: 700, cls: '' })
  function txt(x, y, str, o) {
    o = o || {};
    var t = el('text', {
      x: x, y: y,
      fill: PAL[o.fill] || o.fill || PAL.inkSoft,
      'font-size': TYPE[o.size] || o.size || TYPE.label,
      'font-family': FONT[o.face] || FONT.sans,
      'text-anchor': o.anchor || 'start',
      'font-weight': o.weight,
      'class': o.cls
    });
    t.textContent = str;
    return t;
  }

  function canvas(stage, W, H) {
    stage.innerHTML = '';
    var svg = el('svg', { viewBox: '0 0 ' + W + ' ' + H, width: W, height: H });
    stage.appendChild(svg);
    return svg;
  }

  var registry = {};

  function register(spec) {
    var frags = spec.frags || [];
    registry[spec.stage] = { frags: frags.slice() };
    var index = {};
    frags.forEach(function (id, i) { index[id] = i; });
    var current = null;

    // How many gating fragments Reveal currently shows on this slide. Landing
    // via a #hash or stepping backwards leaves fragments already .visible.
    function fragState(slide) {
      var n = 0;
      frags.forEach(function (id) {
        var f = slide.querySelector('#' + id);
        if (f && f.classList.contains('visible')) n++;
      });
      return n;
    }

    function mount(slide) {
      if (current && spec.stop) spec.stop(current);
      current = null;
      if (!slide) return;
      var stageEl = slide.querySelector('#' + spec.stage);
      if (!stageEl) return;
      current = spec.build(stageEl);
      if (spec.place) spec.place(current, fragState(slide), true);
    }

    function init() {
      if (typeof Reveal === 'undefined') { setTimeout(init, 30); return; }
      Reveal.on('slidechanged', function (e) { mount(e.currentSlide); });
      Reveal.on('ready', function () { mount(Reveal.getCurrentSlide()); });
      Reveal.on('fragmentshown', function (e) {
        var i = index[e.fragment.id];
        if (current && i !== undefined && spec.place) spec.place(current, i + 1, false);
      });
      Reveal.on('fragmenthidden', function (e) {
        var i = index[e.fragment.id];
        if (current && i !== undefined && spec.place) spec.place(current, i, false);
      });
    }
    init();
  }

  window.StageKit = {
    PAL: PAL, FONT: FONT, TYPE: TYPE, REDUCE: REDUCE,
    animeReady: animeReady, el: el, txt: txt, canvas: canvas,
    register: register, registry: registry
  };
})();
</script>
```

- [ ] **Step 2: Render and verify the kit is present and inert**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | tail -1
grep -c 'window.StageKit = ' _site/index.html
```
Expected: `All checks passed.` and `1`.

- [ ] **Step 3: Browser smoke test**

Serve `_site`, open `http://127.0.0.1:8765/index.html#/bins-intuition`, and in the console run:
```js
[typeof StageKit.register, StageKit.TYPE.tick, Object.keys(StageKit.registry).length]
```
Expected: `["function", 18, 0]` (nothing registers yet). The bins animation still plays as before (old code path).

- [ ] **Step 4: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/assets/js/stage-kit.html
git commit -m "feat(deck): add StageKit (palette, type scale, helpers, Reveal wiring)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 3: Monaco tuning script

**Files:**
- Create (overwrite the placeholder): `assets/js/sim-tune.html`

- [ ] **Step 1: Write the script**

```html
<script>
/*
  deck-sim-tune — Monaco editor options that CSS cannot reach.

  quarto-webr creates one Monaco instance per cell and stores it in the
  global sparse array `qwebrEditorInstances` (index = cell counter). Monaco
  positions its lines from its own metrics, so line height has to be an
  editor option, and the line-number gutter (about 50px at our font size)
  can only be removed the same way. Nothing in the deck refers to a line
  number.

  The instances are created asynchronously after the AMD loader fetches
  Monaco, so this polls four times a second until every .qwebr-editor on
  the page has an instance, or for 60 seconds, whichever comes first.
*/
(function () {
  var LINE_HEIGHT = 27;        // 20px font × 1.35; spec §4.3
  var PLOT_LINE_HEIGHT = 27;   // set to 25 only if the §6.2 par() fallback is needed
  var started = Date.now();

  function tune() {
    var list = window.qwebrEditorInstances || [];
    var want = document.querySelectorAll('.qwebr-editor').length;
    var have = 0;
    list.forEach(function (ed) {           // forEach skips the sparse holes
      if (!ed || typeof ed.updateOptions !== 'function') return;
      have++;
      if (ed.__deckTuned) return;
      var node = ed.getDomNode && ed.getDomNode();
      var inPlot = !!(node && node.closest && node.closest('.sim-plot'));
      ed.updateOptions({
        lineHeight: inPlot ? PLOT_LINE_HEIGHT : LINE_HEIGHT,
        lineNumbers: 'off',
        glyphMargin: false,
        folding: false,
        lineDecorationsWidth: 0,
        lineNumbersMinChars: 0
      });
      ed.__deckTuned = true;
    });
    if ((want === 0 || have < want) && Date.now() - started < 60000) {
      setTimeout(tune, 250);
    }
  }
  tune();
})();
</script>
```

- [ ] **Step 2: Render and verify in the browser**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | tail -1
```
Open `#/ci-t-vs-z`, wait 5 seconds for Monaco, run in the console:
```js
(function(){var ed=(qwebrEditorInstances||[]).filter(Boolean)[0];var O=monaco.editor.EditorOption;return [ed.getOption(O.lineHeight), ed.getOption(O.lineNumbers).renderType, ed.getOption(O.fontSize)];})()
```
Expected: `[27, 0, 26.64]` — line height tuned, line numbers off (renderType 0), and the font size is still the old CSS value ×1 (26.64px) until Task 4 sets 20px. The editor shows no gutter.

- [ ] **Step 3: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/assets/js/sim-tune.html
git commit -m "feat(deck): tune Monaco line height and drop the gutter

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 4: CSS and markup for the new grid

**Files:**
- Modify: `assets/seminars.scss` (replace whole file)
- Modify: `sections/*.qmd` (stage div class, wrap class names)

- [ ] **Step 1: Replace `assets/seminars.scss` with this content**

```scss
/*-- scss:rules --*/

// Layer on top of assets/theme.scss. Only what the seminar deck adds:
// animation stages, the "turn this knob" prompt, webR cards sized to run
// full-width on a projected slide, and the hero/sim chrome overrides.
// Every override for this deck lives here; theme.scss is shared history
// with the intro-r deck and is not edited.

// ---- Slide grid (spec §4) ----
// Title band 0–80: pull the accent bar up. Must out-rank theme.scss's
// `.reveal section > h2::after` (0,1,3), hence the full selector.
.reveal section.stage-slide > h2::after,
.reveal section.sim-slide > h2::after { margin-top: 0.4em; }

// ---- Animation stages ----
// Every stage is authored in a fixed 1000-wide pixel space (445 tall by
// default, 330 for the coverage stage) and shown at 105% so it spans the
// full 1050px slide width. Heights are on the wrapper so the absolute
// fragments and the takeaway line flow correctly.
.reveal section.stage-slide {
  display: block !important;
  text-align: left !important;
  overflow: hidden;
}
.stage-wrap {
  position: relative;
  margin: 8px auto 0;
  overflow: visible;
}
.stage-wrap-std { height: 468px; }   // 445 * 1.05
.stage-wrap-ci  { height: 347px; }   // 330 * 1.05 — leaves room for .claim-pair

.stage {
  position: relative;
  margin: 0 auto;
  display: block;
  width: 1000px;
  transform-origin: top center;
  transform: scale(1.05);
}
.stage svg { display: block; }

// Takeaway line under a stage: ink, 24px, two lines max.
.reveal section.stage-slide .slide-footer {
  font-size: 24px;
  color: var(--ink);
  max-width: 980px;
  margin-top: 0.45em;
}

// Invisible fragments used purely to gate animation steps.
.fi-frag {
  position: absolute;
  pointer-events: none;
  opacity: 0 !important;
}

// ---- "Turn this knob" prompt ----
// Orange (accent-3) rather than navy: navy is the deck's voice, orange is
// the student's turn to act. One per interactive slide, never more.
.try-this {
  margin: 0.35em 0 0.2em;
  padding: 8px 16px 8px 46px;
  background: rgba(244, 124, 60, 0.07);
  border: 1px solid rgba(244, 124, 60, 0.22);
  border-left: 4px solid var(--accent-3);
  border-radius: 0 6px 6px 0;
  font-size: 23px;
  line-height: 1.55;
  color: var(--ink);
  position: relative;
}
.try-this::before {
  content: "▶";
  position: absolute;
  left: 15px;
  top: 50%;
  transform: translateY(-50%);
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--accent-3);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.6em;
  line-height: 1;
  padding-left: 2px;
}
.try-this p { margin: 0; }
.try-this p + p { margin-top: 0.3em; }
.try-this strong { color: #C4551A; }
.try-this code {
  background: rgba(255, 255, 255, 0.7);
  color: #C4551A;
  font-weight: 600;
}

// ---- Sim slides: chrome sized for the room (spec §4.3, §7) ----
.reveal section.sim-slide {
  display: block !important;
  text-align: left !important;
}
.slide-kicker { font-size: 17px; }
.reveal section.sim-slide .slide-kicker { margin: 0.2em 0 0.4em; }
.reveal section.sim-slide .lede-min {
  font-size: 26px;
  margin: 0.25em 0 0.4em;
}

// ---- Full-width webR card ----
// Same surface treatment as the base theme's .type-card, wider, and the
// output pane is tall enough for a base-graphics plot.
.sim-card {
  padding: 14px 18px 12px;
  background: var(--bg-elev);
  border: 1px solid var(--rule);
  border-top: 3px solid var(--accent-1);
  border-radius: 8px;
  box-shadow: 0 1px 2px rgba(20, 28, 45, 0.03);
  margin: 0.25em 0 0.15em;
  min-width: 0;
}
// qwebr's real DOM (verified in the browser, not assumed):
//   .qwebr-interactive-area
//     .qwebr-editor-toolbar        <- the Run button
//     .qwebr-console-area          <- editor + text output, stacked
//     .qwebr-output-graph-area     <- SIBLING of the console, not a child
// So a plot has to be split off at the interactive-area level; text output
// is split off one level deeper. Hence two variants below.
//
// Font sizes: the extension reads the computed font-size of the editor div
// and of the output div and multiplies by editor-font-scale (1, set in
// _quarto.yml), so these px values ARE the Monaco font size and the printed
// output size. Line height for Monaco is set in assets/js/sim-tune.html.
.sim-card .qwebr-editor { font-size: 20px; }
.sim-card .qwebr-output-code-area { font-size: 22px; }

.sim-card .qwebr-output-code-area,
.sim-card .qwebr-output-graph-area {
  min-height: 70px;
  overflow: auto;
  background: var(--bg-soft);
  border: 1px dashed var(--rule);
  border-radius: 4px;
}
.sim-card .qwebr-output-code-area pre,
.sim-card pre.qwebr-output-code {
  line-height: 1.25;
}

// --- .sim-plot: code on the left, the figure on the right ---
// 1.45fr/1fr on the 998px inner grid gives a 590px code column: 49
// characters of 20px mono, so the 48-character source limit never wraps.
.sim-card.sim-plot .qwebr-interactive-area {
  display: grid;
  grid-template-columns: 1.45fr 1fr;
  grid-template-areas:
    "toolbar toolbar"
    "console graph";
  column-gap: 16px;
  align-items: start;
}
.sim-card.sim-plot .qwebr-editor-toolbar   { grid-area: toolbar; }
.sim-card.sim-plot .qwebr-console-area     { grid-area: console; min-width: 0; }
.sim-card.sim-plot .qwebr-output-graph-area { grid-area: graph; min-width: 0; }
.sim-card.sim-plot .qwebr-output-graph-area canvas,
.sim-card.sim-plot .qwebr-output-graph-area img,
.sim-card.sim-plot .qwebr-output-graph-area svg {
  max-width: 100%;
  height: auto;
}
// The console column carries the editor with the printed value beneath it.
.sim-card.sim-plot .qwebr-output-code-area { margin-top: 6px; min-height: 0; }

// --- .sim-text: code on the left, printed output on the right ---
// 1.5fr/1fr: 599px of code (49 chars), 399px of output (30 chars at 22px).
.sim-card.sim-text .qwebr-console-area {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 16px;
  align-items: start;
}
.sim-card.sim-text .qwebr-console-area > * { min-width: 0; }
.sim-card.sim-text .qwebr-output-graph-area { display: none; }

// The hidden setup cell (plot text hook, spec §6.2) renders a "Loading
// webR…" stub until the extension's hidden-cell pass runs. Never show it.
.qwebr-noninteractive-setup-area { display: none; }

// ---- Seminar marker on hero slides ----
// Mono numeral + rule, so the deck reads as an ordered sequence of nine.
.sem-mark {
  display: flex;
  align-items: baseline;
  gap: 14px;
  margin: 0 0 0.1em;
  color: var(--accent-1);
}
.sem-mark::before {
  content: attr(data-sem);
  font-family: "JetBrains Mono", monospace;
  font-size: 4.4em;
  font-weight: 700;
  line-height: 1;
  color: rgba(50, 93, 136, 0.18);
}
.sem-mark p {
  margin: 0;
  font-size: 0.42em;
  font-weight: 700;
  letter-spacing: 0.2em;
  text-transform: uppercase;
}
// Hero weight (spec §4.4): tagline up one step, lede in ink.
.reveal section.hero > p { font-size: 1.3em; }
.reveal section.hero .lede { color: var(--ink); }

// ---- Stepped formula, annotated back to the picture ----
// Each row is `expression | plain-English note`, so the algebra is read as a
// caption on the geometry rather than as a new object to memorise. The token
// colours match the Bayes grid exactly: navy = prior, orange = likelihood.
.formula-steps {
  margin: 0.5em 0 0.3em;
  font-family: "JetBrains Mono", monospace;
}
.formula-row {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 22px;
  align-items: baseline;
  padding: 9px 2px;
  border-bottom: 1px solid var(--rule-soft);
  font-size: 0.6em;
  line-height: 1.5;
  color: var(--ink);
}
.formula-row:last-child { border-bottom: none; }
.formula-row .fx-note {
  font-family: "Roboto", sans-serif;
  font-size: 0.88em;
  color: var(--ink-soft);
  line-height: 1.45;
}
.fx-prior { color: var(--accent-1); font-weight: 700; }
.fx-like  { color: var(--accent-3); font-weight: 700; }
.fx-post  { color: var(--accent-4); font-weight: 700; }

// ---- Two-up claim/answer for intuition slides ----
.claim-pair {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin: 0.5em 0 0.3em;
}
.claim-cell {
  padding: 14px 18px 12px;
  border-radius: 6px;
  background: var(--bg-elev);
  border: 1px solid var(--rule);
  font-size: 0.6em;
  line-height: 1.55;
}
.claim-cell.claim-wrong { border-left: 4px solid var(--accent-4); }
.claim-cell.claim-right { border-left: 4px solid var(--accent-2); }
.claim-cell > p:first-child { margin: 0 0 8px; line-height: 1; }
.claim-cell > p { margin: 0 0 6px; }
.claim-cell > p:last-child { margin-bottom: 0; }
.claim-tag {
  display: inline-block;
  padding: 2px 10px;
  font-size: 0.72em;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  border-radius: 3px;
}
.claim-wrong .claim-tag { background: rgba(185, 74, 72, 0.14); color: #8A3937; }
.claim-right .claim-tag { background: rgba(147, 197, 75, 0.18); color: #4E6B33; }
```

- [ ] **Step 2: Add `class="stage"` to the 18 stage divs and rename the wrap classes**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz/bman10750-slides"
sed -i '' -E 's/<div id="([a-z]+)-stage"><\/div>/<div id="\1-stage" class="stage"><\/div>/' sections/*.qmd
sed -i '' -E 's/\.stage-wrap-(400|bins|mm)/.stage-wrap-std/' sections/*.qmd   # no \b: BSD sed ignores it
grep -c 'class="stage"' sections/*.qmd | awk -F: '{s+=$2} END {print "stage divs:", s}'
grep -ho 'stage-wrap-[a-z0-9]*' sections/*.qmd | sort | uniq -c
```
Expected: `stage divs: 18`; wrap classes `17 stage-wrap-std` and `1 stage-wrap-ci`.

- [ ] **Step 3: Render, check, and look**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | tail -1
```
Expected: `All checks passed.` Then in the browser:
- `#/clt-intuition`: the stage is now 1050 wide and sits in a 468px band; the old 1000×400 drawing is shown at 105% with empty space at the bottom of the band (expected until Task 14); the takeaway is 24px ink.
- `#/s01-visualisation`: the ghosted numeral is about 160px tall; the tagline is larger; the lede is ink not grey.
- `#/ci-t-vs-z`: console `qwebrEditorInstances.filter(Boolean)[0].getOption(monaco.editor.EditorOption.fontSize)` → `20`. This slide overflows now (15 lines at 27px); Task 8 fixes it.
- `#/ci-intuition`: the coverage stage is clipped at the bottom of its 347px wrap (expected until Task 24).

- [ ] **Step 4: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/assets/seminars.scss bman10750-slides/sections
git commit -m "feat(deck): projection grid CSS, .stage class, sim/hero chrome sizes

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 5: Checks — `check-render.sh` and the browser probe

**Files:**
- Modify: `scripts/check-render.sh` (replace whole file)
- Create: `scripts/probe-overflow.js`

- [ ] **Step 1: Replace `scripts/check-render.sh`**

```bash
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
# Every stage div must carry the shared class (seminars.scss sizes .stage).
STAGE_DIVS=$( { grep -oE '<div id="[a-z]+-stage" class="stage">' "$OUT" || true; } | wc -l | tr -d ' ')
if [[ "$STAGE_DIVS" -eq 18 ]]; then echo "OK:   18 .stage divs"; else echo "FAIL: $STAGE_DIVS .stage divs (want 18)"; fail=1; fi
need "window.StageKit = " "StageKit included"
need "deck-sim-tune" "sim-tune included"

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
  /^## / { id=$0; sub(/.*#/,"",id); sub(/\}.*/,"",id); lede=0; plot=0 }
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
  inchunk { n++; if (length($0) > mx) mx = length($0) }
  END { exit bad ? 1 : 0 }
' sections/*.qmd) || fail=1
echo "$budget_out"

echo "───────────────────────────────────────────────────"
[[ "$fail" -eq 0 ]] && echo "All checks passed." || { echo "Checks FAILED."; exit 1; }
```

- [ ] **Step 2: Add the marker the check greps for to `assets/js/sim-tune.html`**

Change the first line of the comment block from `deck-sim-tune — Monaco editor options that CSS cannot reach.` to exactly `deck-sim-tune: Monaco editor options that CSS cannot reach.` (the string `deck-sim-tune` must appear in the render; it already does, this step is only to make sure nobody rewords it away — leave a note `// keep the token "deck-sim-tune": check-render.sh greps for it` on the line below the comment block).

- [ ] **Step 3: Create `scripts/probe-overflow.js`**

```js
// probe-overflow.js — paste into the browser console on the rendered deck.
// deckProbe.all()  : every leaf slide over 700px, every stage whose gating
//                    fragment count disagrees with StageKit.registry, every
//                    takeaway line running to three lines, and Monaco sizes.
// deckProbe.here() : the CURRENT slide only — smallest <text> in its stage
//                    (must be >= 18 canvas units) and, for a sim slide, the
//                    editor's wrapped-line count (must be 0).
// Stages are built on slide entry, so walk the deck and call here() on each.
window.deckProbe = (function () {
  function leaves() {
    return Array.prototype.filter.call(
      document.querySelectorAll('.reveal .slides section'),
      function (s) { return !s.querySelector('section'); });
  }
  function forced(s, fn) {
    var d = s.style.display, v = s.style.visibility;
    s.style.display = 'block'; s.style.visibility = 'hidden';
    var r = fn(); s.style.display = d; s.style.visibility = v; return r;
  }
  function all() {
    var H = Reveal.getConfig().height, out = { tall: [], frags: [], footers: [], editors: [] };
    leaves().forEach(function (s) {
      forced(s, function () {
        if (s.scrollHeight > H) out.tall.push(s.id + ' ' + s.scrollHeight + 'px');
        Array.prototype.forEach.call(s.querySelectorAll('.slide-footer'), function (f) {
          var lh = parseFloat(getComputedStyle(f).lineHeight) || 36;
          var lines = Math.round(f.offsetHeight / lh);
          if (lines > 2) out.footers.push(s.id + ' footer ' + lines + ' lines');
        });
      });
      var st = s.querySelector('.stage');
      if (st) {
        var reg = window.StageKit && StageKit.registry[st.id];
        var n = s.querySelectorAll('.fi-frag').length;
        if (!reg) out.frags.push(st.id + ' not registered with StageKit');
        else if (reg.frags.length !== n) out.frags.push(st.id + ' registry ' + reg.frags.length + ' vs slide ' + n);
      }
    });
    (window.qwebrEditorInstances || []).forEach(function (ed) {
      if (!ed || !ed.getOption) return;
      var O = monaco.editor.EditorOption;
      var fs = ed.getOption(O.fontSize), lh = ed.getOption(O.lineHeight);
      if (fs !== 20 || (lh !== 27 && lh !== 25)) out.editors.push('cell ' + ed.__qwebrCounter + ' font ' + fs + ' line ' + lh);
    });
    return out;
  }
  function here() {
    var s = Reveal.getCurrentSlide(), r = { slide: s.id };
    var svg = s.querySelector('.stage svg');
    if (svg) {
      var sizes = Array.prototype.map.call(svg.querySelectorAll('text'), function (t) {
        return parseFloat(t.getAttribute('font-size') || getComputedStyle(t).fontSize);
      });
      r.textNodes = sizes.length; r.minFont = Math.min.apply(null, sizes); r.maxFont = Math.max.apply(null, sizes);
    }
    var ed = (window.qwebrEditorInstances || []).filter(function (e) {
      return e && e.getDomNode && s.contains(e.getDomNode()); })[0];
    if (ed) {
      var vm = ed._getViewModel && ed._getViewModel();
      r.modelLines = ed.getModel().getLineCount();
      r.wrappedLines = vm ? vm.getLineCount() - r.modelLines : 'unknown';
    }
    return r;
  }
  return { all: all, here: here };
})();
```

- [ ] **Step 4: Render and run the checks**

```bash
chmod +x scripts/check-render.sh
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh
```
Expected: everything OK except `FAIL: plot-text setup cell missing` and budget FAILs for the ten cells that are over budget or over 48 characters today (bins, cheb, bayes, seller, memory, ci, ci-t-vs-z, alpha, pair, ovb; `clt` and `smooth` are over on lines, `cond`, `pois`, `ols`, `power` and the intro cell pass). Overall `Checks FAILED.` This is the expected red state; Tasks 6–8 turn it green. In the browser, paste the probe on any slide and run `deckProbe.all()`: `frags` lists every stage as "not registered" (until retuned) and `tall` lists the overflowing sim slides.

- [ ] **Step 5: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/scripts/check-render.sh bman10750-slides/scripts/probe-overflow.js bman10750-slides/assets/js/sim-tune.html
git commit -m "test(deck): cell budgets, kit presence and browser overflow probe

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 6: Plot text — setup cell and plot cell options

**Files:**
- Modify: `sections/00-how-to-use.qmd`
- Modify: `sections/01-visualisation.qmd`, `sections/04-distributions.qmd`, `sections/05-estimation.qmd` (the four plot cells' first lines)

- [ ] **Step 1: Insert the hidden setup cell on `#s00-webr`**

In `sections/00-how-to-use.qmd`, between the closing `:::` of the `.try-this` block and the `::: {.slide-footer}` line, insert:

````markdown
```{webr-r}
#| context: setup
setHook("before.plot.new", function() par(cex = 1.6, mar = c(3.6, 3.8, 1.6, 0.8), mgp = c(2.3, 0.8, 0)))
```

````

- [ ] **Step 2: Add figure options to the four plot cells**

In each of `bins-sim` (01), `seller-sim` and `clt-sim` (04), `ci-sim` (05), make the first two lines of the cell (immediately after ```` ```{webr-r} ````):
```
#| fig-width: 5.7
#| fig-height: 4.3
```
The extension builds a 410×310px canvas (inches × 72 dpi, 12pt text), the same width as the plot column, so it is shown 1:1.

- [ ] **Step 3: Render, check, and verify the hook fires**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | grep -E 'setup cell|webR cells'
```
Expected: `OK:   18 webR cells (matches 18 in sections/)` and `OK:   plot-text setup cell present`.

In the browser open `#/s00-webr`, wait for webR, replace the cell's code with `length(getHook("before.plot.new"))` and press Run. Expected output: `[1] 1`. Then open `#/clt-sim`, press Run Code, wait, and take a screenshot: the axis numbers and labels are visibly larger than in the baseline (roughly 19px on the slide; the "Frequency" label is about as tall as the printed `sd_obs` text). Zoom on the plot to confirm the margins still leave a usable plotting region. If the text is not larger, the hook did not fire: apply the §6.2 fallback (a first line `par(cex = 1.6)` in each of the four plot cells, and `PLOT_LINE_HEIGHT = 25` in `assets/js/sim-tune.html`) and note it in the commit message.

- [ ] **Step 4: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/sections bman10750-slides/assets/js/sim-tune.html
git commit -m "feat(deck): plot text sized for the room via a before.plot.new hook

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 7: Cell rewrites, seminars 1–4

**Files:**
- Modify: `sections/01-visualisation.qmd`, `sections/02-descriptives.qmd`, `sections/03-probability.qmd`, `sections/04-distributions.qmd`

Replace the code inside each named cell with exactly the text below (keep the two `#|` lines from Task 6 on plot cells above it). Nothing else on the slide changes unless stated. Every cell has been checked against its budget and the 48-character limit; do not reflow.

- [ ] **Step 1: `bins-sim` (plot, budget 12)**

```r
set.seed(7)
x <- round(rgamma(120, 2.2, 0.45) + 4, 1)
bw <- 1   # <-- bin width
brk <- seq(floor(min(x)),
           ceiling(max(x)) + bw, bw)
hist(x, breaks = brk, col = "#CBD9E6",
     border = "white", las = 1,
     main = paste("bin width =", bw),
     xlab = "R&D spend (% of revenue)")
```

- [ ] **Step 2: `cheb-sim` (lede, budget 10)**

```r
k <- 2        # <-- how many SDs
n <- 20000
# a wildly skewed population, far from normal
x  <- rexp(n, rate = 1)^2
mu <- mean(x); s <- sd(x)

actual <- mean(abs(x - mu) <= k * s)
bound  <- 1 - 1/k^2
round(c(actual = actual, chebyshev = bound), 3)
```

- [ ] **Step 3: `bayes-sim` (plain, budget 14)** — replaced again by the next project; this only brings it within limits.

```r
prior <- 0.05   # <-- P(librarian)
n <- 300000

lib  <- runif(n) < prior
# fits 40% of librarians, 10% of farmers
fits <- runif(n) < ifelse(lib, 0.40, 0.10)

round(c(prior     = prior,
        posterior = mean(lib[fits])), 4)
```

- [ ] **Step 4: `seller-sim` (plot, budget 12)**

```r
s <- seq(0.5, 1, length.out = 401)
L   <- function(k, n) dbinom(k, n, s)
rel <- function(k, n) L(k, n) / max(L(k, n))
plot(s, rel(10, 10), type = "l", lwd = 2,
     col = "#325D88", xlab = "true rate s",
     ylab = "relative likelihood")
lines(s, rel(48, 50), lwd = 2, col = "#93C54B")
lines(s, rel(186,200), lwd = 2, col = "#B94A48")
# flat prior: s ~ Beta(k + 1, n - k + 1)
good <- function(k,n) 1 - pbeta(.95, k+1, n-k+1)
round(c(A = good(10, 10), B = good(48, 50),
        C = good(186, 200)), 4)
```

- [ ] **Step 5: `memory-sim` (lede, budget 10)** — output names shortened so the printed header fits 30 characters (today's header is 34 wide). This is a deliberate deviation from spec §6.1's "prints exactly what it prints today": the values are unchanged, only the two names. Say so in the commit message.

```r
x <- rexp(500000, rate = 0.1)  # mean life 10y
s <- 10                        # <-- survived

fresh <- mean(x > 5)
used  <- mean(x > s + 5) / mean(x > s)

round(c(new_5_more  = fresh,
        used_5_more = used), 4)
```

- [ ] **Step 6: `clt-sim` (plot, budget 12)**

```r
n <- 5          # <-- draws per average
reps <- 4000
# a population with no bell shape at all
pop <- function(k) rexp(k, rate = 1)^2
sigma <- sd(pop(200000))
xbar <- replicate(reps, mean(pop(n)))
hist(xbar, breaks = 40, col = "#CBD9E6",
     border = "white", las = 1, main = "",
     xlab = paste("mean of", n, "draws"))
round(c(sd_obs  = sd(xbar),
        se_pred = sigma/sqrt(n)), 3)
```

- [ ] **Step 7: Render and check**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | grep -E 'bins-sim|cheb-sim|bayes-sim|cond-sim|seller-sim|memory-sim|pois-sim|clt-sim|s00-webr'
```
Expected: every listed cell `OK:` (`pois-sim`, `cond-sim` and `s00-webr` were already within budget). In the browser run `bins-sim`, `seller-sim`, `clt-sim` and `memory-sim` and confirm each prints or plots what it did before (bins histogram; three curves and A/B/C values 0.43/0.47/0.xx; CLT histogram with sd_obs/se_pred; memory values both about 0.607).

- [ ] **Step 8: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/sections
git commit -m "feat(deck): seminars 1-4 cells within the projection line budget

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 8: Cell rewrites, seminars 5–9

**Files:**
- Modify: `sections/05-estimation.qmd`, `sections/06-testing.qmd`, `sections/07-two-populations.qmd`, `sections/08-regression.qmd`, `sections/09-forecasting.qmd`

- [ ] **Step 1: `ci-sim` (plot, budget 12)**

```r
mu <- 100; sigma <- 15; reps <- 100  # the truth
n <- 25; conf <- 0.95                # <-- knobs
se   <- sigma / sqrt(n)
half <- qnorm(1 - (1 - conf)/2) * se
xbar <- replicate(reps, mean(rnorm(n,mu,sigma)))
hit  <- abs(xbar - mu) <= half
plot(NA, ylim=c(1,reps), xlim=mu+c(-4,4)*se,
     xlab = "interval", ylab = "sample")
abline(v = mu, lty = 2, lwd=2, col = "#325D88")
segments(xbar-half, 1:reps, xbar+half, 1:reps,
        col = ifelse(hit, "#9FB6CC", "#B94A48"))
mean(hit)
```

- [ ] **Step 2: `ci-t-vs-z` (plain, budget 14)**

```r
n <- 5            # <-- try 5, then 25, then 100
mu <- 100; sigma <- 15; reps <- 2000
# same sample sd; only the cut-off differs
z_rule <- function(x) qnorm(.975)*sd(x)/sqrt(n)
t_rule <- function(x) qt(.975,n-1)*sd(x)/sqrt(n)
cover <- function(rule) mean(replicate(reps, {
  x <- rnorm(n, mu, sigma)
  abs(mean(x) - mu) <= rule(x)
}))
round(c(used_z = cover(z_rule),
        used_t = cover(t_rule)), 3)
```

- [ ] **Step 3: `alpha-sim` (lede, budget 10)**

```r
alpha <- 0.05   # <-- your significance level
reps  <- 5000
n     <- 30
reject <- replicate(reps, {
  x <- rnorm(n, 100, 15)   # H0 is TRUE
  t <- (mean(x) - 100) / (sd(x)/sqrt(n))
  abs(t) > qt(1 - alpha/2, n - 1)
})
mean(reject)   # how often we cried wolf
```

- [ ] **Step 4: `power-sim` (claim pair above, budget 8)** — the removed comment moves into the kicker.

Cell:
```r
n <- 10   # <-- try 10, then 50, then 200
mean(replicate(4000, {
  x <- rnorm(n, mean = 105, sd = 15)
  t <- (mean(x) - 100) / (sd(x)/sqrt(n))
  abs(t) > qt(0.975, n - 1)
}))
```
Kicker on that slide becomes:
```markdown
::: {.slide-kicker}
Seminar 6 · the other error · H₀ false, true mean 105
:::
```

- [ ] **Step 5: `pair-sim` (plain, budget 14)** — prints a 2×2 matrix so the output fits 30 characters.

```r
before <- c(3, 15, 8, 19, 5, 12, 17, 7,
            14, 10, 6, 16, 9, 13, 11)
after  <- c(1, 13, 5, 17, 4, 9, 16, 4,
            12, 7, 5, 13, 7, 10, 9)
ind <- t.test(after, before, var.equal = TRUE)
par <- t.test(after, before, paired = TRUE)
row <- function(r) c(t = unname(r$statistic),
                     p = r$p.value)
round(rbind(independent = row(ind),
            paired      = row(par)), 4)
```

- [ ] **Step 6: `ovb-sim` (lede, budget 10)** — variables shortened; the printed header becomes `truth full omitted`.

```r
n <- 5000
school <- rnorm(n, 12, 3)
exper  <- 20 - 0.6*school + rnorm(n, 0, 3)
wage   <- 5 + 0.8*school + 0.3*exper + rnorm(n)
both <- coef(lm(wage ~ school + exper))
one  <- coef(lm(wage ~ exper))
round(c(truth = 0.3, full = both[["exper"]],
        omitted = one[["exper"]]), 3)
```

- [ ] **Step 7: `smooth-sim` (lede, budget 10)** — the "F2 is given" comment moves into the lede.

Cell:
```r
x <- c(45, 62, 73, 87, 86, 95)   # <-- trending
err <- function(a) {
  f <- 67
  for (k in 2:5) f[k] <- a*x[k] + (1-a)*f[k-1]
  x[2:6] - f[1:5] }
for (a in c(0.2, 0.4, 0.6, 0.8)) {
  e <- err(a)
  cat("a", a, " MSE", round(mean(e^2), 1),
      " MAE", round(mean(abs(e)), 2), "\n") }
```
Lede on that slide becomes:
```markdown
::: {.lede-min}
This series **trends upward**, which breaks the no-trend assumption smoothing requires. $F_2 = 67$ is given; the error metrics will tell you the rest.
:::
```

- [ ] **Step 8: Render, check, and run the changed cells**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | tail -14
```
Expected: every budget line `OK:` and `All checks passed.` In the browser run `ci-sim` (100 intervals, about 5 red), `ci-t-vs-z` (used_z about 0.87, used_t about 0.95 at n = 5), `power-sim` (about 0.16), `pair-sim` (matrix: independent t = -1.282, p = 0.2103; paired t = -11.000, p = 0.0000; the data is fixed so these are exact), `ovb-sim` (truth 0.3, full about 0.3, omitted clearly off), `smooth-sim` (four `a … MSE … MAE …` lines, each under 30 characters). Run `deckProbe.all()` (paste `scripts/probe-overflow.js` first): `tall` must be empty.

- [ ] **Step 9: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/sections
git commit -m "feat(deck): seminars 5-9 cells within the projection line budget

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 9: Retune `bins` on the kit (the worked example)

**Files:**
- Modify: `assets/js/bins-anim.html` (replace whole file)

This file is the template every later retune follows: same data, same states, same motion; the kit supplies palette, fonts, type roles and wiring; the canvas is 1000×445 and every text node uses a role.

- [ ] **Step 1: Replace the file**

```html
<script>
/*
  Binning animation — slide #bins-intuition.

  Teaching point: a histogram is not in the data, it is a CHOICE. The same
  30 numbers are shown three ways as the presenter advances fragments:
    0. loose on a number line  (what you actually have)
    1. stacked into bins of width 1
    2. re-stacked into bins of width 2  (the shape changes)

  Built on StageKit (assets/js/stage-kit.html): palette, type roles and the
  Reveal fragment wiring live there. Canvas 1000x445, shown at scale(1.05).
*/
(function () {
  var K = window.StageKit;

  var DATA = [6.1, 6.3, 6.4, 6.7, 6.9, 7.0, 7.1, 7.2, 7.4, 7.6,
              7.8, 7.9, 8.1, 8.3, 8.4, 8.6, 8.9, 9.2, 9.4, 9.7,
              10.1, 10.4, 10.9, 11.3, 11.8, 12.2, 12.7, 13.1, 13.8, 14.2];

  var W = 1000, H = 445, X0 = 60, VMIN = 5.5, VMAX = 15.5, SCALE = 88;
  var AXIS_Y = 412, STRIP_Y = 120, DOT_R = 8, GAP = 19, FLOOR = AXIS_Y - 16;

  function px(v) { return X0 + (v - VMIN) * SCALE; }

  // Where each dot sits for a given bin width. width === 0 means "loose".
  function layout(width) {
    if (!width) {
      return DATA.map(function (v) { return { x: px(v), y: STRIP_Y }; });
    }
    var counts = {};
    return DATA.map(function (v) {
      var b = Math.floor((v - 6) / width);          // bins start at 6
      var j = counts[b] || 0;
      counts[b] = j + 1;
      var centre = 6 + b * width + width / 2;
      return { x: px(centre), y: FLOOR - j * GAP };
    });
  }

  var CAPTIONS = {
    0: '30 numbers, no bins yet',
    1: 'bin width 1 — a long right tail',
    2: 'bin width 2 — the tail all but disappears'
  };

  function build(stage) {
    var svg = K.canvas(stage, W, H);

    svg.appendChild(K.el('line', {
      x1: X0, y1: AXIS_Y, x2: px(VMAX), y2: AXIS_Y,
      stroke: K.PAL.rule, 'stroke-width': 1
    }));
    for (var v = 6; v <= 15; v++) {
      svg.appendChild(K.el('line', {
        x1: px(v), y1: AXIS_Y, x2: px(v), y2: AXIS_Y + 6,
        stroke: K.PAL.dim, 'stroke-width': 1
      }));
      svg.appendChild(K.txt(px(v), AXIS_Y + 28, v,
        { size: 'tick', face: 'mono', anchor: 'middle' }));
    }

    var cap = K.txt(X0, 28, CAPTIONS[0], { size: 'caption', cls: 'bins-caption' });
    svg.appendChild(cap);

    var pts = layout(0);
    var dots = DATA.map(function (v, i) {
      return svg.appendChild(K.el('circle', {
        cx: pts[i].x, cy: pts[i].y, r: DOT_R,
        fill: K.PAL.navy, opacity: 0.5, class: 'bins-dot'
      }));
    });

    return { dots: dots, cap: cap };
  }

  function place(s, width, instant) {
    var pts = layout(width);
    s.cap.textContent = CAPTIONS[width];
    if (instant || K.REDUCE || !K.animeReady()) {
      s.dots.forEach(function (d, i) {
        d.setAttribute('cx', pts[i].x); d.setAttribute('cy', pts[i].y);
      });
      return;
    }
    window.anime.animate(s.dots, {
      cx: function (el, i) { return pts[i].x; },
      cy: function (el, i) { return pts[i].y; },
      duration: 620,
      delay: window.anime.stagger(14),
      ease: 'outCubic'
    });
  }

  K.register({
    stage: 'bins-stage',
    frags: ['bins-frag-w1', 'bins-frag-w2'],
    build: build,
    place: place
  });
})();
</script>
```

- [ ] **Step 2: Render, check, and walk the stage**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | tail -1
```
In the browser open `#/bins-intuition`; paste the probe; run `deckProbe.here()` → `minFont: 18` (ticks) and `maxFont: 24` (caption). Press Right twice and Left twice: dots stack, restack, and return; the caption changes each time. Reload the page on `#/bins-intuition` with both fragments shown (press Right twice, then reload): the stage opens already stacked at width 2 (snap on entry). The tallest stack (width 2) must not touch the caption; if it does, lower `GAP` to 18.

- [ ] **Step 3: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/assets/js/bins-anim.html
git commit -m "refactor(deck): bins stage on StageKit, 445 canvas, projection type

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

## The retune recipe (Tasks 10–23)

Each of the following tasks applies this recipe to one file. Read the file's header comment first; it states the teaching point and the states, none of which change.

**R1. Boilerplate → kit.** At the top of the IIFE add `var K = window.StageKit;`. Delete the local `REDUCE`, `NS`, `el` (and `txt` if it only wraps `el('text')`), `fragState`, `init`, `mount`, the `Reveal.on(...)` block, and the fragment-id map (`ORDER`/`STATES`; in `zstd` that is `ORDER` and `FRAGS`, while `zstd`'s `STATES` is frame data and stays). Replace with one call at the end:
```js
K.register({ stage: '<name>-stage', frags: [ ...the ids in order... ], build: build, place: <place or render>, stop: <stop if the file has one> });
```
Every use of `REDUCE` becomes `K.REDUCE`; every `el(` becomes `K.el(`; `typeof window.anime === 'undefined' || !window.anime.animate` becomes `!K.animeReady()`. `build` must start with `var svg = K.canvas(stage, W, H);` instead of clearing the stage and creating the svg by hand.

Note: the kit calls `place(handle, state, true)` on mount for **every** state, including 0, whereas six files today only snap when the state is non-zero (`bins`, `mm`, `clt`, `cond`, `expo`, `smooth`). Their state-0 snap is idempotent with `build` (every `place` must handle 0 anyway, because hiding the first fragment reaches it), so this is harmless. Do not add a guard.

**R2. Colours and fonts.** Replace every hex literal with the `K.PAL` name from this table and every font string with `K.FONT.mono` / `K.FONT.sans`. Files that define local colour variables keep the variable names and point them at the kit (`var NAVY = K.PAL.navy;`), so the drawing code's diff stays small.

| hex | name | hex | name |
|---|---|---|---|
| `#325D88` | `navy` | `#3E3F3A` | `ink` |
| `#93C54B` | `olive` | `#6E7681` | `inkSoft` |
| `#F47C3C` | `orange` | `#B0B7C0` | `dim` |
| `#B94A48` | `brick` | `#E5E7EB` | `rule` |
| `#FFFFFF` | `white` | | |

**R3. Type roles.** Replace every `'font-size': N` (or size argument to a local text helper) by role, never by nearest number: axis numbers and tick labels → `K.TYPE.tick` (18); panel titles, small annotations, legends, footnote lines → `K.TYPE.label` (20); the state caption at the top left (the node with class `*-caption`, drawn at about (40, 34)) → `K.TYPE.caption` (24) and move it to y = 28; the one headline number or formula (bold, mono) → `K.TYPE.readout` (30). Nothing stays below 18.

**R4. Height.** Set `H = 445`. Multiply every vertical constant and every literal `y`, `y1`, `y2`, `cy` in `build`/`place` by **1.1125** (445/400) and round, except the caption (y = 28) and any text baseline that must stay above 440. Heights of bars/panels (`HMAX`, `SQ_H`, `PY` density scale, `UNIT` plot scale) scale by the same factor so the drawing uses the new height. Horizontal constants do not change.

**R5. Collisions.** Larger labels can collide with neighbours. Fix by moving elements or splitting a caption onto its own line; never by shrinking text. Captions are limited to about 40 characters at 24 units when a readout shares the top band; if a caption is longer, put the readout at the right edge (`anchor: 'end'` at x = 960) or drop the caption to a second line.

**R6. Verify (every file).**
```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | tail -1
```
Browser: open the slide, paste the probe, `deckProbe.here()` → `minFont >= 18`; walk every fragment forward and back; reload with all fragments shown to confirm the snap-on-entry; screenshot the final state and look for overlaps and for anything clipped at the bottom of the 468px band. Console must show no errors.

**R7. Commit** with `refactor(deck): <name> stage on StageKit, 445 canvas, projection type` and the two trailers.

Per-file notes follow. Line numbers are as of the baseline commit.

---

### Task 10: Retune `mm`

**Files:** `assets/js/mm-anim.html` (227 lines; H is 380 today)

- [ ] **Step 1:** Apply R1–R3. Fonts today: 15×3, 17×1. Place: `place(s, state, instant)`. No stop.
- [ ] **Step 2:** R4 with factor **1.171** (445/380): `AXIS_Y 300→351`, `ROW_Y 210→246`, `MEAN_TOP 306→358`, `MEDIAN_TOP 340→398`, `LAB_DROP 27→32`, `DOT_R 9→10`. Check the mean/median labels (`MEDIAN_TOP + LAB_DROP` = 430) stay above 440.
- [ ] **Step 3:** R6, on `#/mm-intuition` (two fragments). R7.

### Task 11: Retune `binom`

**Files:** `assets/js/binom-anim.html` (375 lines)

- [ ] **Step 1:** R1–R3. Fonts: 15×4, 17×2, 20×1 (the count readout). Eight inline hex values, no colour variables. Has `stop(s)` (setTimeout replay chain): pass it to `register`. Place: `place(s, state, instant)`.
- [ ] **Step 2:** R4: `BASE 330→367`; matrix block `MY 156→174`, `MSIDE 18→20`, `MPITCH 34→38`; scale other literal y's.
- [ ] **Step 3:** R6 on `#/binom-intuition` (three fragments); also leave the slide mid-replay and come back: the replay must not continue on the old handle. R7.

### Task 12: Retune `cieq`

**Files:** `assets/js/cieq-anim.html` (283 lines)

- [ ] **Step 1:** R1–R3. Fonts: 17 (caption), 19 (notes → label), 24 (an opacity-0 text at line 188 → label), plus a `'font-size': FS` reference with `FS = 30` for the formula grid (already the readout size; route it through `K.TYPE.readout`). Colour variables INK/SOFT/RULE/NAVY/OLIVE/ORANGE/BRICK → kit. Place: `place(s, st, instant)`.
- [ ] **Step 2:** R4: `Y_ABOVE 138→154`, `Y_BELOW 205→228`; scale other literal y's. The formula at 30 mono is 18 units per character; confirm it still fits between x = 40 and 960.
- [ ] **Step 3:** R6 on `#/cieq-formula` (four fragments). R7.

### Task 13: Retune `ciflip`

**Files:** `assets/js/ciflip-anim.html` (441 lines)

- [ ] **Step 1:** R1–R3. Fonts: 15×5, 17×2, plus a `'font-size': FS` reference (`FS = 15`, the mean label at line 149 → label). Colour variables → kit. The state function is `render(s, st, instant)`: pass `place: render`.
- [ ] **Step 2:** R4: `BASE 210→234`, `PEAK_Y 78→87`; scale other literal y's.
- [ ] **Step 3:** R6 on `#/ciflip-intuition` (three fragments). R7.

### Task 14: Retune `clt`

**Files:** `assets/js/clt-anim.html` (390 lines)

- [ ] **Step 1:** R1–R3. Fonts: 15×6 (axis numbers → tick; panel titles and the two foot lines → label), 17 (caption), 22 (`n = …` → readout). Inline hex → kit. Place: `place(s, i, instant)`.
- [ ] **Step 2:** R4: `BASE 320→356`, `HMAX 190→211`, `AXIS_Y 345→384`, `FOOT_Y 374→416`; the divider line `y1 60→67, y2 350→389`; panel titles `y 104→116`; the `n =` readout `y 78→87`; the mean markers `y1 134→149`.
- [ ] **Step 3:** R5: the captions are up to 46 characters; at 24 units they run under the orange readout that starts at x = 560. Move the readout to the right edge: `x: 950, 'text-anchor': 'end'`, and keep the caption at (40, 28).
- [ ] **Step 4:** R6 on `#/clt-intuition` (three fragments). R7.

### Task 15: Retune `cond`

**Files:** `assets/js/cond-anim.html` (323 lines)

- [ ] **Step 1:** R1–R3. Fonts: 15 (→ label), 17×2 (caption + label), 20×2 (→ readout for the `32/34 = 94%` line, label for the other). Colour variables → kit. State function `render(s, st, instant)` → `place: render`.
- [ ] **Step 2:** R4: `SQ_Y 70→78`, `SQ_H 270→300` (the derived `BUY_UP_H`/`NB_UP_H` follow); scale other literal y's.
- [ ] **Step 3:** R6 on `#/cond-intuition` (three fragments). R7. (The next project changes only this file's captions; do not reword them here.)

### Task 16: Retune `expo`

**Files:** `assets/js/expo-anim.html` (456 lines)

- [ ] **Step 1:** R1–R3. This file has no literal `font-size` attributes: text goes through `label(x, y, s, size, fill, family, anchor)` (line 209). Map the `size` argument at every call site by role, and the `fill`/`family` arguments to `K.PAL`/`K.FONT`. Inline hex elsewhere → kit. Keeps its `op()` helper. Place: `place(s, state, instant)`.
- [ ] **Step 2:** R4: `AXIS_Y 110→122`, `TICK_H 22→24`, `BRACK_Y 152→169`, `BASE 340→378`, `HMAX 170→189`, `TITLE_Y 186→207`.
- [ ] **Step 3:** R6 on `#/expo-intuition` (three fragments); state 3 (the re-normalised gaps landing on the curve) must still land exactly on the brick curve. R7.

### Task 17: Retune `ls`

**Files:** `assets/js/ls-anim.html` (268 lines)

- [ ] **Step 1:** R1–R3. Fonts: 13, 14×2, 15×2 (→ tick/label by role), 17 (caption), 30 (already the readout). Inline hex → kit. Place: `place(s, state, instant)`.
- [ ] **Step 2:** R4: `UNIT 34→38` (data-to-px scale, so the squares grow), `Y0 366→407`; scale the four literal y's.
- [ ] **Step 3:** R6 on `#/ls-intuition` (two fragments); the squares must stay inside the band at the far-off point. R7.

### Task 18: Retune `pair`

**Files:** `assets/js/pair-anim.html` (281 lines)

- [ ] **Step 1:** R1–R3. Fonts: 14×2, 15×2, 17. Colour variables (INK_SOFT, RULE, GREY, NAVY, OLIVE, ORANGE, BRICK) → kit. Place: `place(s, state, instant)`.
- [ ] **Step 2:** R4: `TOP 60→67`, `BOT 340→378`, `DOT_R 8→9`; scale the three literal y's.
- [ ] **Step 3:** R6 on `#/pair-intuition` (two fragments). R7.

### Task 19: Retune `pois`

**Files:** `assets/js/pois-anim.html` (220 lines)

- [ ] **Step 1:** R1–R3. Fonts: 15×2, 16, 17. Inline hex → kit. Place: `place(s, state, instant)`.
- [ ] **Step 2:** R4: `BASE 330→367`, `HMAX 250→278`; scale the four literal y's.
- [ ] **Step 3:** R6 on `#/pois-intuition` (three fragments). R7.

### Task 20: Retune `pval`

**Files:** `assets/js/pval-anim.html` (288 lines)

- [ ] **Step 1:** R1–R3. Fonts: 14, 15, 17×2, 18 (the p-value readout → readout). NAVY/BRICK variables → kit, other hex inline → kit. Place: `place(s, n, instant)`.
- [ ] **Step 2:** R4: `BASE 320→356`, `TOP 60→67`; scale the three literal y's.
- [ ] **Step 3:** R6 on `#/pval-intuition` (three fragments). R7.

### Task 21: Retune `seller`

**Files:** `assets/js/seller-anim.html` (373 lines)

- [ ] **Step 1:** R1–R3. Fonts: 13, 14×5, 17×2. SOFT/RULE/GREY variables → kit; other hex inline → kit. Has `stop(s)` (pauses tweens in `s.anims`): pass to `register`. State function `render(s, st, instant)` → `place: render`.
- [ ] **Step 2:** R4: `BASE 280→312`, `PEAK_Y 80→89`; scale other literal y's. The right-hand panel (x ≥ 700) holds the seller table: check its rows still fit at 20 units.
- [ ] **Step 3:** R6 on `#/seller-intuition` (three fragments), including leaving mid-tween and returning. R7.

### Task 22: Retune `smooth`

**Files:** `assets/js/smooth-anim.html` (272 lines)

- [ ] **Step 1:** R1–R3. Fonts: 12, 13, 15×2, 17, 22 (→ readout). Inline hex → kit. Place: `place(s, i, instant)`.
- [ ] **Step 2:** R4: `BASE_Y 320→356`, `TOP_V 50→56`, `AXIS_Y 336→374`; scale other literal y's. The right panel (weight profile, x 690–950) has its own y's; scale them too.
- [ ] **Step 3:** R6 on `#/smooth-intuition` (two fragments). R7.

### Task 23: Retune `zstd`

**Files:** `assets/js/zstd-anim.html` (344 lines)

- [ ] **Step 1:** R1–R3. Fonts: 14×3, 15, 17×2, 26 (the shaded-area value → readout). Inline hex → kit. Delete `ORDER` (line 302) and `FRAGS` (303); keep `STATES` (line 49, frame data). The state-moving function is `place(s, i, instant)` (line 264); `render(s, f)` is internal and stays.
- [ ] **Step 2:** R4: `BASE 330→367`, `PY 640→712`; scale the seven literal y's.
- [ ] **Step 3:** R6 on `#/zstd-intuition` (two fragments); the peak of the standardised curve must stay below the caption. R7.

---

### Task 24: Re-lay out `ci` to 1000×330

**Files:**
- Modify: `assets/js/ci-anim.html` (replace whole file)

The slide keeps the `.claim-pair` under the stage, so this stage gets 330 units of height, not 445. Twenty intervals at a 12-unit step fit between y = 62 and y = 290; the axis sits at 300 with tick labels at 324; the μ label and the counter share the top band.

- [ ] **Step 1: Replace the file**

```html
<script>
/*
  CI coverage animation — slide #ci-intuition.

  Teaching point: mu is a fixed vertical line; the INTERVALS are what move.
  Twenty 95% intervals rain in from a mu = 100, sigma = 15, n = 25 world
  (so SE = 3 and the half-width is 1.96 * 3 = 5.88). Exactly one of the
  twenty misses, which is what 95% coverage looks like at this sample size.

  Sample means are hardcoded rather than drawn live so the picture is the
  same in every run of the lecture — the live version is the webR slide
  that follows.

  Built on StageKit. Canvas 1000x330 (the .claim-pair sits beneath it),
  shown at scale(1.05). No fragments: the rain plays on slide entry.
*/
(function () {
  var K = window.StageKit;

  var MU = 100, HALF = 5.88;
  var MEANS = [101.2, 98.4, 103.1, 99.6, 96.9, 100.8, 104.2, 97.5, 102.3, 94.0,
               100.1, 105.4, 98.9, 101.7, 97.1, 103.6, 99.2, 100.5, 96.3, 102.8];

  var W = 1000, H = 330, X0 = 50, X1 = 950, VMIN = 88, VMAX = 112;
  // Top band 0-50 holds the mu label (two lines) and the counter; the rows
  // run 62..290 at a 12-unit step (row 20 = 62 + 19*12 = 290), ten units
  // clear of the axis at 300; tick labels sit at 324, inside the 330 canvas.
  var AXIS_Y = 300, MU_TOP = 54, ROW_TOP = 62, ROW_STEP = 12;

  function px(v) { return X0 + (v - VMIN) * (X1 - X0) / (VMAX - VMIN); }

  function build(stage) {
    var svg = K.canvas(stage, W, H);

    // --- axis ---
    svg.appendChild(K.el('line', {
      x1: X0, y1: AXIS_Y, x2: X1, y2: AXIS_Y, stroke: K.PAL.rule, 'stroke-width': 1
    }));
    [90, 95, 100, 105, 110].forEach(function (v) {
      svg.appendChild(K.el('line', {
        x1: px(v), y1: AXIS_Y, x2: px(v), y2: AXIS_Y + 6,
        stroke: K.PAL.dim, 'stroke-width': 1
      }));
      svg.appendChild(K.txt(px(v), AXIS_Y + 24, v,
        { size: 'tick', face: 'mono', anchor: 'middle' }));
    });

    // --- mu line: the thing that does NOT move ---
    var muLine = K.el('line', {
      x1: px(MU), y1: MU_TOP, x2: px(MU), y2: AXIS_Y,
      stroke: K.PAL.navy, 'stroke-width': 2, 'stroke-dasharray': '6 5',
      class: 'ci-mu', opacity: 0
    });
    svg.appendChild(muLine);

    var muLab = K.txt(px(MU), 24, 'μ = 100',
      { size: 'label', face: 'mono', fill: 'navy', weight: 700, anchor: 'middle', cls: 'ci-mu-lab' });
    muLab.setAttribute('opacity', 0);
    svg.appendChild(muLab);

    var muSub = K.txt(px(MU), 46, 'unknown, but fixed',
      { size: 'tick', anchor: 'middle', cls: 'ci-mu-lab' });
    muSub.setAttribute('opacity', 0);
    svg.appendChild(muSub);

    // --- intervals ---
    var hits = 0;
    MEANS.forEach(function (m, i) {
      var covers = (m - HALF) <= MU && MU <= (m + HALF);
      if (covers) hits++;
      var y = ROW_TOP + i * ROW_STEP;
      var colour = covers ? K.PAL.navy : K.PAL.brick;

      var g = K.el('g', { class: 'ci-int', opacity: 0 });
      g.style.transformBox = 'fill-box';
      g.style.transformOrigin = 'center';
      g.appendChild(K.el('line', {
        x1: px(m - HALF), y1: y, x2: px(m + HALF), y2: y,
        stroke: colour, 'stroke-width': covers ? 2.6 : 3.4,
        'stroke-linecap': 'round', opacity: covers ? 0.55 : 1
      }));
      g.appendChild(K.el('circle', {
        cx: px(m), cy: y, r: covers ? 3 : 3.8,
        fill: colour, opacity: covers ? 0.75 : 1
      }));
      svg.appendChild(g);
    });

    // --- running counter ---
    var cnt = K.txt(X1, 30, '0 / 20 cover μ',
      { size: 'readout', face: 'mono', fill: 'ink', weight: 700, anchor: 'end', cls: 'ci-count' });
    cnt.setAttribute('opacity', 0);
    svg.appendChild(cnt);

    var s = { muParts: svg.querySelectorAll('.ci-mu, .ci-mu-lab'),
              ints: svg.querySelectorAll('.ci-int'), cnt: cnt, hits: hits };
    run(s);
    return s;
  }

  function show(nodes) {
    Array.prototype.forEach.call(nodes, function (n) { n.setAttribute('opacity', 1); });
  }

  function run(s) {
    if (K.REDUCE || !K.animeReady()) {
      show(s.muParts); show(s.ints);
      s.cnt.setAttribute('opacity', 1);
      s.cnt.textContent = s.hits + ' / 20 cover μ';
      return;
    }

    var A = window.anime;
    A.animate(s.muParts, { opacity: [0, 1], duration: 420, ease: 'outQuad' });

    // Intervals grow out from their own centre, one after another.
    Array.prototype.forEach.call(s.ints, function (g) {
      g.style.transform = 'scaleX(0)';
    });
    A.animate(s.ints, {
      opacity: [0, 1],
      scaleX: [0, 1],
      duration: 340,
      delay: A.stagger(85, { start: 320 }),
      ease: 'outQuad'
    });

    // Counter ticks up in step with the intervals landing.
    var c = { v: 0 };
    s.cnt.setAttribute('opacity', 1);
    A.animate(c, {
      v: s.hits,
      duration: 85 * s.ints.length,
      delay: 420,
      ease: 'linear',
      onUpdate: function () {
        s.cnt.textContent = Math.round(c.v) + ' / 20 cover μ';
      }
    });
  }

  K.register({ stage: 'ci-stage', frags: [], build: build });
})();
</script>
```

- [ ] **Step 2: Render, check, look**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh | tail -1
```
Browser `#/ci-intuition`: the rain plays on entry; the counter reads `19 / 20 cover μ`; the last row (y = 290) sits clear of the axis; the tick labels (y 324) are inside the 347px wrap; the claim pair beneath is fully visible and the slide is not in `deckProbe.all().tall`. `deckProbe.here()` → `minFont: 18`. The μ label must not collide with the counter: they are at x = px(100) = 500 and x = 950, so they do not.

- [ ] **Step 3: Commit**

```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/assets/js/ci-anim.html
git commit -m "refactor(deck): coverage stage re-laid out to 1000x330 on StageKit

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
```

---

### Task 25: Final verification pass and spec status

**Files:**
- Modify: `sections/*.qmd` only if a takeaway needs shortening
- Modify: `docs/superpowers/specs/2026-09-05-projection-presence-design.md` (status line)

- [ ] **Step 1: Full static check**

```bash
quarto render 2>&1 | tail -1 && bash scripts/check-render.sh
```
Expected: `All checks passed.`

- [ ] **Step 2: Probe**

Browser, any slide, paste `scripts/probe-overflow.js`, run `deckProbe.all()`. Expected: `tall: []`, `footers: []`, `editors: []`, and `frags` containing only `bayes-stage not registered with StageKit` and `bayeq-stage not registered with StageKit` (the two files the next project replaces). If `footers` lists a slide, shorten that takeaway in its qmd without changing its claim, re-render, re-run.

- [ ] **Step 3: Stage walk**

For each of the 16 retuned stages plus `ci`: open the slide, `deckProbe.here()` → `minFont >= 18`; step every fragment forward and back. Record any collision found and fix it in that stage's file (R5), commit as `fix(deck): <name> stage layout`.

- [ ] **Step 4: Cell run**

Run all 17 visible cells once; none may print a line wider than 30 characters in a `.sim-text` card (measure by eye against the column: no horizontal scrollbar appears in the output pane). `deckProbe.here()` on each sim slide → `wrappedLines: 0`.

- [ ] **Step 5: Viewport screenshots**

Resize the window to 1024×768, 1280×720 and 1920×1080 in turn and screenshot `#/s04-distributions`, `#/clt-intuition` (final fragment), `#/ci-t-vs-z` (after Run) and `#/clt-sim` (after Run). Save them to the scratchpad directory named `<size>-<slide>.png`. Nothing may be clipped or overlapping at any size.

- [ ] **Step 6: Spec status and final commit**

Change the spec's status line to `**Status:** implemented 2026-09-XX (plan 2026-09-06-projection-presence.md)` with today's date, then:
```bash
cd "/Users/gabbocg/Dropbox (Personal)/Documentos/Brainstorming/quantviz"
git add bman10750-slides/docs/superpowers/specs/2026-09-05-projection-presence-design.md bman10750-slides/sections
git commit -m "docs(deck): presence project implemented; verification pass recorded

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014GtmXtXJWTbQRMLyEWRH3L"
pkill -f "http.server 8765" || true
```

Report: the four screenshot sets, the probe output, and any R5 fixes made, in the final message.
