# Code Quality Setup Script

A one-command setup script to add comprehensive code quality tooling to your React Native Expo projects.

## Features

- 🛠️ **Zero-configuration setup** for code quality tools
- 🔄 **Multiple package manager support**: npm, yarn, pnpm, and bun
- 🚀 **Automatic configuration** of:
  - ESLint (with React Native and Prettier plugins)
  - Prettier (code formatting)
  - Husky (Git hooks)
  - lint-staged (run linters on staged files)
  - Commitlint (enforce conventional commits)
- 🔄 **Git hooks** for pre-commit and commit message validation
- 📦 **Automatic dependency installation**
- 🛡️ **Error handling** and validation

## Prerequisites

- Node.js (v14 or later)
- npm, yarn, pnpm, or bun
- Git

## Installation

Run this one-liner in your project root:

```bash
# Using npm (default)
curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh | bash -s

# Or specify your preferred package manager
curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh | bash -s yarn
# or
curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh | bash -s pnpm
# or
curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/setup-lint.sh | bash -s bun
```

## What It Does

1. Validates your environment and package manager
2. Downloads standard configuration files:
   - `eslint.config.js`
   - `.prettierrc`
   - `commitlint.config.js`
3. Installs required development dependencies
4. Configures `package.json` with useful scripts:
   ```json
   {
     "scripts": {
       "lint": "eslint .",
       "lint:fix": "eslint . --fix",
       "format": "prettier --write .",
       "prepare": "husky install",
       "lint-staged": "lint-staged"
     },
     "lint-staged": {
       "*.{js,jsx,ts,tsx,json,md}": ["prettier --write", "eslint --fix"]
     }
   }
   ```
5. Sets up Git hooks:
   - Pre-commit: Runs lint-staged
   - Commit-msg: Validates commit messages

## Included Tools

- **ESLint**: Static code analysis
- **Prettier**: Code formatting
- **Husky**: Git hooks made easy
- **lint-staged**: Run linters on git staged files
- **Commitlint**: Lint commit messages
- **@commitlint/config-conventional**: Conventional commit rules

## Usage

After setup, these commands are available:

- `[npm|yarn|pnpm|bun] run lint`: Lint your code
- `[npm|yarn|pnpm|bun] run lint:fix`: Fix linting issues automatically
- `[npm|yarn|pnpm|bun] run format`: Format your code
- `git commit`: Will automatically validate commit messages and run linters on staged files

## Customization

1. **ESLint**: Edit `eslint.config.js` to modify linting rules
2. **Prettier**: Edit `.prettierrc` to change formatting rules
3. **Commit Messages**: Edit `commitlint.config.js` to modify commit message rules

## Requirements

- React Native Expo project with a `package.json` file
- Git repository (will be initialized if not present)

## License

MIT

---

Created with ❤️ by Ahsan Tariq
