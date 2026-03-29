---
id: 9837e690-439f-42cb-811f-dbcff58a6af9
title: "Phase 17: Security - Secrets"
status: pending
depends_on:
  - 4690fa44-71ef-4f5d-84f4-943c8c50a34b  # phase-16
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 17: Security - Secrets

## 1. Current State Assessment

- [ ] Check for existing secret scanning
- [ ] Review pre-commit hooks for secrets
- [ ] Identify secret patterns to detect
- [ ] Check for GitHub secret scanning

### Existing Assets

GitHub built-in secret scanning (if enabled on repo).

### Gaps Identified

- [ ] secret-scan-precommit.yml (Gitleaks hook)
- [ ] secret-scan-ci.yml (TruffleHog PR gate)
- [ ] secret-scan-audit.yml (GitGuardian audit)
- [ ] .gitleaks.toml configuration
- [ ] Pre-commit hook configuration

---

## 2. Contextual Goal

Implement defense-in-depth secret scanning with three layers: Gitleaks at pre-commit to catch secrets before commit, TruffleHog in CI to block PRs with secrets, and GitGuardian for post-approval audit and historical scanning. Configure custom patterns for organization-specific secret formats.

### Success Criteria

- [ ] Pre-commit hook catches secrets locally
- [ ] CI gate blocks PRs with secrets
- [ ] Audit scanning runs on schedule
- [ ] Custom patterns for org secrets configured
- [ ] False positives minimized with allowlist

### Out of Scope

- Secret rotation (operations task)
- Vault integration (deployment config)

---

## 3. Implementation

### 3.1 Defense-in-Depth Layers

| Layer | Tool | When | Purpose |
|-------|------|------|---------|
| 1 | Gitleaks | Pre-commit | Block before commit |
| 2 | TruffleHog | PR gate | Block before merge |
| 3 | GitGuardian | Scheduled | Historical audit |

### 3.2 secret-scan-precommit.yml

```yaml
name: Pre-commit Secret Scan

on:
  pull_request:

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3.3 secret-scan-ci.yml

```yaml
name: Secret Scan CI

on:
  pull_request:

jobs:
  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: TruffleHog
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified
```

### 3.4 .gitleaks.toml

```toml
[extend]
useDefault = true

[[rules]]
id = "org-api-key"
description = "Organization API Key"
regex = '''org_[a-zA-Z0-9]{32}'''
secretGroup = 0

[allowlist]
paths = [
  '''\.gitleaks\.toml$''',
  '''test/.*fixtures.*''',
]
```

### 3.5 Pre-commit Hook

```yaml
# .pre-commit-config.yaml addition
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

---

## 4. Review & Validation

- [ ] Pre-commit hook blocks test secrets
- [ ] CI gate detects secrets in PRs
- [ ] Audit runs on schedule
- [ ] Allowlist prevents false positives
- [ ] Implementation tracking checklist updated
