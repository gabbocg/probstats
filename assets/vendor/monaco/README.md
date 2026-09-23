# Vendored Monaco Editor 0.47.0

quarto-webr loads Monaco from `cdn.jsdelivr.net` at runtime
(`_extensions/coatless/webr/qwebr-monaco-editor-init.html`). On a slow or
absent network the loader never resolves, `window.monaco` stays undefined,
and NO editors are created — every `{webr-r}` cell renders as an empty box
with no code in it, while the rest of the deck looks fine because everything
else is local. That is not a risk worth carrying into a lecture theatre.

So the bundle is vendored here and the extension's two CDN URLs are pointed
at it. `assets/vendor/` is already in `_quarto.yml`'s `resources`, so it is
copied into `_site` on render.

Trimmed: `vs/language/` (5.8MB of CSS, HTML, JSON and TypeScript language
services) is deleted — this deck only ever sets the editor language to `r`,
and those services load lazily for their own languages only. `vs/basic-languages/`
is kept whole; it is only 636K and it contains `r`.

If `quarto update` ever restores the extension, the CDN URLs come back.
`scripts/check-render.sh` asserts the rendered page has no jsdelivr Monaco
reference, so that regression fails the checks rather than the lecture.

To refresh: download `monaco-editor-<version>.tgz` from the npm registry,
extract `package/min/vs` here, delete `vs/language/`, and update the two URLs
in the extension file.
