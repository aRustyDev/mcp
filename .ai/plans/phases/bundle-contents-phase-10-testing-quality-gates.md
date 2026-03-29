---
id: 903f0911-039e-4917-8605-cb0e33519d75
title: "Phase 10: Testing - Quality Gates"
status: pending
depends_on:
  - f074da4e-abd9-476f-8e6c-a5cfc970d37c  # phase-09
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 10: Testing - Quality Gates

## 1. Current State Assessment

- [ ] Check for existing quality gate enforcement
- [ ] Review coverage thresholds
- [ ] Identify blocking vs warning conditions
- [ ] Check for Code Climate integration

### Existing Assets

Coverage collection exists but no gates enforced.

### Gaps Identified

- [ ] Quality gate workflow
- [ ] Coverage threshold enforcement
- [ ] Mutation testing
- [ ] Type coverage enforcement

---

## 2. Contextual Goal

Establish quality gates that block merges when code quality drops below acceptable thresholds. This includes minimum coverage requirements, type coverage for typed languages, and optionally mutation testing to verify test effectiveness. Gates should be configurable per project with sensible defaults.

### Success Criteria

- [ ] Quality gate workflow blocks on threshold failures
- [ ] Coverage thresholds configurable (default 70%)
- [ ] Mutation testing integrated (optional)
- [ ] Type coverage checked for Python/TypeScript
- [ ] Clear failure messages for blocked PRs

### Out of Scope

- SAST (Phase 16)
- Security gates (Phase 14+)

---

## 3. Implementation

### 3.1 quality-gate.yml

```yaml
name: Quality Gates

on:
  pull_request:
  workflow_dispatch:

jobs:
  coverage-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check coverage
        uses: codecov/codecov-action@v4
        with:
          fail_ci_if_error: true
          token: ${{ secrets.CODECOV_TOKEN }}

      - name: Verify thresholds
        run: |
          # Check that coverage meets minimum
          # Exit 1 if below threshold

  mutation-testing:
    runs-on: ubuntu-latest
    if: contains(github.event.pull_request.labels.*.name, 'mutation-test')
    steps:
      - uses: actions/checkout@v4

      - name: Run cargo-mutants
        run: |
          cargo install cargo-mutants
          cargo mutants --timeout 300

      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: mutation-report
          path: mutants.out/

  type-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Python type coverage
        run: |
          pip install mypy
          mypy --html-report typecov .
          # Check coverage percentage

      - name: TypeScript type coverage
        run: |
          npx type-coverage --at-least 90
```

### 3.2 Threshold Configuration

```yaml
# .github/quality-gates.yml
coverage:
  minimum: 70
  patch_minimum: 80

mutation:
  enabled: false  # Opt-in via label
  timeout: 300

type_coverage:
  python: 80
  typescript: 90
```

### 3.3 Gate Enforcement

| Gate | Default | Blocks Merge |
|------|---------|--------------|
| Line coverage | 70% | Yes |
| Patch coverage | 80% | Yes |
| Mutation score | 60% | No (opt-in) |
| Type coverage | 80% | Warning |

---

## 4. Review & Validation

- [ ] Gates block PRs below thresholds
- [ ] Thresholds are configurable
- [ ] Mutation testing runs on demand
- [ ] Type coverage reported accurately
- [ ] Implementation tracking checklist updated
