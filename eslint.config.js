// eslint.config.js – Flat Config for React Native / Expo 53+
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

// Custom rules and overrides
module.exports = defineConfig([
  // Base Expo config
  ...expoConfig,

  // Ignore build artifacts
  {
    ignores: ['node_modules', 'dist', 'android', 'ios'],
  },

  // Enable TS project linting
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parserOptions: {
        project: './tsconfig.json',
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
  },

  // Custom rules
  {
    rules: {
      // React rules
      'react/jsx-filename-extension': ['warn', { extensions: ['.tsx', '.jsx'] }],
      'react/prop-types': 'off',

      // Import ordering & validation
      'import/order': [
        'error',
        {
          groups: ['builtin', 'external', 'internal', 'parent', 'sibling', 'index'],
          pathGroups: [
            {
              pattern: '@/**',
              group: 'internal',
              position: 'after',
            },
          ],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
      'import/first': 'error',
      'import/newline-after-import': 'error',
      'import/no-duplicates': 'error',
    },
  },
]);
