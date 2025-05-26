#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --------------------------------------------
# Usage:
#   curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh \
#     | bash -s [npm|yarn|pnpm|bun]
# --------------------------------------------

# 1) Pick package manager
pm="${1:-npm}"
pm=$(printf '%s' "$pm" | tr '[:upper:]' '[:lower:]')

[[ "$pm" =~ ^(npm|yarn|pnpm|bun)$ ]] || {
  echo "❌  PM must be one of: npm | yarn | pnpm | bun"; exit 1; }
[[ -f package.json ]] || { echo "❌  No package.json found—run in project root"; exit 1; }
command -v "$pm" >/dev/null 2>&1 || { echo "❌  '$pm' not in PATH"; exit 1; }

# 2) Map helpers per PM (arrays for install & run)
case "$pm" in
  npm)
    install_cmd=(npm install --save-dev --)     # array prevents word-splitting issues
    run_cmd=(npm run)
    commitlint_cmd='npx --no-install commitlint --edit "$1"'
    ;;
  yarn)
    install_cmd=(yarn add --dev --)
    run_cmd=(yarn)
    commitlint_cmd='yarn commitlint --edit "$1"'
    ;;
  pnpm)
    install_cmd=(pnpm add -D --)
    run_cmd=(pnpm run)
    commitlint_cmd='pnpm exec commitlint --edit "$1"'
    ;;
  bun)
    install_cmd=(bun add -d --)
    run_cmd=(bun run)
    commitlint_cmd='bunx commitlint --edit "$1"'
    ;;
esac

# 3) Init Git if missing (needed for Husky)
[ -d .git ] || git init

# 4) Download config files
repo_base="https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main"
curl -sSfL "$repo_base/eslint.config.js"     -o eslint.config.js
curl -sSfL "$repo_base/.prettierrc"          -o .prettierrc
curl -sSfL "$repo_base/commitlint.config.js" -o commitlint.config.js
echo "✅  Config files downloaded."

# 5) Build install list, skipping only exact 'eslint'
pkg_list=(eslint prettier husky lint-staged \
  @commitlint/cli @commitlint/config-conventional \
  @react-native-community/eslint-config eslint-config-prettier eslint-plugin-prettier eslint-plugin-import)
if grep -Eq '"eslint"\s*:' package.json; then
  echo "ℹ️  ESLint found—skipping ESLint install."
  filtered=()
  for pkg in "${pkg_list[@]}"; do
    [[ "$pkg" == "eslint" ]] && continue
    filtered+=("$pkg")
  done
  pkg_list=("${filtered[@]}")
fi

# 6) Install devDependencies
echo "📦  Installing code-quality packages…"
"${install_cmd[@]}" "${pkg_list[@]}"

# 7) Patch package.json: scripts & lint-staged
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
const fs=require('fs');
const pkg=JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.scripts ||= {};
Object.assign(pkg.scripts,{
  lint:'eslint .',
  'lint:fix':'eslint . --fix',
  format:'prettier --write .',
  prepare:'husky',
  'lint-staged':'lint-staged'
});
pkg['lint-staged']={ '*.{js,jsx,ts,tsx}':['prettier --write','eslint --fix'] };
fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));
JS
fi

# 8) Bootstrap Husky via prepare script
echo "🔧  Bootstrapping Husky…"
"${run_cmd[@]}" prepare

# 9) Manually create hooks (avoids deprecated commands)
echo "🔨  Creating Git hooks…"
touch .husky/pre-commit .husky/commit-msg

pre_cmd="${run_cmd[*]} lint-staged"  # e.g. "npm run lint-staged" or "bun run lint-staged"
cat > .husky/pre-commit << HOOK
#!/usr/bin/env sh
$pre_cmd
HOOK
chmod +x .husky/pre-commit

cat > .husky/commit-msg << HOOK
#!/usr/bin/env sh
$commitlint_cmd
HOOK
chmod +x .husky/commit-msg

echo "🎉  Setup complete! ESLint Flat Config, Prettier, Husky hooks, lint-staged & commitlint are configured."
