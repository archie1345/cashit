// functions/eslint.config.js

const globals = require('globals');
const js = require('@eslint/js');

module.exports = [
  // Use ESLint's recommended built-in rules
  js.configs.recommended,

  {
    // Apply rules to all JavaScript files
    files: ['**/*.js'],

    // Define language options
    languageOptions: {
      ecmaVersion: 2022, // Use a modern ECMAScript version
      sourceType: 'commonjs', // Firebase Functions use CommonJS modules
      globals: {
        ...globals.node, // Add all Node.js global variables
      },
    },

    // Define your custom rules here
    rules: {
      // Allow console.log for Firebase Functions logging
      'no-console': 'off',
      // Enforce consistent indentation (2 spaces)
      'indent': ['error', 2],
      // Enforce single quotes
      'quotes': ['error', 'single'],
      // Require semicolons at the end of statements
      'semi': ['error', 'always'],
      // Warn about unused variables instead of causing an error
      'no-unused-vars': 'warn',
      // Disallow trailing spaces
      'no-trailing-spaces': 'error',
    },
  },
];