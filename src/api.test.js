/**
 * @file api.test.js
 * @project DEMOS Node Dashboard
 * @repository https://github.com/weudlll-cyber/demos-dashboard
 *
 * @description
 *   Unit test suite for src/api.js.
 *   Tests the fetchNodeData() function under all realistic conditions:
 *   successful responses, HTTP error codes, network failures, and timeouts.
 *
 *   All tests run in a happy-dom environment (no real browser or network).
 *   The global `fetch` is replaced with a vi.fn() mock in each test to keep
 *   tests isolated and deterministic.
 *
 * @coverage
 *   - Happy path: 200 OK with valid JSON body
 *   - HTTP 4xx: 404 Not Found
 *   - HTTP 5xx: 500 Internal Server Error
 *   - Network error (fetch rejects with Error)
 *   - Timeout (fetch rejects with DOMException 'TimeoutError')
 *   - AbortError edge case
 *   - Empty peerlist (valid response, zero peers)
 *   - Correct URL and Accept header
 *
 * @testFramework Vitest 1.x
 * @environment   happy-dom (see vite.config.js)
 *
 * @author  weudlll-cyber
 * @license MIT
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { fetchNodeData } from './api.js';

// --- Fixtures ---

const VALID_DATA = {
  version: '0.9.8',
  version_name: 'Oxlong Michael',
  identity: '0xd9409b0d6106e5358b29a56bd4957a1f31fa1a192f00b85cb02709170447f4ab',
  connectionString: 'http://localhost:53550',
  peerlist: [
    {
      connection: { string: 'http://localhost:53550' },
      identity: '0xd9409b0d6106e5358b29a56bd4957a1f31fa1a192f00b85cb02709170447f4ab',
      verification: { status: false },
      sync: {
        status: true,
        block: 701638,
        block_hash: '9305e28c5c3cf22305307220f8162a2b572ebfd94c81cfee478a8e9cbaf4e52f',
      },
      status: { online: true, ready: false },
    },
  ],
};

// --- Test helpers ---

function makeFetchMock(ok, status, data) {
  return vi.fn().mockResolvedValueOnce({
    ok,
    status,
    statusText: ok ? 'OK' : `Error ${status}`,
    json: async () => data,
  });
}

// --- Tests ---

describe('fetchNodeData', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    // Suppress expected error logs from appearing in test output
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    // Prevent AbortSignal.timeout from actually firing during tests
    vi.spyOn(AbortSignal, 'timeout').mockReturnValue(new AbortController().signal);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('returns parsed JSON when the response is successful', async () => {
    globalThis.fetch = makeFetchMock(true, 200, VALID_DATA);

    const result = await fetchNodeData();

    expect(result).toEqual(VALID_DATA);
  });

  it('calls fetch with the correct URL', async () => {
    globalThis.fetch = makeFetchMock(true, 200, VALID_DATA);

    await fetchNodeData();

    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/info',
      expect.objectContaining({ method: 'GET' })
    );
  });

  it('sends the correct Accept header', async () => {
    globalThis.fetch = makeFetchMock(true, 200, VALID_DATA);

    await fetchNodeData();

    expect(globalThis.fetch).toHaveBeenCalledWith(
      '/info',
      expect.objectContaining({
        headers: expect.objectContaining({ Accept: 'application/json' }),
      })
    );
  });

  it('returns null when the response status is 404', async () => {
    globalThis.fetch = makeFetchMock(false, 404, null);

    const result = await fetchNodeData();

    expect(result).toBeNull();
    expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('404'));
  });

  it('returns null when the response status is 500', async () => {
    globalThis.fetch = makeFetchMock(false, 500, null);

    const result = await fetchNodeData();

    expect(result).toBeNull();
    expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('500'));
  });

  it('returns null on a network error', async () => {
    globalThis.fetch = vi.fn().mockRejectedValueOnce(new Error('Network failure'));

    const result = await fetchNodeData();

    expect(result).toBeNull();
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      expect.stringContaining('Fetch failed'),
      'Network failure'
    );
  });

  it('returns null on a timeout (TimeoutError)', async () => {
    const timeoutErr = new DOMException('The operation timed out.', 'TimeoutError');
    globalThis.fetch = vi.fn().mockRejectedValueOnce(timeoutErr);

    const result = await fetchNodeData();

    expect(result).toBeNull();
    expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('timed out'));
  });

  it('returns null when fetch rejects with an AbortError', async () => {
    const abortErr = new DOMException('Aborted', 'AbortError');
    globalThis.fetch = vi.fn().mockRejectedValueOnce(abortErr);

    const result = await fetchNodeData();

    expect(result).toBeNull();
  });

  it('handles an empty peerlist without throwing', async () => {
    const dataWithEmptyPeers = { ...VALID_DATA, peerlist: [] };
    globalThis.fetch = makeFetchMock(true, 200, dataWithEmptyPeers);

    const result = await fetchNodeData();

    expect(result).not.toBeNull();
    expect(result.peerlist).toEqual([]);
  });
});
