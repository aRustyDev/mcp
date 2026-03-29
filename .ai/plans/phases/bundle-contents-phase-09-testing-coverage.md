---
id: f074da4e-abd9-476f-8e6c-a5cfc970d37c
title: "Phase 09: Testing - Coverage"
status: pending
depends_on:
  - 8c8e095d-23b8-4ff4-8da7-b2bddd233181  # phase-08
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 09: Testing - Coverage

## 1. Current State Assessment

- [ ] Check for existing coverage collection
- [ ] Review Codecov/Coveralls integration
- [ ] Identify coverage gaps in test workflows
- [ ] Check for coverage configuration files

### Existing Assets

Unit test workflows exist but coverage not uploaded.

### Gaps Identified

- [ ] Unified coverage workflow
- [ ] Codecov configuration
- [ ] Coverage merge across languages
- [ ] Documentation coverage

---

## 2. Contextual Goal

Establish comprehensive code coverage reporting that aggregates results from all test workflows. Coverage reports should be uploaded to Codecov for tracking trends, with PR comments showing coverage changes. Include line, branch, and function coverage metrics, with documentation coverage for public APIs.

### Success Criteria

- [ ] Coverage workflow collecting from all languages
- [ ] Codecov integration with PR comments
- [ ] Coverage trends visible over time
- [ ] Documentation coverage tracked
- [ ] Coverage badge for README

### Out of Scope

- Quality gates based on coverage (Phase 10)
- Mutation testing (separate concern)

---

## 3. Implementation

### 3.1 coverage.yml

```yaml
name: Coverage

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

jobs:
  rust-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@stable
        with:
          components: llvm-tools-preview

      - uses: Swatinem/rust-cache@v2

      - name: Install cargo-llvm-cov
        uses: taiki-e/install-action@cargo-llvm-cov

      - name: Collect coverage
        run: cargo llvm-cov --all-features --lcov --output-path lcov.info

      - name: Upload to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: lcov.info
          flags: rust
          token: ${{ secrets.CODECOV_TOKEN }}

  python-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'

      - run: pip install pytest coverage

      - name: Collect coverage
        run: |
          coverage run -m pytest
          coverage lcov -o coverage.lcov

      - name: Upload to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: coverage.lcov
          flags: python
          token: ${{ secrets.CODECOV_TOKEN }}

  typescript-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Collect coverage
        run: npm run test:coverage

      - name: Upload to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
          flags: typescript
          token: ${{ secrets.CODECOV_TOKEN }}
```

### 3.2 codecov.yml

```yaml
# configs/codecov.yml
coverage:
  status:
    project:
      default:
        target: auto
        threshold: 1%
    patch:
      default:
        target: 80%

comment:
  layout: "reach,diff,flags,files"
  behavior: default
  require_changes: true

flags:
  rust:
    paths:
      - src/
    carryforward: true
  python:
    paths:
      - "**/*.py"
    carryforward: true
  typescript:
    paths:
      - "**/*.ts"
    carryforward: true
```

### 3.3 Documentation Coverage

- **Rust**: `cargo doc --document-private-items`
- **Python**: `interrogate` for docstring coverage
- **TypeScript**: `typedoc` coverage report

---

## 4. Review & Validation

- [ ] All languages upload coverage
- [ ] Codecov comments appear on PRs
- [ ] Coverage trends visible in dashboard
- [ ] Flags correctly separate languages
- [ ] Implementation tracking checklist updated
