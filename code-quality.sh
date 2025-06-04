#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --------------------------------------------
# Usage:
#   curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/code-quality.sh | bash
# --------------------------------------------

echo "🚀 Welcome to the Expo Code Quality Setup!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1) Check prerequisites
[[ -f package.json ]] || { echo "❌  No package.json found—run in project root"; exit 1; }

# 2) Interactive package manager selection with arrow keys
select_package_manager() {
  local options=("bun" "npm" "yarn" "pnpm")
  local selected=0
  local key
  
  echo "📦 Please select your package manager:"
  echo "   Use ↑/↓ arrow keys to navigate, Enter to select"
  echo ""
  
  while true; do
    # Clear previous menu
    for ((i=0; i<${#options[@]}; i++)); do
      echo -ne "\033[2K\r"  # Clear line
      if [[ $i -eq $selected ]]; then
        echo -e "   \033[1;32m► ${options[$i]}\033[0m"  # Green arrow and text for selected
      else
        echo "     ${options[$i]}"
      fi
    done
    
    # Move cursor back up to redraw menu
    echo -ne "\033[${#options[@]}A"
    
    # Read single character
    IFS= read -rsn1 key
    
    case "$key" in
      $'\x1b')  # ESC sequence
        read -rsn2 key  # Read the next two characters
        case "$key" in
          '[A')  # Up arrow
            ((selected > 0)) && ((selected--))
            ;;
          '[B')  # Down arrow
            ((selected < ${#options[@]} - 1)) && ((selected++))
            ;;
        esac
        ;;
      '')  # Enter key
        break
        ;;
    esac
  done
  
  # Move cursor down past the menu
  echo -ne "\033[${#options[@]}B"
  echo ""
  
  # Set the selected package manager directly
  pm="${options[$selected]}"
}

# Call the selection function
select_package_manager

# Verify the selected package manager is available
command -v "$pm" >/dev/null 2>&1 || { echo "❌  '$pm' not found in PATH. Please install $pm first."; exit 1; }

echo "✅ Using $pm as package manager"
echo ""

# 3) Map helpers per PM (arrays for install & run)
case "$pm" in
  npm)
    install_cmd=(npm install --save-dev --)     # array prevents word-splitting issues
    install_cmd_prod=(npm install --)           # for production dependencies
    run_cmd=(npm run)
    commitlint_cmd='npx --no-install commitlint --edit "$1"'
    ;;
  yarn)
    install_cmd=(yarn add --dev --)
    install_cmd_prod=(yarn add --)
    run_cmd=(yarn)
    commitlint_cmd='yarn commitlint --edit "$1"'
    ;;
  pnpm)
    install_cmd=(pnpm add -D --)
    install_cmd_prod=(pnpm add --)
    run_cmd=(pnpm run)
    commitlint_cmd='pnpm exec commitlint --edit "$1"'
    ;;
  bun)
    install_cmd=(bun add -d --)
    install_cmd_prod=(bun add --)
    run_cmd=(bun run)
    commitlint_cmd='bunx commitlint --edit "$1"'
    ;;
esac

# 4) Init Git if missing (needed for Husky)
[ -d .git ] || git init

# 5) Collect user preferences with prompts
echo "📋 Please answer the following questions to customize your setup:"
echo ""

# Prompt 1: ESLint & Prettier
echo "🔍 1/3: Would you like to install ESLint & Prettier for code linting and formatting?"
echo -n "   This will add code quality checks to your project (Y/n)? "
read -r install_eslint_prettier
install_eslint_prettier="${install_eslint_prettier:-Y}"

echo ""

# Prompt 2: Husky & lint-staged & Commitlint
echo "🔗 2/3: Would you like to install Husky, lint-staged & Commitlint for Git hooks?"
echo -n "   This will enforce code quality on commits and standardize commit messages (Y/n)? "
read -r install_git_hooks
install_git_hooks="${install_git_hooks:-Y}"

echo ""

# Prompt 3: NativeWind & TailwindCSS
echo "🎨 3/3: Would you like to install NativeWind for Tailwind CSS support?"
echo -n "   This will add utility-first CSS styling to your React Native project (Y/n)? "
read -r install_nativewind
install_nativewind="${install_nativewind:-Y}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Starting installation based on your selections..."
echo ""

# 5) Install ESLint & Prettier if selected
if [[ "$install_eslint_prettier" =~ ^[Yy]$ ]]; then
  echo "🔍 Installing ESLint & Prettier..."
  
  # Download config files
  repo_base="https://raw.githubusercontent.com/ahsant4riq/expo-code-quality-setup/main"
  curl -sSfL "$repo_base/eslint.config.js"     -o eslint.config.js
  curl -sSfL "$repo_base/.prettierrc"          -o .prettierrc
  echo "✅ ESLint & Prettier config files downloaded."

  # Build install list, skipping only exact 'eslint'
  pkg_list=(eslint prettier)

  if grep -Eq '"eslint"\s*:' package.json; then
    echo "ℹ️  ESLint found—skipping ESLint install."
    pkg_list=(prettier)
  fi

  # Install packages
  "${install_cmd[@]}" "${pkg_list[@]}"
  echo "✅ ESLint & Prettier installed."
  echo ""
