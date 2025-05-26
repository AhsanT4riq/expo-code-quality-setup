// eslint.config.js – Flat Config for React Native / Expo 53+
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

// Plugins
const eslintPluginReact = require('eslint-plugin-react');
const eslintPluginReactNative = require('eslint-plugin-react-native');
const eslintPluginImport = require('eslint-plugin-import');
const eslintPluginPrettier = require('eslint-plugin-prettier');

// Prettier config
const prettier = require('eslint-config-prettier');

module.exports = defineConfig([
  expoConfig,

  // Ignore build artifacts
  {
    ignores: ['node_modules', 'dist', 'android', 'ios'],
  },

  // Enable TS project linting
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: { parserOptions: { project: ['./tsconfig.json'] } },
  },

  // Custom rules & plugins
  {
    plugins: {
      react: eslintPluginReact,
      'react-native': eslintPluginReactNative,
      import: eslintPluginImport,
      prettier: eslintPluginPrettier,
    },
    rules: {
      // React rules
      'react/jsx-filename-extension': ['warn', { extensions: ['.tsx', '.jsx'] }],
      'react/prop-types': 'off',

      // Import ordering & validation
      'import/order': [
        'error',
        {
          groups: ['builtin', 'external', 'internal', 'parent', 'sibling', 'index'],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
      'import/first': 'error',
      'import/newline-after-import': 'error',
      'import/no-duplicates': 'error',

      // Prettier integration
      'prettier/prettier': 'error',
    },
  },

  // Finally, disable any ESLint rules that conflict with Prettier
  prettier,
]);
