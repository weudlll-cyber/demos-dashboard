/**
 * @file main.js
 * @project DEMOS Node Dashboard
 * @repository https://github.com/weudlll-cyber/demos-dashboard
 *
 * @description
 *   Application entry point. Instantiates the root Svelte component (App)
 *   and mounts it into the #app div defined in index.html.
 *
 *   Vite uses this file as the module graph root when building the bundle.
 *
 * @author  weudlll-cyber
 * @license MIT
 */

import App from './App.svelte';

const app = new App({
  target: document.getElementById('app'),
});

export default app;
