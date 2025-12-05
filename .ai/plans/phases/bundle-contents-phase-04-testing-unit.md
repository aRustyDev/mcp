---
id: 0b9c78f2-4273-4522-a4db-7a172e80481c
title: "Phase 04: Testing - Unit"
status: pending
depends_on:
  - e813a7bc-3a3e-4171-94c8-6bf0b363eb62  # phase-03
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 04: Testing - Unit

## 1. Current State Assessment

- [ ] Check for existing test workflows
- [ ] Review test frameworks used per language
- [ ] Identify coverage collection methods
- [ ] Check for test configuration files

### Existing Assets

None - test workflows not yet created.

### Gaps Identified

- [ ] Rust unit tests (cargo test, nextest)
- [ ] Python unit tests (pytest)
- [ ] JavaScript unit tests (jest/vitest)
- [ ] TypeScript unit tests (jest/vitest)
- [ ] Container structure tests
- [ ] mdBook link/spell tests

---

## 2. Contextual Goal

Create unit test workflows for all supported languages with coverage collection. Each workflow should run tests in parallel where possible, generate coverage reports compatible with Codecov, and provide clear failure messages. Use modern test runners (nextest for Rust, vitest for TS) for better performance and output.

### Success Criteria

- [ ] All unit test workflows created
- [ ] Coverage reports generated in lcov format
- [ ] Test results clearly visible in PR checks
- [ ] Parallel test execution where supported
- [ ] Appropriate timeout limits set

### Out of Scope

- Coverage reporting to Codecov (Phase 09)
- Integration tests (Phase 06)
- E2E tests (Phase 07)

---

## 3. Implementation

### 3.1 test-rust.yml

```yaml
# Framework: cargo test + cargo-nextest
# Coverage: cargo-llvm-cov
# Features:
#   - Matrix across stable/beta/nightly
#   - nextest for parallel execution
#   - Coverage in lcov format
#   - Doc tests included
```

### 3.2 test-python.yml

```yaml
# Framework: pytest
# Coverage: coverage.py / pytest-cov
# Features:
#   - Matrix across Python versions
#   - pytest-xdist for parallel
#   - Coverage in lcov/xml format
#   - JUnit XML for test results
```

### 3.3 test-javascript.yml

```yaml
# Framework: jest or vitest (auto-detect)
# Coverage: c8 / istanbul
# Features:
#   - Matrix across Node versions
#   - Coverage in lcov format
#   - JUnit XML for test results
```

### 3.4 test-typescript.yml

```yaml
# Framework: vitest (preferred) or jest
# Coverage: c8 / istanbul
# Features:
#   - Type checking before tests
#   - Coverage in lcov format
#   - Source maps for accurate coverage
```

### 3.5 test-container.yml

```yaml
# Framework: container-structure-test
# Features:
#   - Validate container structure
#   - Check for expected files/commands
#   - Verify metadata labels
```

### 3.6 test-mdbook.yml

```yaml
# Tools:
#   - mdbook-linkcheck for broken links
#   - aspell or cspell for spell check
```

---

## 4. Review & Validation

- [ ] All workflows pass `actionlint`
- [ ] Tests execute and pass on sample code
- [ ] Coverage reports are generated
- [ ] Parallel execution provides speedup
- [ ] Timeouts are appropriate
- [ ] Implementation tracking checklist updated
