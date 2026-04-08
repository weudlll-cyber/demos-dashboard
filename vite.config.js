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
