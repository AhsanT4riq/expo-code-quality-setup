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
  - NativeWind (utility-first CSS in React Native)
- � **Automatic dependency installation**
- 🛡️ **Error handling** and validation
- 🤝 **Interactive setup process** with customizable installation options

## Prerequisites

- Node.js (v14 or later)
- npm, yarn, pnpm, or bun
- Git

## Installation

### Download and Run

If you prefer to download and inspect the script first:

```bash
# Download the script
curl -sL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/code-quality.sh \
  -o code-quality.sh

# Make it executable
chmod +x code-quality.sh

# Run the script
./code-quality.sh
```

The script will guide you through an interactive setup process where you can choose:

- **Package Manager**: Select from bun, npm, yarn, or pnpm using arrow keys
- **Code Quality Tools**: ESLint & Prettier for linting and formatting
- **Git Hooks**: Husky, lint-staged & Commitlint for automated quality checks
- **Styling**: NativeWind & TailwindCSS for utility-first CSS in React Native

## What It Does

### Interactive Setup Process

1. **Package Manager Selection**: Choose your preferred package manager with an intuitive arrow-key menu
2. **Customizable Installation**: Select which tools you want to install based on your project needs
3. **Smart Configuration**: Only downloads and configures the tools you choose

### Code Quality Tools (Optional)

- Downloads configuration files:
  - `eslint.config.js` - ESLint flat config for modern projects
  - `.prettierrc` - Prettier formatting rules
- Installs ESLint and Prettier as dev dependencies
- Adds useful scripts to `package.json`:
  ```json
  {
    "scripts": {
      "lint": "eslint .",
      "lint:fix": "eslint . --fix",
      "format": "prettier --write ."
    }
  }
  ```

### Git Hooks & Commit Standards (Optional)

- Downloads `commitlint.config.js` for conventional commit messages
- Installs Husky, lint-staged, and Commitlint
- Sets up automated Git hooks:
  - **Pre-commit**: Runs lint-staged to format and lint staged files
  - **Commit-msg**: Validates commit message format
- Configures lint-staged in `package.json`:
  ```json
  {
    "lint-staged": {
      "*.{js,jsx,ts,tsx}": ["prettier --write", "eslint --fix"]
    }
  }
  ```

### NativeWind & TailwindCSS Support (Optional)

- Installs `nativewind` and `tailwindcss` as production dependencies
- Downloads essential configuration files:
  - `tailwind.config.js` - Tailwind configuration
  - `global.css` - Global styles
  - `metro.config.js` - Metro bundler configuration
  - `babel.config.js` - Babel configuration for NativeWind
  - `nativewind-env.d.ts` - TypeScript declarations
- Provides setup instructions for importing global styles

## Included Tools

### Core Development Tools

- **ESLint**: Static code analysis and linting
- **Prettier**: Consistent code formatting
- **Husky**: Git hooks made simple
- **lint-staged**: Run linters only on staged files
- **Commitlint**: Enforce conventional commit messages

### Styling & UI (Optional)

- **NativeWind**: Tailwind CSS for React Native
- **TailwindCSS**: Utility-first CSS framework

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
