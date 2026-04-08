/**
 * test-setup.js — Vitest global setup
 * Extends expect with @testing-library/jest-dom matchers and
 * provides a polyfill for AbortSignal.timeout in older test environments.
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
