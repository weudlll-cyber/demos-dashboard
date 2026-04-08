# Contributing

Thank you for taking the time to improve DEMOS Dashboard!

---

## Prerequisites

| Tool    | Version |
|---------|---------|
| Node.js | ≥ 18    |
| npm     | ≥ 9     |

---

## Development Workflow

1. **Fork** the repository and create a feature branch:

   ```bash
   git checkout -b feat/my-feature    # new feature
   git checkout -b fix/my-bug         # bug fix
   git checkout -b chore/my-task      # maintenance / refactor
   git checkout -b docs/update-guide  # documentation
   ```

2. **Install dependencies:**

   ```bash
   npm install
   ```

3. **Make your changes.** Add or update tests whenever behaviour changes.

4. **Run the quality gate before committing:**

   ```bash
   npm test        # all tests must pass
   npm run build   # build must succeed
   ```

5. **Commit** using [Conventional Commits](https://www.conventionalcommits.org/):

   ```
   feat: add block time display to SyncStatus
   fix: handle missing peerlist gracefully
   docs: update VPS setup guide for Ubuntu 24
   test: add timeout edge case to api.test.js
   chore: upgrade vitest to v2
   ```

6. **Open a Pull Request** targeting `main`. The CI will run tests and a production build automatically.

---

## Adding a New Component

1. Create `src/components/MyComponent.svelte`
2. Write tests in `src/components/MyComponent.test.js`
3. Import and use it in `App.svelte`
4. Update `README.md` if the UI changes visibly
5. Add an entry to `CHANGELOG.md` under `[Unreleased]`

---

## Code Style

- **JavaScript** — ES modules (`import`/`export`), no semicolons inside Svelte `<script>` blocks
- **CSS** — use CSS variables from `styles.css`; no inline styles; no external UI frameworks
- **Naming** — `camelCase` for JS identifiers, `kebab-case` for CSS class names
- **Tests** — one `describe` block per file, `it('does X when Y')` naming

---

## Reporting Issues

Please open a GitHub Issue and include:

- What you expected to happen
- What actually happened
- Node.js and npm versions (`node -v && npm -v`)
- Any relevant console errors
