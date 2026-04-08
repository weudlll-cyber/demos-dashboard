# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please **do not open a public GitHub issue**.

Instead, report it privately:

1. Go to the [Security Advisories](https://github.com/weudlll-cyber/demos-dashboard/security/advisories) tab
2. Click **"Report a vulnerability"**
3. Describe the issue, steps to reproduce, and potential impact

You will receive a response within **48 hours**.

---

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅ Yes    |

---

## Security Architecture

### Production

- Static files served by nginx from `/var/www/demos-dashboard/`
- No server-side code runs in production; the dashboard is a pure client-side SPA
- All node data is fetched from `localhost:53550` — the API is never exposed to the internet
- No user input is processed or stored

### nginx Security Headers (see `scripts/nginx.conf`)

| Header | Value | Purpose |
|--------|-------|---------|
| `Content-Security-Policy` | `default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'` | Blocks XSS, clickjacking, and data injection |
| `X-Content-Type-Options` | `nosniff` | Prevents MIME-sniffing attacks |
| `X-Frame-Options` | `DENY` | Legacy clickjacking protection |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Limits referrer leakage |
| `Permissions-Policy` | (all APIs disabled) | Blocks access to camera, GPS, mic, etc. |
| `server_tokens` | `off` | Hides nginx version from scanners |

After enabling HTTPS with Let's Encrypt, add:
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

---

## Automated Security Checks (CI)

Every push and pull request runs:

| Check | Tool | Threshold |
|-------|------|-----------|
| Dependency vulnerabilities | `npm audit` | Fails on HIGH or CRITICAL |
| Structured audit report | `audit-ci` | Fails on HIGH or CRITICAL |
| Secrets scanning | `gitleaks` | Fails on any detected secret |
| Source security analysis | `eslint-plugin-security` | Fails on eval, ReDoS, prototype injection |

---

## Known Accepted Vulnerabilities

The following **moderate-severity** advisories are present in development-only dependencies.
They are **explicitly accepted** because they only affect `npm run dev` (local development)
or Svelte SSR (which this project does not use). They are **not present in the production build**.

| Advisory | Package | Reason accepted |
|----------|---------|----------------|
| [GHSA-67mh-4wv8-2f99](https://github.com/advisories/GHSA-67mh-4wv8-2f99) | esbuild | Affects Vite dev server only. Fix requires upgrading to Vite 8 (breaking change). Not exploitable in production. |
| [GHSA-4w7w-66w2-5vf9](https://github.com/advisories/GHSA-4w7w-66w2-5vf9) | vite | Path traversal in `.map` serving. Dev server only; not present in nginx-served prod build. |
| [GHSA-crpf-4hrx-3jrp](https://github.com/advisories/GHSA-crpf-4hrx-3jrp) | svelte | SSR prototype chain issue. This project uses client-side rendering only (no SSR). |
| [GHSA-m56q-vw4c-c2cp](https://github.com/advisories/GHSA-m56q-vw4c-c2cp) | svelte | SSR invalid element tag issue. No SSR used. |
| [GHSA-f7gr-6p89-r883](https://github.com/advisories/GHSA-f7gr-6p89-r883) | svelte | SSR XSS via spread attributes. No SSR used. |
| [GHSA-phwv-c562-gvmh](https://github.com/advisories/GHSA-phwv-c562-gvmh) | svelte | SSR XSS via contenteditable. No SSR used. |

These are tracked in `audit-ci.json`. Any **new** HIGH or CRITICAL finding will still break CI immediately.

To fully resolve the Svelte and Vite findings, migrate to Svelte 5 + Vite 8 — tracked as a future improvement.
