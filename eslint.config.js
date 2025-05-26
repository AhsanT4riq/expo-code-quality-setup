// eslint.config.js – Flat Config for React Native / Expo 53+
const eslintPluginReact = require('eslint-plugin-react');
const eslintPluginReactNative = require('eslint-plugin-react-native');
const prettier = require('eslint-config-prettier');
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

module.exports = defineConfig([
  expoConfig,
  {
    ignores: ['node_modules', 'dist', 'android', 'ios'],
  },
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: { parserOptions: { project: ['./tsconfig.json'] } },
  },
  {
    // custom rules section
    rules: {
      'react/jsx-filename-extension': ['warn', { extensions: ['.tsx', '.jsx'] }],
      'react/prop-types': 'off',
      'prettier/prettier': 'error',
    },
    plugins: { react: eslintPluginReact, 'react-native': eslintPluginReactNative },
  },
  prettier,
]);
