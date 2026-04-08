/**
 * @file api.js
 * @project DEMOS Node Dashboard
 * @repository https://github.com/weudlll-cyber/demos-dashboard
 *
 * @description
 *   API client layer. Provides a single exported function, fetchNodeData(),
 *   that retrieves the current state of a DEMOS blockchain node from the
 *   local REST endpoint.  All error handling is centralised here so that
 *   callers (App.svelte) never need to deal with raw exceptions.
 *
 * @api
 *   GET /info  →  { version, version_name, identity, connectionString, peerlist[] }
 *
 * @exports
 *   fetchNodeData(): Promise<object|null>
 *
 * @security
 *   - Uses AbortSignal.timeout() to enforce a hard 5 second deadline.
 *   - Does NOT construct URL from user-supplied input.
 *   - Vite dev proxy handles CORS in development; production goes through nginx.
 *
 * @author  weudlll-cyber
 * @license MIT
 */

// Development proxy maps this path to http://localhost:53550/info (see vite.config.js).
// In production the nginx reverse-proxy or the node must be on the same origin.
const NODE_API_URL = '/info';

/**
 * Fetches the current node data from the DEMOS node REST API.
 *
 * Behaviour on failure:
 *   - HTTP 4xx / 5xx   → logs the status code, returns null
 *   - Network error    → logs the message, returns null
 *   - Request timeout  → logs "timed out", returns null
 *
 * Callers receive null on any failure so they can show an error state
 * without crashing the UI.
 *
 * @returns {Promise<object|null>} Parsed JSON response, or null on any error.
 */
export async function fetchNodeData() {
  try {
    const response = await fetch(NODE_API_URL, {
      method: 'GET',
      // Tells the node we only accept JSON — guards against HTML error pages
      // being silently parsed as valid data.
      headers: { Accept: 'application/json' },
      // Hard deadline: prevents a stalled node from blocking the UI indefinitely.
      signal: AbortSignal.timeout(5000),
    });

    // Non-2xx responses are not thrown automatically — check explicitly.
    if (!response.ok) {
      console.error(`[api] HTTP ${response.status}: ${response.statusText}`);
      return null;
    }

    const data = await response.json();
    return data;
  } catch (err) {
    // AbortSignal.timeout() throws a DOMException with name 'TimeoutError'.
    if (err.name === 'TimeoutError') {
      console.error('[api] Request timed out after 5s');
    } else {
      // Covers network failures, DNS errors, aborts, JSON parse errors.
      console.error('[api] Fetch failed:', err.message);
    }
    return null;
  }
}
