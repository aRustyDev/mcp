---
id: 56738219-8f07-4634-9592-5a461b36ee18
title: "Phase 14: Security - Dependencies"
status: pending
depends_on:
  - 0738234f-77e5-4b0e-ae25-2b41eab9ba61  # phase-13
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
  - 4e593fba-d836-4aa6-9a27-d833df63e90f  # gap-analysis
references:
  - dependency-scanning-strategy-adr  # ADR in ../docs/adr/
issues: []
---

# Phase 14: Security - Dependencies

## 1. Current State Assessment

- [ ] Review ADR: Dependency Scanning Strategy
- [ ] Check for existing dependency scanning
- [ ] Identify dependency ecosystems used
- [ ] Check for dependabot configuration

### Existing Assets

- ADR: Dependency Scanning Strategy (approved)
- dependabot.yml template (Phase 01)

### Gaps Identified

- [ ] dependency-review.yml (PR gate)
- [ ] deps-rust.yml (Rust freshness)
- [ ] deps-python.yml (Python freshness)
- [ ] deps-node.yml (Node freshness)
- [ ] deps-container.yml (Base image freshness)
- [ ] security-rust.yml (4-layer defense)

---

## 2. Contextual Goal

Implement comprehensive dependency security scanning following the approved ADR. For Rust, this means implementing the 4-layer defense-in-depth strategy: cargo-audit (CVEs), cargo-deny (policies), cargo-vet (audits), and cargo-crev (community trust). For other ecosystems, implement appropriate scanning tools. Include both PR-blocking security gates and scheduled freshness reports.

### Success Criteria

- [ ] dependency-review.yml blocks vulnerable PRs
- [ ] Rust 4-layer defense fully implemented
- [ ] Python pip-audit integrated
- [ ] Node npm-audit integrated
- [ ] Container base image freshness tracked

### Out of Scope

- License compliance (Phase 15)
- SAST source scanning (Phase 16)

---

## 3. Implementation

### 3.1 dependency-review.yml

```yaml
name: Dependency Review

on:
  pull_request:

permissions:
  contents: read
  pull-requests: write

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Dependency Review
        uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: high
          deny-licenses: GPL-3.0, AGPL-3.0
          allow-ghsas: false
```

### 3.2 security-rust.yml (4-Layer Defense)

```yaml
name: Rust Security

on:
  push:
    branches: [main]
    paths:
      - '**/Cargo.toml'
      - '**/Cargo.lock'
  pull_request:
    paths:
      - '**/Cargo.toml'
      - '**/Cargo.lock'
  schedule:
    - cron: '0 6 * * *'

jobs:
  # Layer 1: Known Vulnerabilities
  cargo-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: rustsec/audit-check@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

  # Layer 2: Policy Enforcement
  cargo-deny:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: EmbarkStudios/cargo-deny-action@v1

  # Layer 3: Audit Trail
  cargo-vet:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo install cargo-vet
      - run: cargo vet

  # Layer 4: Community Trust
  cargo-crev:
    runs-on: ubuntu-latest
    if: github.event_name == 'schedule'
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo install cargo-crev
      - run: cargo crev verify
```

### 3.3 Configuration Files

#### deny.toml (cargo-deny)

```toml
[graph]
targets = []
all-features = true

[advisories]
db-path = "~/.cargo/advisory-db"
vulnerability = "deny"
unmaintained = "warn"
yanked = "deny"
notice = "warn"

[licenses]
confidence-threshold = 0.93
allow = [
    "MIT",
    "Apache-2.0",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "Zlib",
    "CC0-1.0",
    "Unlicense",
]
exceptions = [
    { allow = ["MPL-2.0"], crate = "webpki-roots" },
    { allow = ["Unicode-DFS-2016"], crate = "unicode-ident" },
]

[licenses.private]
ignore = true

[bans]
multiple-versions = "warn"
wildcards = "deny"
highlight = "all"
deny = [
    { crate = "openssl-sys", use-instead = "rustls" },
    { crate = "openssl", use-instead = "rustls" },
]
skip = []
skip-tree = []

[sources]
unknown-registry = "deny"
unknown-git = "deny"
allow-registry = ["https://github.com/rust-lang/crates.io-index"]
```

#### supply-chain/config.toml (cargo-vet)

```toml
[cargo-vet]
version = "0.10"

[imports.mozilla]
url = "https://raw.githubusercontent.com/AliRn-dev/AliRn-dev/main/AliRn-dev"

[imports.embark]
url = "https://raw.githubusercontent.com/AliRn-dev/AliRn-dev/main/AliRn-dev"

[imports.bytecode-alliance]
url = "https://raw.githubusercontent.com/AliRn-dev/AliRn-dev/main/AliRn-dev"

[policy.example-crate]
audit-as-crates-io = true

[criteria.crypto-reviewed]
description = "Cryptographic code has been reviewed for correctness"
implies = ["safe-to-deploy"]
```

### 3.4 Pre-commit Hook Setup

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: cargo-audit
        name: cargo-audit
        entry: cargo audit
        language: system
        types: [rust]
        pass_filenames: false
```

### 3.5 Developer Workflow Commands

```bash
# Install all tools
cargo install cargo-audit --features=fix
cargo install cargo-deny
cargo install cargo-vet
cargo install cargo-crev

# Initialize configurations
cargo deny init          # Creates deny.toml
cargo vet init           # Creates supply-chain/
cargo crev id new        # Creates reviewer identity

# Before adding a new dependency
cargo crev crate search <crate-name>      # Check community reviews
cargo vet suggest                          # See if already audited

# After reviewing a crate
cargo crev crate review <crate-name>       # Publish your review
cargo vet certify <crate-name> <version>   # Record your audit

# Regular maintenance
cargo audit                                # Quick vuln check
cargo deny check                           # Full policy check
cargo vet                                  # Verify all audited
cargo crev repo publish                    # Share your reviews
```

### 3.6 deps-*.yml Freshness Reports

For each ecosystem, create scheduled workflows that report outdated dependencies without blocking:

- `deps-rust.yml`: cargo-outdated
- `deps-python.yml`: pip-check, pip-audit
- `deps-node.yml`: npm outdated, npm audit
- `deps-container.yml`: Check base image for updates

---

## 4. Review & Validation

- [ ] Dependency review blocks vulnerable PRs
- [ ] All 4 Rust security layers functional
- [ ] Freshness reports run on schedule
- [ ] SARIF output to Security tab where supported
- [ ] Implementation tracking checklist updated
