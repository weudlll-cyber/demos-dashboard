# Development Guide

Everything you need to work on DEMOS Dashboard locally.

---

## Prerequisites

| Tool    | Version | Install                                     |
|---------|---------|---------------------------------------------|
| Node.js | ≥ 18    | https://nodejs.org or `nvm install 20`      |
| npm     | ≥ 9     | bundled with Node.js                        |

---

## Setup

```bash
git clone https://github.com/weudlll-cyber/demos-dashboard.git
cd demos-dashboard
npm install
```

---

## Running the Dev Server

```bash
npm run dev
```

Opens at **http://localhost:5173**.

The Vite dev server proxies all `/api` requests to `http://localhost:53550`, so there are no CORS issues and you can point your browser at the dev server while the DEMOS node runs on the same machine.

---

## Running Without a Live Node (API Mocking)

If you don't have a DEMOS node running locally, you can temporarily replace `fetchNodeData` in `src/api.js` with a stub that returns fixture data:

```js
// Temporary stub — do not commit to main
export async function fetchNodeData() {
  return {
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
}
```

Revert this before committing.

---

## Running Tests

```bash
npm test            # run all tests once (also what CI runs)
npm run test:watch  # re-run tests automatically on file changes
```

**Test stack:**

| Library                    | Role                                      |
|----------------------------|-------------------------------------------|
| Vitest                     | Test runner, assertion library            |
| happy-dom                  | Lightweight DOM environment (no browser)  |
| @testing-library/svelte    | Renders Svelte components in tests        |
| @testing-library/jest-dom  | Extra DOM matchers (`toBeInTheDocument`)  |

Test files live next to the code they test:

```
src/api.js              ← src/api.test.js
src/components/NodeInfo.svelte  ← src/components/NodeInfo.test.js
```

---

## Building for Production

```bash
npm run build     # compiles everything into dist/
npm run preview   # serve the production build at http://localhost:4173
```

The `dist/` folder contains static files ready to be served by nginx or any static host.

---

## File Overview

| File | Purpose |
|------|---------|
| `src/api.js` | `fetchNodeData()` — fetches `/api`, returns parsed JSON or `null` on any error |
| `src/App.svelte` | Root component; initialises polling on `onMount`, tears down on `onDestroy` |
| `src/components/NodeInfo.svelte` | Shows node version, version name, identity, connection string |
| `src/components/SyncStatus.svelte` | Shows block height, hash, and status pills for the first peer |
| `src/components/PeerList.svelte` | Full table of all peers with all status fields |
| `src/styles.css` | Global dark theme, CSS variables, `.card`, `.grid`, `.pill` classes |
| `src/main.js` | Svelte entry point, mounts `App` into `#app` |
| `vite.config.js` | Vite + Svelte plugin, dev proxy, Vitest config |
| `scripts/install.sh` | VPS first-time installer |
| `scripts/update.sh` | VPS updater (pull → build → deploy → reload nginx) |
| `scripts/nginx.conf` | Nginx config template with security headers and gzip |
| `scripts/demos-dashboard.service` | Optional systemd unit for `vite preview` |

---

## Adding a New Component

1. Create `src/components/NewComponent.svelte`
2. Accept data via `export let propName;`
3. Write a test file `src/components/NewComponent.test.js`
4. Import it in `App.svelte` and pass in the relevant slice of `data`
5. Update `README.md` if the UI changes visibly
6. Add an entry to `CHANGELOG.md` under `[Unreleased]`

---

## Polling Interval

The refresh interval is defined as a constant in `src/App.svelte`:

```js
const POLL_INTERVAL_MS = 3000;
```

Change it there if you need a different interval.
