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
