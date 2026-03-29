---
id: 63b65361-73ac-48b5-a614-931d6cb36022
title: "Phase 05: Testing - Property-Based"
status: pending
depends_on:
  - 0b9c78f2-4273-4522-a4db-7a172e80481c  # phase-04
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 05: Testing - Property-Based

## 1. Current State Assessment

- [ ] Check for existing property-based test setups
- [ ] Review proptest/hypothesis usage in projects
- [ ] Identify shrinking and seed management

### Existing Assets

None - property testing not yet configured.

### Gaps Identified

- [ ] Rust property tests (proptest)
- [ ] Python property tests (Hypothesis)
- [ ] TypeScript property tests (fast-check)

---

## 2. Contextual Goal

Add property-based testing capabilities to discover edge cases that unit tests miss. Property-based tests generate random inputs based on specifications and verify invariants hold. Failed cases are automatically shrunk to minimal reproducible examples. This complements unit testing by exploring the input space more thoroughly.

### Success Criteria

- [ ] Property test workflow created
- [ ] Supports Rust (proptest), Python (Hypothesis), TypeScript (fast-check)
- [ ] Seed values logged for reproduction
- [ ] Shrunk failing cases reported clearly
- [ ] Reasonable iteration counts (default 100-1000)

### Out of Scope

- Fuzzing (Phase 19) - different purpose, longer running
- Integration property tests

---

## 3. Implementation

### 3.1 test-property.yml

```yaml
name: Property Tests

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 6 * * 1'  # Weekly deep run
  workflow_dispatch:
    inputs:
      iterations:
        description: 'Number of test cases'
        default: '1000'

jobs:
  rust-property:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - name: Run proptest
        env:
          PROPTEST_CASES: ${{ inputs.iterations || '256' }}
        run: cargo test --features proptest

  python-property:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - run: pip install hypothesis pytest
      - name: Run Hypothesis
        env:
          HYPOTHESIS_PROFILE: ${{ github.event_name == 'schedule' && 'ci-extended' || 'ci' }}
        run: pytest -v --hypothesis-show-statistics

  typescript-property:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - name: Run fast-check
        run: npm run test:property
```

### 3.2 Configuration Files

**conftest.py** (Hypothesis profiles):
```python
from hypothesis import settings, Verbosity

settings.register_profile("ci", max_examples=100)
settings.register_profile("ci-extended", max_examples=1000)
settings.load_profile("ci")
```

**proptest.toml**:
```toml
[proptest]
cases = 256
max_shrink_iters = 10000
```

---

## 4. Review & Validation

- [ ] All property tests run successfully
- [ ] Seed values are logged
- [ ] Shrinking produces minimal examples
- [ ] Weekly extended runs complete in reasonable time
- [ ] No flaky tests due to randomness
- [ ] Implementation tracking checklist updated