fi

# 6) Install Git hooks if selected
if [[ "$install_git_hooks" =~ ^[Yy]$ ]]; then
  echo "🔗 Installing Husky, lint-staged & Commitlint..."
  
  # Download commitlint config if not already downloaded
  if [[ "$install_eslint_prettier" =~ ^[Nn]$ ]]; then
    repo_base="https://raw.githubusercontent.com/ahsant4riq/expo-code-quality-setup/main"
  fi
  curl -sSfL "$repo_base/commitlint.config.js" -o commitlint.config.js
  echo "✅ Commitlint config file downloaded."

  # Install Git hook packages
  git_pkg_list=(husky lint-staged @commitlint/cli @commitlint/config-conventional)
  "${install_cmd[@]}" "${git_pkg_list[@]}"
  echo "✅ Git hook packages installed."
  echo ""
fi

# 7) Update package.json scripts if any linting/git tools were installed
if [[ "$install_eslint_prettier" =~ ^[Yy]$ ]] || [[ "$install_git_hooks" =~ ^[Yy]$ ]]; then
  echo "🛠️  Updating package.json scripts..."
  
  # Build scripts and lint-staged config based on selections
  scripts_obj='{"prepare":"husky","lint-staged":"lint-staged"}'
  lintstaged_obj='{}'
  
  if [[ "$install_eslint_prettier" =~ ^[Yy]$ ]]; then
    scripts_obj='{"lint":"eslint .","lint:fix":"eslint . --fix","format":"prettier --write .","prepare":"husky","lint-staged":"lint-staged"}'
    lintstaged_obj='{"*.{js,jsx,ts,tsx}":["prettier --write","eslint --fix"]}'
  fi
  
  if command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    jq --argjson scripts "$scripts_obj" --argjson ls "$lintstaged_obj" '
      .scripts |= (. // {}) + $scripts
      | if ($ls | length) > 0 then ."lint-staged" = $ls else . end
    ' package.json > "$tmp" && mv "$tmp" package.json
  else
    node - <<JS
const fs=require('fs');
const pkg=JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.scripts ||= {};
const scripts = $scripts_obj;
const lintstaged = $lintstaged_obj;
Object.assign(pkg.scripts, scripts);
if (Object.keys(lintstaged).length > 0) {
  pkg['lint-staged'] = lintstaged;
}
fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));
JS
  fi
  echo "✅ Package.json updated."
  echo ""
fi

# 8) Setup Husky hooks if Git hooks were selected
if [[ "$install_git_hooks" =~ ^[Yy]$ ]]; then
  echo "🔧 Bootstrapping Husky..."
  "${run_cmd[@]}" prepare

  echo "🔨 Creating Git hooks..."
  touch .husky/pre-commit .husky/commit-msg

  pre_cmd="$(IFS=' '; echo "${run_cmd[*]}") lint-staged"
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
  echo "✅ Git hooks configured."
  echo ""
fi

# 9) Install NativeWind if selected
if [[ "$install_nativewind" =~ ^[Yy]$ ]]; then
  echo "🎨 Installing NativeWind & TailwindCSS..."
  
  # Install packages as production dependencies
  "${install_cmd_prod[@]}" nativewind tailwindcss
  echo "✅ NativeWind & TailwindCSS installed."
  
  echo "📥 Downloading NativeWind configuration files..."
  
  # Base URL for NativeWind config files
  nativewind_base="https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/nativewind"
  
  # Download NativeWind config files to project root
  curl -sSfL "$nativewind_base/tailwind.config.js" -o tailwind.config.js
  curl -sSfL "$nativewind_base/global.css" -o global.css
  curl -sSfL "$nativewind_base/metro.config.js" -o metro.config.js
  curl -sSfL "$nativewind_base/nativewind-env.d.ts" -o nativewind-env.d.ts
  curl -sSfL "$nativewind_base/babel.config.js" -o babel.config.js
  
  echo "✅ NativeWind configuration files downloaded."
  echo ""
fi

# 10) Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Setup Complete! Your project now includes:"

if [[ "$install_eslint_prettier" =~ ^[Yy]$ ]]; then
  echo "   ✓ ESLint & Prettier"
fi

if [[ "$install_git_hooks" =~ ^[Yy]$ ]]; then
  echo "   ✓ Husky & lint-staged"
  echo "   ✓ Commitlint"
fi

if [[ "$install_nativewind" =~ ^[Yy]$ ]]; then
  echo "   ✓ NativeWind & TailwindCSS"
  echo ""
  echo "📌 IMPORTANT: To complete NativeWind setup:"
  echo "   Import the global.css file in your root _layout file:"
  echo ""
  echo "   import '../global.css';"
  echo ""
  echo "   For TypeScript projects, add to your _layout.tsx"
  echo "   For JavaScript projects, add to your _layout.js"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
