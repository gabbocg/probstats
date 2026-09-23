#!/usr/bin/env bash
# publish.sh — render, check, and push _site/ to the gh-pages branch.
#
# NOT `quarto publish gh-pages`. That command ships the rendered HTML plus the
# resources it can DISCOVER from <script src> and <link href>, and ignores the
# `resources:` tree in _quarto.yml. On this deck that dropped 105 of the 107
# files under assets/vendor/ — including Monaco's 3.5MB editor.main.js — so
# every webR cell rendered as an empty box on the deployed site while working
# perfectly under `quarto preview`. Pushing _site/ verbatim cannot drift.
set -euo pipefail
cd "$(dirname "$0")/.."

quarto render
bash scripts/check-render.sh

WT=".gh-pages"
git worktree remove --force "$WT" 2>/dev/null || true
rm -rf "$WT"
git fetch -q origin gh-pages
git worktree add -q -f "$WT" gh-pages
rsync -a --delete --exclude .git _site/ "$WT"/
touch "$WT/.nojekyll"        # or GitHub's Jekyll pass eats every _-prefixed dir

cd "$WT"
git add -Af .
if git diff --cached --quiet; then
  echo "nothing to publish"
else
  git commit -q -m "Publish $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  git push -q origin HEAD:gh-pages
  echo "published $(git ls-files | wc -l | tr -d ' ') files"
fi
cd ..
git worktree remove --force "$WT"
