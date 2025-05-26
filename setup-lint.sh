#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --------------------------------------------
# Usage:
#   curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh \
#     | bash -s [npm|yarn|pnpm|bun]
# --------------------------------------------

pm="${1:-npm}"
pm=$(printf '%s' "$pm" | tr '[:upper:]' '[:lower:]')

[[ "$pm" =~ ^(npm|yarn|pnpm|bun)$ ]] || {
  echo "❌  Package manager must be npm|yarn|pnpm|bun"; exit 1; }
[[ -f package.json ]] || { echo "❌  Run in project root (package.json missing)"; exit 1; }
command -v "$pm" >/dev/null || { echo "❌  $pm not found in PATH"; exit 1; }

# --- map helpers per package manager (using arrays for install cmd) ---
case "$pm" in
  npm)
    install=(npm install --save-dev)
    run="npm run"
    dlx="npx"
    commitlint_cmd='npx --no-install commitlint --edit "$1"'
    ;;
  yarn)
    install=(yarn add --dev)
    run="yarn"
    if yarn dlx --help >/dev/null 2>&1; then dlx="yarn dlx"; else dlx="npx"; fi
    commitlint_cmd='yarn commitlint --edit "$1"'
    ;;
  pnpm)
    install=(pnpm add -D)
    run="pnpm"
    dlx="pnpm dlx"
    commitlint_cmd='pnpm exec commitlint --edit "$1"'
    ;;
  bun)
    install=(bun add -d)
    run="bun run"
    dlx="bunx"
    commitlint_cmd='bunx commitlint --edit "$1"'
    ;;
esac

# --- init Git if needed (Husky hooks require .git) ---
[ -d .git ] || git init

# --- download config files ---
repo_base="https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main"
curl -sSfL "$repo_base/eslint.config.js"     -o eslint.config.js
curl -sSfL "$repo_base/.prettierrc"          -o .prettierrc
curl -sSfL "$repo_base/commitlint.config.js" -o commitlint.config.js
echo "✅  Config files downloaded."

# --- determine install list, skipping eslint if already present ---
pkg_list=(eslint prettier husky lint-staged \
  @commitlint/cli @commitlint/config-conventional \
  @react-native-community/eslint-config eslint-config-prettier eslint-plugin-prettier)
if grep -Eq '"eslint"\s*:' package.json; then
  echo "ℹ️  ESLint already detected in package.json—skipping ESLint install."
  pkg_list=("${pkg_list[@]/eslint}")
fi

# --- install devDependencies ---
echo "📦  Installing code-quality packages…"
"${install[@]}" "${pkg_list[@]}"

# --- patch package.json scripts & lint-staged ---
echo "🛠️  Updating package.json scripts…"
lintstaged='{"*.{js,jsx,ts,tsx}":["prettier --write","eslint --fix"]}'
if command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq --argjson ls "$lintstaged" '
    .scripts |= (. // {}) + {
      "lint":"eslint .",
      "lint:fix":"eslint . --fix",
      "format":"prettier --write .",
      "prepare":"husky",
      "lint-staged":"lint-staged"
    }
    | ."lint-staged" = $ls
  ' package.json > "$tmp" && mv "$tmp" package.json
else
  node - <<'JS'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.scripts ||= {};
Object.assign(pkg.scripts, {
  lint: 'eslint .',
  'lint:fix': 'eslint . --fix',
  format: 'prettier --write .',
  prepare: 'husky',
  'lint-staged': 'lint-staged',
});
pkg['lint-staged'] = {
  '*.{js,jsx,ts,tsx}': ['prettier --write','eslint --fix']
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
JS
fi

# --- bootstrap Husky via prepare script ---
echo "🔧  Bootstrapping Husky (prepare)…"
$run prepare

# --- manually create hooks (avoids deprecated CLI) ---
echo "🔨  Creating Git hooks…"
mkdir -p .husky/_ && cp node_modules/husky/husky.sh .husky/_/husky.sh

cat > .husky/pre-commit << 'HOOK'
#!/usr/bin/env sh
"$run" lint-staged
HOOK
chmod +x .husky/pre-commit

cat > .husky/commit-msg << HOOK
#!/usr/bin/env sh
$commitlint_cmd
HOOK
chmod +x .husky/commit-msg

echo "🎉  Setup complete! ESLint Flat Config, Prettier, Husky hooks, lint-staged & commitlint are ready."
