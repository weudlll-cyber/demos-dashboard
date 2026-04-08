/**
 * api.js — DEMOS Node API client
 * Fetches node data from the local node endpoint.
 */

const NODE_API_URL = '/api';

/**
 * Fetches the current node data from the DEMOS node API.
 * Returns the parsed JSON object on success, or null on failure.
 *
 * @returns {Promise<object|null>}
 */
export async function fetchNodeData() {
  try {
    const response = await fetch(NODE_API_URL, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) {
      console.error(`[api] HTTP ${response.status}: ${response.statusText}`);
      return null;
    }

    const data = await response.json();
    return data;
  } catch (err) {
    if (err.name === 'TimeoutError') {
      console.error('[api] Request timed out after 5s');
    } else {
      console.error('[api] Fetch failed:', err.message);
    }
    return null;
  }
}
