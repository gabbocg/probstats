#!/usr/bin/env node
// check-anims.js — load every assets/js/*-anim.html in isolation and make sure
// it survives to the end.
//
// Guards a failure mode that is invisible to every other check here and to
// `quarto render`: a stage file that THROWS while loading. The JS is in the
// page, so the include check passes; the <div> is in the .qmd, so the stage
// check passes; the render reports success. But the exception kills the
// module before K.register() runs, StageKit never hears about the stage, and
// the slide simply draws nothing in the lecture.
//
// It has happened twice. Both times it was ordering: a `var` initialised from
// another `var` declared further down the file, which hoists to undefined.
//
// Stubs are deliberately dumb — this asks "does the module load and register",
// not "does it draw correctly".
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'assets', 'js');
const files = fs.readdirSync(dir).filter(f => /-anim\.html$/.test(f)).sort();

const nodeStub = () => ({
  setAttribute() {}, getAttribute() { return null; },
  appendChild(c) { return c; }, querySelector() { return nodeStub(); },
  querySelectorAll() { return []; }, getBBox() { return {x:0,y:0,width:0,height:0}; },
  style: {}, textContent: '', classList: { contains: () => false }
});

let failed = 0;
for (const f of files) {
  const src = fs.readFileSync(path.join(dir, f), 'utf8').replace(/<\/?script>/g, '');
  let registered = null;
  const K = {
    PAL: new Proxy({}, { get: () => '#000000' }),
    FONT: { mono: 'm', sans: 's' },
    TYPE: { tick: 18, label: 20, caption: 24, readout: 30 },
    REDUCE: false, MARK: { PER: 50, GP: 19, TICK: 'T', CROSS: 'C' },
    el: nodeStub, txt: nodeStub, canvas: nodeStub, mark: nodeStub,
    missSet: (n, m) => { const s = {}; for (let i = 0; i < m; i++) s[i] = 1; return s; },
    block: (p, c) => Array.from({ length: c }, nodeStub),
    animeReady: () => false,
    register: (spec) => { registered = spec && spec.stage; },
    registry: {}
  };
  global.window = {
    StageKit: K, anime: { animate: () => ({ pause() {} }), stagger: () => 0 },
    performance: { now: () => 0 },
    matchMedia: () => ({ matches: false }),
    addEventListener() {}, setTimeout() {}
  };
  global.document = {
    hidden: false, addEventListener() {}, querySelector: nodeStub,
    querySelectorAll: () => [], createElementNS: nodeStub
  };
  try {
    new Function(src)();
    if (registered) console.log(`OK:   ${f} -> registered ${registered}`);
    else console.log(`OK:   ${f} -> loads (self-wired, no K.register)`);
  } catch (e) {
    console.log(`FAIL: ${f} threw while loading: ${e.message}`);
    failed = 1;
  }
}
process.exit(failed);
