// probe-overflow.js — paste into the browser console on the rendered deck.
// deckProbe.all()  : every stage-or-hero slide over 700px (sim slides are
//                    skipped and listed), every stage whose gating fragment
//                    count disagrees with StageKit.registry, every takeaway
//                    running to three lines, and Monaco sizes.
// deckProbe.here() : the CURRENT slide only — its height vs 700, smallest
//                    <text> in its stage (must be >= 18 canvas units) and,
//                    for a sim slide, the editor's wrapped-line count (0).
// Sim slides only measure correctly while shown, so walk the deck and call
// here() on each.
window.deckProbe = (function () {
  function leaves() {
    return Array.prototype.filter.call(
      document.querySelectorAll('.reveal .slides section'),
      function (s) { return !s.querySelector('section'); });
  }
  // Reveal keeps vertical stacks beyond `viewDistance` at display:none, so a
  // leaf forced visible inside a hidden stack still measures 0: force the
  // stack too, and restore both afterwards.
  function forced(s, fn) {
    var p = s.parentElement;
    var els = (p && p.classList.contains('stack')) ? [s, p] : [s];
    var saved = els.map(function (el) { return [el, el.style.display, el.style.visibility]; });
    els.forEach(function (el) { el.style.display = 'block'; el.style.visibility = 'hidden'; });
    try { return fn(); }
    finally { saved.forEach(function (x) { x[0].style.display = x[1]; x[0].style.visibility = x[2]; }); }
  }
  function all() {
    var H = Reveal.getConfig().height, out = { tall: [], frags: [], footers: [], editors: [], skipped: [] };
    leaves().forEach(function (s) {
      // Monaco lays out to its container width, which is 0 while the slide
      // is hidden, so a forced sim slide reports a nonsense height: measure
      // those with here() when the slide is shown.
      if (s.querySelector('.qwebr-editor')) {
        out.skipped.push(s.id);
      } else {
        forced(s, function () {
          if (s.scrollHeight > H) out.tall.push(s.id + ' ' + s.scrollHeight + 'px');
          Array.prototype.forEach.call(s.querySelectorAll('.slide-footer'), function (f) {
            var lh = parseFloat(getComputedStyle(f).lineHeight) || 36;
            var lines = Math.round(f.offsetHeight / lh);
            if (lines > 2) out.footers.push(s.id + ' footer ' + lines + ' lines');
          });
        });
      }
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
    r.height = s.scrollHeight; r.over = s.scrollHeight > Reveal.getConfig().height;
    var svg = s.querySelector('.stage svg');
    if (svg) {
      var sizes = Array.prototype.map.call(svg.querySelectorAll('text'), function (t) {
        return parseFloat(t.getAttribute('font-size') || getComputedStyle(t).fontSize);
      });
      r.textNodes = sizes.length;
      r.minFont = sizes.length ? Math.min.apply(null, sizes) : null;
      r.maxFont = sizes.length ? Math.max.apply(null, sizes) : null;
    }
    var ed = (window.qwebrEditorInstances || []).filter(function (e) {
      return e && e.getDomNode && s.contains(e.getDomNode()); })[0];
    if (ed) {
      // _getViewModel is a private Monaco API; fine for a console diagnostic, not a contract.
      var vm = ed._getViewModel && ed._getViewModel();
      r.modelLines = ed.getModel().getLineCount();
      r.wrappedLines = vm ? vm.getLineCount() - r.modelLines : 'unknown';
    }
    return r;
  }
  return { all: all, here: here };
})();
