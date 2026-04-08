# DEMOS Node Dashboard

A real-time monitoring dashboard for a DEMOS blockchain node, built with **Svelte 4** and **Vite**.

[![CI](https://github.com/your-username/demos-dashboard/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/demos-dashboard/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Replace `your-username`** in the badge URLs above and in the install instructions with your actual GitHub username once the repo is created.

---

## Features

- **Live polling** — data refreshes every 3 seconds, no page reload needed
- **Node Info card** — version, version name, identity, connection string
- **Sync Status card** — block height, block hash, online / ready / verified indicators
- **Peer List table** — all connected peers with full status fields
- **Error state** — graceful fallback when the node is unreachable
- **Dark theme** — modern UI with CSS variables, no external UI frameworks
- **Responsive** — works on desktop, tablet, and mobile

---

## Prerequisites

| Tool    | Version  | Install                              |
|---------|----------|--------------------------------------|
| Node.js | ≥ 18     | https://nodejs.org or `nvm`          |
| npm     | ≥ 9      | bundled with Node.js                 |

---

## Quick Start (local development)

```bash
git clone https://github.com/your-username/demos-dashboard.git
cd demos-dashboard
npm install
npm run dev
```

Open **http://localhost:5173**.

The dev server automatically proxies `/api` → `http://localhost:53550`, so no CORS issues during development. The DEMOS node must be running locally. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for how to mock the API when no live node is available.

---

## Running Tests

```bash
npm test            # run all tests once
npm run test:watch  # re-run on file changes
```

Tests use **Vitest** + **happy-dom** + **@testing-library/svelte**. No browser required.

---

## Build for Production

```bash
npm run build     # outputs compiled files to dist/
npm run preview   # serve the production build locally at http://localhost:4173
```

---

## VPS Deployment

See **[docs/VPS_SETUP.md](docs/VPS_SETUP.md)** for the full step-by-step guide.

**Quick path** — once the repo is cloned on your VPS:

```bash
# First-time install
bash scripts/install.sh

# After any update
bash scripts/update.sh
```

The installer handles Node.js, nginx, building, and deploying automatically.

---

## Project Structure

```
demos-dashboard/
├── .github/
│   └── workflows/
│       └── ci.yml                   # GitHub Actions CI (test + build on every push/PR)
├── docs/
│   ├── VPS_SETUP.md                 # Full VPS deployment guide
│   └── DEVELOPMENT.md               # Local development guide & API mocking
├── scripts/
│   ├── install.sh                   # VPS first-time installer
│   ├── update.sh                    # VPS updater (pull → build → deploy)
│   ├── nginx.conf                   # Nginx config template
│   └── demos-dashboard.service      # Systemd unit file (optional vite preview service)
├── src/
│   ├── api.js                       # fetchNodeData() with error handling & timeout
│   ├── api.test.js                  # Unit tests for the API module
│   ├── App.svelte                   # Root component, polling logic
│   ├── main.js                      # Svelte entry point
│   ├── styles.css                   # Global dark theme, card grid, pills
│   ├── test-setup.js                # Vitest global setup
│   └── components/
│       ├── NodeInfo.svelte
│       ├── NodeInfo.test.js         # Component tests for NodeInfo
│       ├── SyncStatus.svelte
│       └── PeerList.svelte
├── index.html
├── package.json
├── vite.config.js
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[MIT](LICENSE) © 2026
