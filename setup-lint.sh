#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Determine package manager from first argument (default to npm if not provided)
package_manager="${1:-npm}"
package_manager="${package_manager,,}"  # convert to lowercase for safety

# If user requests help, display usage and exit
if [[ "$package_manager" == "-h" || "$package_manager" == "--help" ]]; then
    echo "Usage: curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh | bash -s [npm|yarn|pnpm|bun]"
    exit 0
fi

# Validate package manager choice
if ! [[ $package_manager =~ ^(npm|yarn|pnpm|bun)$ ]]; then
    echo "Error: Unsupported package manager '$package_manager'. Use npm, yarn, pnpm, or bun." >&2
    exit 1
fi

# Ensure package.json exists in current directory
if [[ ! -f package.json ]]; then
    echo "Error: package.json not found. Please run this script at the root of a Node/React Native project." >&2
    exit 1
fi

# Ensure the chosen package manager is installed
if ! command -v "$package_manager" >/dev/null 2>&1; then
    echo "Error: $package_manager is not installed or not available in PATH." >&2
    exit 1
fi

# Set appropriate install command and run command based on package manager
install_cmd=""
run_cmd=""
case "$package_manager" in
    npm)
        install_cmd="npm install --save-dev"
        run_cmd="npm run"  # npm requires 'run' for custom scripts
        ;;
    yarn)
        install_cmd="yarn add --dev"
        run_cmd="yarn"     # Yarn can run scripts directly
        ;;
    pnpm)
        install_cmd="pnpm add --save-dev"
        run_cmd="pnpm"     # PNPM can run scripts directly
        ;;
    bun)
        install_cmd="bun add -d"
        run_cmd="bun run"  # Bun requires 'run' to run package scripts
        ;;
esac

# Define command to execute Husky CLI (package manager specific)
husky_exec=""
if [[ "$package_manager" == "yarn" ]]; then
    # Use yarn dlx for Yarn 2+, or npx for Yarn 1 (which lacks dlx)
    yarn_major=$(yarn --version | cut -d. -f1 || echo "1")
    if [[ "$yarn_major" =~ ^[0-9]+$ ]] && (( yarn_major >= 2 )); then
        husky_exec="yarn dlx"
    else
        husky_exec="npx"
    fi
elif [[ "$package_manager" == "pnpm" ]]; then
    husky_exec="pnpm dlx"  # pnpm v6+ supports dlx (alias to pnpx)
elif [[ "$package_manager" == "bun" ]]; then
    husky_exec="bunx"      # bunx is Bun's equivalent to npx
else
    husky_exec="npx"
fi

# Download configuration files from GitHub repository (replace placeholders with actual repo if needed)
config_repo_base="https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main"
echo "Downloading config files..."
if ! curl -sSfL "$config_repo_base/.eslintrc.js" -o .eslintrc.js; then
    echo "Error: Failed to download .eslintrc.js" >&2
    exit 1
fi
if ! curl -sSfL "$config_repo_base/.prettierrc" -o .prettierrc; then
    echo "Error: Failed to download .prettierrc" >&2
    exit 1
fi
if ! curl -sSfL "$config_repo_base/commitlint.config.js" -o commitlint.config.js; then
    echo "Error: Failed to download commitlint.config.js" >&2
    exit 1
fi

# Initialize a Git repository if one doesn't exist (required for Husky to install hooks)
if [[ ! -d .git ]]; then
    echo "Initializing new Git repository..."
    git init
fi

# Install latest versions of code quality devDependencies
echo "Installing devDependencies (ESLint, Prettier, Husky, lint-staged, Commitlint, etc.)..."
$install_cmd eslint prettier husky lint-staged @commitlint/cli @commitlint/config-conventional \
    @react-native-community/eslint-config eslint-config-prettier eslint-plugin-prettier

# Add linting and formatting scripts, and lint-staged configuration to package.json
echo "Configuring package.json scripts and lint-staged settings..."
if command -v jq >/dev/null 2>&1; then
    # Use jq to merge new scripts and add lint-staged config
    tmpfile=$(mktemp) 
    jq '.scripts = (.scripts // {} + {
            "lint": "eslint .",
            "lint:fix": "eslint . --fix",
            "format": "prettier --write .",
            "prepare": "husky install",
            "lint-staged": "lint-staged"
        }) | ."lint-staged" = {
            "*.{js,jsx,ts,tsx,json,md}": ["prettier --write", "eslint --fix"]
        }' package.json > "$tmpfile" && mv "$tmpfile" package.json
else
    # Fallback to Node.js (or Bun) for JSON editing if jq is not available
    if command -v node >/dev/null 2>&1; then
        node - <<'EOF'
const fs = require('fs');
const pkgFile = 'package.json';
const pkg = JSON.parse(fs.readFileSync(pkgFile, 'utf8'));
pkg.scripts = pkg.scripts || {};
pkg.scripts['lint'] = 'eslint .';
pkg.scripts['lint:fix'] = 'eslint . --fix';
pkg.scripts['format'] = 'prettier --write .';
pkg.scripts['prepare'] = 'husky install';
pkg.scripts['lint-staged'] = 'lint-staged';
pkg['lint-staged'] = {
    '*.{js,jsx,ts,tsx,json,md}': ['prettier --write', 'eslint --fix']
};
fs.writeFileSync(pkgFile, JSON.stringify(pkg, null, 2));
EOF
    elif command -v bun >/dev/null 2>&1; then
        bun run - <<'EOF'
const fs = require('fs');
const pkgFile = 'package.json';
const pkg = JSON.parse(fs.readFileSync(pkgFile, 'utf8'));
pkg.scripts = pkg.scripts || {};
pkg.scripts['lint'] = 'eslint .';
pkg.scripts['lint:fix'] = 'eslint . --fix';
pkg.scripts['format'] = 'prettier --write .';
pkg.scripts['prepare'] = 'husky install';
pkg.scripts['lint-staged'] = 'lint-staged';
pkg['lint-staged'] = {
    '*.{js,jsx,ts,tsx,json,md}': ['prettier --write', 'eslint --fix']
};
fs.writeFileSync(pkgFile, JSON.stringify(pkg, null, 2));
EOF
    else
        echo "Error: Could not update package.json. Install 'jq' or Node.js to modify package.json automatically." >&2
        exit 1
    fi
fi

# Initialize Husky and set up Git hooks for linting and commit messages
echo "Setting up Husky git hooks..."
$husky_exec husky install

# Configure Husky pre-commit hook to run lint-staged
$husky_exec husky set .husky/pre-commit "$run_cmd lint-staged"

# Configure Husky commit-msg hook to run commitlint
if [[ "$package_manager" == "bun" ]]; then
    $husky_exec husky set .husky/commit-msg 'bunx commitlint --edit "$1"'
elif [[ "$package_manager" == "yarn" ]]; then
    $husky_exec husky set .husky/commit-msg 'yarn commitlint --edit "$1"'
elif [[ "$package_manager" == "pnpm" ]]; then
    $husky_exec husky set .husky/commit-msg 'pnpm exec commitlint --edit "$1"'
else
    $husky_exec husky set .husky/commit-msg 'npx --no-install commitlint --edit "$1"'
fi

echo "All done! ✅ Linting and commit hooks have been configured successfully."
