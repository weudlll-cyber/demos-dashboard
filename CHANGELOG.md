# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-04-09

### Added

- Initial release of DEMOS Node Dashboard
- Live polling every 3 seconds via `fetchNodeData()` in `api.js`
- `NodeInfo` component: version, version name, identity, connection string
- `SyncStatus` component: block height, block hash, online / ready / verified status pills
- `PeerList` component: full peer table with all status fields per peer
- Dark theme with CSS variables, card grid layout, responsive breakpoints
- Error state: graceful "Cannot reach node" screen with auto-retry
- VPS installer script (`scripts/install.sh`) for Ubuntu 22.04 / 24.04
- VPS updater script (`scripts/update.sh`) for one-command redeploys
- Nginx config template (`scripts/nginx.conf`) with security headers and gzip
- Systemd service unit file (`scripts/demos-dashboard.service`) for optional `vite preview` deployment
- Unit tests for `api.js` covering success, 404, 500, network error, and timeout (Vitest)
- Component tests for `NodeInfo` component (@testing-library/svelte)
- GitHub Actions CI workflow: test + build on every push and pull request to `main`
- `docs/VPS_SETUP.md`: full VPS setup guide including HTTPS with Let's Encrypt
- `docs/DEVELOPMENT.md`: local dev guide, API mocking, file overview
