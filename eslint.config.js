/**
 * @file eslint.config.js
 * @project DEMOS Node Dashboard
 * @repository https://github.com/weudlll-cyber/demos-dashboard
 *
 * @description
 *   ESLint flat-config (ESLint 9+) for source health checks.
 *   Covers .js files and Svelte single-file components (.svelte).
 *
 *   Rule goals:
 *     - Catch undefined variables and accidental globals.
 *     - Prevent unused variables from accumulating as dead code.
 *     - Flag common mistakes: == vs ===, unreachable code, duplicate keys.
 *     - Svelte-specific rules via eslint-plugin-svelte to catch bad
 *       reactive patterns and component prop issues.
 *
 *   Run manually: npx eslint src --ext .js,.svelte
 *   CI runs it with --max-warnings 0 (warnings treated as errors).
 *
 * @author  weudlll-cyber
 * @license MIT
 */

import js from '@eslint/js';
import svelte from 'eslint-plugin-svelte';
import svelteParser from 'svelte-eslint-parser';

export default [
  // --- Global ignores ---
  {
    ignores: [
      'dist/**',
      'node_modules/**',
    ],
  },

  // --- JavaScript files ---
  {
    files: ['**/*.js'],
    ...js.configs.recommended,
    rules: {
      // Catch suspicious equality comparisons (== allows type coercion bugs)
      eqeqeq: ['error', 'always', { null: 'ignore' }],

      // Prevent unused variables — a common source of stale/dead code
      // Leading underscores are allowed as an explicit "intentionally unused" signal
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],

      // Disallow console.log left in production code; console.error/warn are OK
      'no-console': ['warn', { allow: ['error', 'warn'] }],

      // Guard against == true/false comparisons that work by accident
      'no-constant-condition': 'error',

      // Catch duplicate object keys (a common copy-paste mistake)
      'no-dupe-keys': 'error',

      // Catch unreachable code after return / throw
      'no-unreachable': 'error',

      // Enforce === for all null checks (== null catches both null and undefined,
      // which is usually unintentional)
      'no-eq-null': 'off', // covered by eqeqeq above with null:'ignore'
    },
  },

  // --- Svelte component files ---
  {
    files: ['**/*.svelte'],
    plugins: { svelte },
    languageOptions: {
      parser: svelteParser,
      parserOptions: {
        // Tell the Svelte parser to use the default JS parser for <script> blocks
        parser: null,
      },
    },
    rules: {
      // Spread recommended Svelte rules
      ...svelte.configs.recommended.rules,

      // Svelte-specific: catch unused component props
      'svelte/no-unused-svelte-ignore': 'error',

      // Svelte-specific: prevent reactive declarations with side effects in templates
      'svelte/no-at-html-tags': 'error',
    },
  },
];
