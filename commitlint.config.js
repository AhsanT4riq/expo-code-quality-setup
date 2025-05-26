/**
 * Commitlint configuration enforcing Conventional Commits.
 * -------------------------------------------------------
 * Docs: https://www.conventionalcommits.org/
 */

module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Example: force kebab-case in scope, e.g. `feat(api-auth): ...`
    'scope-case': [2, 'always', 'kebab-case'],
  },
};
