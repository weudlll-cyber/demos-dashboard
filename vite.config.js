/**
 * @file vite.config.js
 * @project DEMOS Node Dashboard
 * @repository https://github.com/weudlll-cyber/demos-dashboard
 *
 * @description
 *   Vite build and dev-server configuration, plus Vitest test configuration.
 *
 *   Key settings:
 *     - @sveltejs/vite-plugin-svelte: compiles .svelte files during both
 *       dev and production builds.
 *     - server.proxy: in development, all requests to /api are forwarded to
 *       http://localhost:53550 so the browser is never making cross-origin
 *       requests. In production this proxy is not active — nginx handles
 *       routing instead (see scripts/nginx.conf).
 *     - test.environment: happy-dom provides a lightweight DOM implementation
 *       so component tests run without a real browser.
 *     - test.globals: exposes describe/it/expect/vi globally to avoid
 *       importing them in every test file.
 *     - test.setupFiles: runs src/test-setup.js before every test suite.
 *
 * @seeAlso  scripts/nginx.conf, src/test-setup.js
 *
 * @author  weudlll-cyber
 * @license MIT
 */

import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

export default defineConfig({
  plugins: [svelte()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:53550',
        changeOrigin: true,
      },
    },
  },
  test: {
    // Use happy-dom as the DOM environment — lightweight and fast
    environment: 'happy-dom',
    // Make vitest globals (describe, it, expect, vi) available without imports
    globals: true,
    // Run this file before every test suite
    setupFiles: ['./src/test-setup.js'],
  },
});
