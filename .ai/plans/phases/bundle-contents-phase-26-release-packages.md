---
id: 045fa19d-a65d-4fca-b6e0-2a813af692a8
title: "Phase 26: Release - Packages"
status: pending
depends_on:
  - b0116cbd-58d7-4a2e-8720-9d3860ad9232  # phase-25
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 26: Release - Packages

## 1. Current State Assessment

- [ ] Check for existing package publishing
- [ ] Review registry tokens configuration
- [ ] Identify package ecosystems used
- [ ] Check for dry-run testing

### Existing Assets

Build workflows (Phase 02) create publishable artifacts.

### Gaps Identified

- [ ] publish-rust.yml (crates.io)
- [ ] publish-python.yml (PyPI)
- [ ] publish-node.yml (npm)
- [ ] deploy-docs.yml (documentation)

---

## 2. Contextual Goal

Implement package publishing workflows for all supported ecosystems. Publish Rust crates to crates.io, Python packages to PyPI, and Node packages to npm. Include documentation deployment to GitHub Pages or Cloudflare. Ensure packages are signed and include provenance.

### Success Criteria

- [ ] crates.io publishing works
- [ ] PyPI publishing works
- [ ] npm publishing works
- [ ] Documentation deployed
- [ ] Dry-run on PRs

### Out of Scope

- Private registries
- Monorepo package coordination

---

## 3. Implementation

### 3.1 publish-rust.yml

```yaml
name: Publish to crates.io

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@stable

      - name: Publish
        run: cargo publish
        env:
          CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
```

### 3.2 publish-python.yml

```yaml
name: Publish to PyPI

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # For trusted publishing

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Build package
        run: |
          pip install build
          python -m build

      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1
```

### 3.3 publish-node.yml

```yaml
name: Publish to npm

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # For npm provenance

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          registry-url: 'https://registry.npmjs.org'

      - run: npm ci

      - run: npm publish --provenance --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### 3.4 deploy-docs.yml

```yaml
name: Deploy Documentation

on:
  release:
    types: [published]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write

    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    steps:
      - uses: actions/checkout@v4

      - name: Build docs
        run: |
          # mdBook, rustdoc, etc.

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: 'book/'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 4. Review & Validation

- [ ] crates.io publish succeeds
- [ ] PyPI publish succeeds
- [ ] npm publish succeeds
- [ ] Documentation deploys
- [ ] Implementation tracking checklist updated
