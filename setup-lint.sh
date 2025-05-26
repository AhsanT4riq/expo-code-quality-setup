#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Usage: curl -sL https://yourserver.com/setup-lint.sh | bash -s [npm|yarn|pnpm|bun]
pm="${1:-npm}" ; pm="${pm,,}"  # default -> npm, normalise case

[[ "$pm" =~ ^(npm|yarn|pnpm|bun)$ ]] || { echo "PM must be npm|yarn|pnpm|bun"; exit 1; }

[[ -f package.json ]] || { echo "Run in project root (package.json missing)"; exit 1; }

command -v "$pm" >/dev/null || { echo "$pm not found in PATH"; exit 1; }

# Map install / run / dlx helpers
case "$pm" in
  npm)  install="npm install -D";  run="npm run";  exec_bin="npx";;
  yarn) install="yarn add -D";     run="yarn";     exec_bin="$(command -v yarn dlx >/dev/null && echo 'yarn dlx' || echo 'npx')";;
  pnpm) install="pnpm add -D";     run="pnpm";     exec_bin="pnpm dlx";;
  bun)  install="bun add -d";      run="bun run";  exec_bin="bunx";;
esac

# Init git repo if missing (needed for Husky)
[ -d .git ] || git init

# ------- download flat-config files from GitHub repo -------
repo_base="https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main"

curl -sSfL "$repo_base/eslint.config.js"       -o eslint.config.js
curl -sSfL "$repo_base/.prettierrc"            -o .prettierrc
curl -sSfL "$repo_base/commitlint.config.js"   -o commitlint.config.js

echo "Config files downloaded."

# ------- install dev dependencies -------
echo "Installing ESLint Flat stack + Prettier + Husky v9 …"
$install eslint prettier husky \
  @commitlint/cli @commitlint/config-conventional lint-staged \
  @react-native-community/eslint-config eslint-config-prettier eslint-plugin-prettier

# ------- patch package.json (jq preferred) -------
echo "Updating package.json scripts…"
lintstaged='{"*.{js,jsx,ts,tsx,json,md}":["prettier --write","eslint --fix"]}'

if command -v jq >/dev/null; then
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
  node -e "
    const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));
    p.scripts={...p.scripts,
      lint:'eslint .',
      'lint:fix':'eslint . --fix',
      format:'prettier --write .',
      prepare:'husky install',
      'lint-staged':'lint-staged'};
    p['lint-staged']=$lintstaged;
    fs.writeFileSync('package.json',JSON.stringify(p,null,2));
  "
fi

# ------- Husky v9 setup & hooks -------
$exec_bin husky install
$exec_bin husky set .husky/pre-commit "$run lint-staged"
$exec_bin husky set .husky/commit-msg "$exec_bin --no-install commitlint --edit \"\$1\""

echo "✅  ESLint Flat, Prettier, Husky & Commitlint are ready. Try a commit to see the hooks fire!"
