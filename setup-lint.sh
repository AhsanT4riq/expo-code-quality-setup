#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --------------------------------------------
# Usage:
#   curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh \
#        | bash -s [npm|yarn|pnpm|bun]
# --------------------------------------------

pm="${1:-npm}"
pm=$(printf '%s' "$pm" | tr '[:upper:]' '[:lower:]')

[[ "$pm" =~ ^(npm|yarn|pnpm|bun)$ ]] || {
  echo "❌  Package manager must be npm | yarn | pnpm | bun"; exit 1; }

[[ -f package.json ]] || {
  echo "❌  Run this script in the project root (package.json missing)"; exit 1; }

command -v "$pm" >/dev/null || {
  echo "❌  $pm is not installed or not in PATH"; exit 1; }

# ---------- map helpers per package manager ----------
case "$pm" in
  npm)
    install=(npm install --save-dev)        # array prevents word-splitting issues
    run="npm run"
    exec_bin="npx"
    commitlint_hook='npx --no-install commitlint --edit "$1"'
    ;;
  yarn)
    install=(yarn add --dev)
    run="yarn"
    if yarn dlx --help >/dev/null 2>&1; then
      exec_bin="yarn dlx"
    else
      exec_bin="npx"
    fi
    commitlint_hook='yarn commitlint --edit "$1"'
    ;;
  pnpm)
    install=(pnpm add -D)
    run="pnpm"
    exec_bin="pnpm dlx"
    commitlint_hook='pnpm exec commitlint --edit "$1"'
    ;;
  bun)
    install=(bun add -d)
    run="bun run"
    exec_bin="bunx"
    commitlint_hook='bunx commitlint --edit "$1"'
    ;;
esac

# ---------- initialise git repo if missing ----------
[ -d .git ] || git init

# ---------- download config files ----------
repo_base="https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main"
curl -sSfL "$repo_base/eslint.config.js"       -o eslint.config.js
curl -sSfL "$repo_base/.prettierrc"            -o .prettierrc
curl -sSfL "$repo_base/commitlint.config.js"   -o commitlint.config.js
echo "✅  Config files downloaded."

# ---------- install devDependencies ----------
echo "📦  Installing ESLint Flat, Prettier, Husky, lint-staged & Commitlint …"
"${install[@]}" \
  eslint prettier husky lint-staged \
  @commitlint/cli @commitlint/config-conventional \
  @react-native-community/eslint-config eslint-config-prettier eslint-plugin-prettier

# ---------- patch package.json ----------
echo "🛠️  Updating package.json scripts…"
lintstaged='{"*.{js,jsx,ts,tsx,json,md}":["prettier --write","eslint --fix"]}'

if command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq --argjson ls "$lintstaged" '
      .scripts   |= (. // {}) + {
        "lint":"eslint .",
        "lint:fix":"eslint . --fix",
        "format":"prettier --write .",
        "prepare":"husky install",
        "lint-staged":"lint-staged"
      }
      | ."lint-staged" = $ls ' package.json > "$tmp" && mv "$tmp" package.json
else
  # fallback to Node (or Bun) if jq missing
  node - <<'NODE'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.scripts ||= {};
pkg.scripts.lint = 'eslint .';
pkg.scripts['lint:fix'] = 'eslint . --fix';
pkg.scripts.format = 'prettier --write .';
pkg.scripts.prepare = 'husky install';
pkg.scripts['lint-staged'] = 'lint-staged';
pkg['lint-staged'] = { '*.{js,jsx,ts,tsx,json,md}': ['prettier --write','eslint --fix'] };
fs.writeFileSync('package.json', JSON.stringify(pkg,null,2));
NODE
fi

# ---------- Husky v9 setup & hooks ----------
$exec_bin husky install
$exec_bin husky set .husky/pre-commit "$run lint-staged"
$exec_bin husky set .husky/commit-msg "$commitlint_hook"

echo "🎉  All done! ESLint Flat, Prettier, Husky hooks & Commitlint are ready. Try committing to see them in action."
