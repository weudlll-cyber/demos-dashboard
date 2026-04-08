/**
 * @file test-setup.js
 * @project DEMOS Node Dashboard
 * @repository https://github.com/weudlll-cyber/demos-dashboard
 *
 * @description
 *   Global test setup file executed once before every test suite.
 *   Referenced by the `setupFiles` array in vite.config.js.
 *
 *   Responsibilities:
 *     1. Extends Vitest's `expect` with the full set of jest-dom matchers
 *        (e.g. toBeInTheDocument, toHaveTextContent, toBeVisible).
 *     2. Polyfills AbortSignal.timeout() for environments that don't yet
 *        implement the WHATWG AbortSignal extensions (happy-dom includes this
 *        but the polyfill ensures backwards compatibility with other envs).
 *
 * @seeAlso
 *   https://testing-library.com/docs/jest-dom
 *   https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/timeout_static
 *
 * @author  weudlll-cyber
 * @license MIT
 */

import '@testing-library/jest-dom/vitest';

// Polyfill AbortSignal.timeout for environments that don't support it yet
if (typeof AbortSignal.timeout !== 'function') {
  AbortSignal.timeout = function timeout(ms) {
    const controller = new AbortController();
    setTimeout(() => {
      const err = new DOMException('The operation timed out.', 'TimeoutError');
      controller.abort(err);
    }, ms);
    return controller.signal;
  };
}
