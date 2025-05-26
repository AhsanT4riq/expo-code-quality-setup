/**
 * ESLint configuration for a React Native project.
 * ------------------------------------------------
 * - Extends the official RN community rules.
 * - Integrates Prettier so formatting issues surface as ESLint errors.
 * - Adds a few sensible defaults you can tweak any time.
 */

module.exports = {
  root: true, // Stop ESLint from looking any higher
  extends: [
    '@react-native-community', // Base rules from RN core team
    'plugin:prettier/recommended', // Turns Prettier rules into ESLint errors
  ],
  plugins: ['react', 'react-native', 'prettier'],
  parserOptions: {
    ecmaVersion: 2023,
    sourceType: 'module',
  },
  env: {
    es2023: true,
    'react-native/react-native': true,
  },
  rules: {
    // Allow JSX in .js, .jsx, .ts, .tsx files
    'react/jsx-filename-extension': [1, { extensions: ['.js', '.jsx', '.ts', '.tsx'] }],

    // Prefer arrow functions for functional components
    'react/function-component-definition': [2, { namedComponents: 'arrow-function' }],

    // Treat Prettier formatting issues as ESLint errors
    'prettier/prettier': ['error'],

    // Disable prop-types if you rely on TypeScript or another validator
    'react/prop-types': 'off',
  },

  // Example: stricter settings just for TypeScript files
  overrides: [
    {
      files: ['*.ts', '*.tsx'],
      parser: '@typescript-eslint/parser',
      extends: ['plugin:@typescript-eslint/recommended'],
    },
  ],
};
