---
id: 4690fa44-71ef-4f5d-84f4-943c8c50a34b
title: "Phase 16: Security - SAST"
status: pending
depends_on:
  - 998f42c0-584d-4dcb-8b02-07116f0f03e3  # phase-15
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - ../../docs/strategies/sast-strategy.md   # SAST tool selection and boundaries
  - ../../docs/strategies/sarif-strategy.md  # SARIF aggregation
issues: []
---

# Phase 16: Security - SAST

## 1. Current State Assessment

- [ ] Check for existing SAST configuration
- [ ] Review CodeQL setup if present
- [ ] Identify Semgrep rules in use
- [ ] Check for language-specific security lints

### Existing Assets

Clippy quality lints (Phase 03) provide style checking; security lints move here.

### Gaps Identified

- [ ] security-sast.yml (unified pattern SAST)
- [ ] security-sast-rust.yml (Rust-specific)
- [ ] security-sast-python.yml (Python-specific)
- [ ] security-sast-go.yml (Go-specific)
- [ ] MCP-specific Semgrep rules (in configs/semgrep/rules/mcp/)
- [ ] SARIF aggregation workflow
- [ ] Baseline management

---

## 2. Contextual Goal

Implement **pattern-based** static application security testing using Semgrep and language-specific tools. This phase focuses on fast, deterministic pattern matching suitable for PR checks. Deep dataflow analysis is deferred to Phase 20.

> **See**: [SAST Strategy](../../docs/strategies/sast-strategy.md) for tool selection rationale and phase boundaries.

### Success Criteria

- [ ] Unified SAST workflow with Semgrep
- [ ] Language-specific security lint workflows
- [ ] MCP-specific Semgrep rules created
- [ ] SARIF results aggregated and uploaded
- [ ] PR gate blocks on HIGH/CRITICAL findings
- [ ] False positive rate < 10%

### Out of Scope

- Dataflow/taint analysis (Phase 20)
- Memory safety analysis (Phase 18)
- Fuzzing (Phase 19)
- DAST/runtime testing

### Phase Boundary

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PHASE 16 RESPONSIBILITIES                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  IN SCOPE (Pattern-Based SAST)                                               │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✓ Semgrep security-audit ruleset                                           │
│  ✓ Semgrep custom MCP patterns                                              │
│  ✓ clippy::suspicious, clippy::correctness                                  │
│  ✓ cargo-geiger (unsafe code audit)                                         │
│  ✓ bandit (Python patterns)                                                 │
│  ✓ gosec (Go patterns)                                                      │
│  ✓ eslint-plugin-security                                                   │
│                                                                              │
│  OUT OF SCOPE (Deferred to Other Phases)                                     │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✗ CodeQL dataflow queries → Phase 20                                       │
│  ✗ Semgrep taint mode → Phase 20                                            │
│  ✗ Pysa taint tracking → Phase 20                                           │
│  ✗ Miri/sanitizers → Phase 18                                               │
│  ✗ Fuzzing → Phase 19                                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Implementation

### 3.1 security-sast.yml (Unified Pattern SAST)

```yaml
name: Pattern SAST

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 5 * * *'

jobs:
  semgrep:
    name: Semgrep Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Semgrep Scan
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            p/owasp-top-ten
            configs/semgrep/rules/mcp/
          generateSarif: true

      - name: Upload Semgrep SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-semgrep
          path: semgrep.sarif

  # Aggregate SARIF from all jobs
  aggregate:
    needs: [semgrep]
    uses: ./.github/workflows/sarif-aggregate.yml

  # Quality gate
  gate:
    needs: [aggregate]
    uses: ./.github/workflows/sarif-gate.yml
    with:
      gate_config: pr  # or 'main' for push to main
```

### 3.2 security-sast-rust.yml

```yaml
name: Rust Security SAST

on:
  push:
    branches: [main]
    paths: ['**.rs', 'Cargo.toml', 'Cargo.lock']
  pull_request:
    paths: ['**.rs', 'Cargo.toml', 'Cargo.lock']

jobs:
  clippy-security:
    name: Clippy Security Lints
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy

      - uses: Swatinem/rust-cache@v2

      - name: Clippy Security Analysis
        run: |
          cargo clippy --all-targets --all-features -- \
            -D clippy::suspicious \
            -D clippy::correctness \
            -W clippy::nursery \
            2>&1 | tee clippy-output.txt

      - name: Convert to SARIF
        run: |
          cargo install clippy-sarif sarif-fmt
          cat clippy-output.txt | clippy-sarif > clippy.sarif

      - name: Upload Clippy SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-clippy
          path: clippy.sarif

  cargo-geiger:
    name: Unsafe Code Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@stable

      - name: Install cargo-geiger
        run: cargo install cargo-geiger

      - name: Run cargo-geiger
        run: |
          cargo geiger --all-features --output-format Json > geiger.json

      - name: Check unsafe thresholds
        run: |
          # Parse geiger.json and check thresholds
          UNSAFE_COUNT=$(jq '.packages[].unsafety.used.functions.unsafe' geiger.json | grep -v null | paste -sd+ | bc)
          echo "Total unsafe functions: $UNSAFE_COUNT"

          if [ "$UNSAFE_COUNT" -gt "${UNSAFE_THRESHOLD:-10}" ]; then
            echo "::warning::Unsafe function count ($UNSAFE_COUNT) exceeds threshold"
          fi

      - name: Upload geiger report
        uses: actions/upload-artifact@v4
        with:
          name: cargo-geiger-report
          path: geiger.json
```

### 3.3 security-sast-python.yml

```yaml
name: Python Security SAST

on:
  push:
    branches: [main]
    paths: ['**.py', 'pyproject.toml', 'requirements*.txt']
  pull_request:
    paths: ['**.py', 'pyproject.toml', 'requirements*.txt']

jobs:
  bandit:
    name: Bandit Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Bandit
        run: pip install bandit[sarif]

      - name: Run Bandit
        run: |
          bandit -r . \
            --format sarif \
            --output bandit.sarif \
            --severity-level medium \
            --confidence-level medium \
            --exclude '**/tests/**,**/test_*.py' \
            || true

      - name: Upload Bandit SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-bandit
          path: bandit.sarif

  pylint-security:
    name: Pylint Security Checks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install pylint pylint-sarif

      - name: Run Pylint security checks
        run: |
          pylint --load-plugins=pylint.extensions.security \
            --disable=all \
            --enable=security \
            --output-format=sarif \
            **/*.py > pylint-security.sarif || true

      - name: Upload Pylint SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-pylint-security
          path: pylint-security.sarif
```

### 3.4 security-sast-go.yml

```yaml
name: Go Security SAST

on:
  push:
    branches: [main]
    paths: ['**.go', 'go.mod', 'go.sum']
  pull_request:
    paths: ['**.go', 'go.mod', 'go.sum']

jobs:
  gosec:
    name: gosec Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: stable

      - name: Run gosec
        uses: securego/gosec@master
        with:
          args: -fmt sarif -out gosec.sarif ./...

      - name: Upload gosec SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-gosec
          path: gosec.sarif
```

### 3.5 MCP-Specific Semgrep Rules

> **Rule Location**: `configs/semgrep/rules/mcp/`

All MCP-specific rules are centralized for maintainability. See [SAST Strategy](../../docs/strategies/sast-strategy.md) for rule organization.

#### 3.5.1 Directory Structure

```
configs/semgrep/rules/mcp/
├── mcp-all.yaml              # Aggregates all MCP rules
├── injection/
│   ├── path-traversal.yaml   # Resource URI path injection
│   ├── command-injection.yaml # Tool → subprocess flows
│   └── sql-injection.yaml    # Tool → database flows
├── protocol/
│   ├── json-rpc-validation.yaml
│   ├── capability-check.yaml
│   └── transport-security.yaml
└── README.md                 # Rule documentation
```

#### 3.5.2 injection/path-traversal.yaml

```yaml
rules:
  - id: mcp-path-traversal-resource
    message: |
      Potential path traversal in MCP resource handler.
      Resource URIs from clients must be validated before filesystem access.

      Remediation:
      - Use os.path.realpath() and verify path is within allowed directory
      - Use pathlib.Path.resolve() and check with is_relative_to()
    severity: ERROR
    languages: [python]
    metadata:
      category: security
      subcategory: path-traversal
      cwe: CWE-22
      owasp: "A01:2021"
      mcp-component: resources
      confidence: HIGH
      likelihood: HIGH
      impact: HIGH
    patterns:
      - pattern-either:
          - pattern: |
              def $FUNC($URI, ...):
                  ...
                  open($PATH, ...)
          - pattern: |
              async def $FUNC($URI, ...):
                  ...
                  open($PATH, ...)
      - pattern-not-inside: |
          if $CHECK:
              ...
      - metavariable-pattern:
          metavariable: $PATH
          pattern-either:
            - pattern: $URI
            - pattern: f"...{$URI}..."
            - pattern: $X + $URI
            - pattern: os.path.join(..., $URI, ...)

  - id: mcp-path-traversal-dotdot
    message: |
      Path contains traversal sequence '../'.
      Validate and normalize paths before use.
    severity: ERROR
    languages: [python, javascript, typescript]
    metadata:
      cwe: CWE-22
      mcp-component: resources
    pattern-regex: '\.\.\/'
```

#### 3.5.3 injection/command-injection.yaml

```yaml
rules:
  - id: mcp-command-injection-shell
    message: |
      MCP tool handler passes input to shell command.
      Never use shell=True with untrusted input.

      Remediation:
      - Use subprocess.run() with shell=False and argument list
      - Use shlex.split() for argument parsing
      - Validate input against allowlist
    severity: ERROR
    languages: [python]
    metadata:
      category: security
      subcategory: command-injection
      cwe: CWE-78
      owasp: "A03:2021"
      mcp-component: tools
      confidence: HIGH
    patterns:
      - pattern-either:
          - pattern: subprocess.run($CMD, shell=True, ...)
          - pattern: subprocess.call($CMD, shell=True, ...)
          - pattern: subprocess.Popen($CMD, shell=True, ...)
          - pattern: os.system($CMD)
          - pattern: os.popen($CMD)
      - pattern-inside: |
          def $TOOL(...):
              ...
      - pattern-not-inside: |
          $CMD = "..."  # Literal string only

  - id: mcp-command-injection-format
    message: |
      User input formatted into command string.
      Use argument lists instead of string formatting.
    severity: ERROR
    languages: [python]
    metadata:
      cwe: CWE-78
      mcp-component: tools
    patterns:
      - pattern-either:
          - pattern: subprocess.run(f"...$ARG...", ...)
          - pattern: subprocess.run("...%s..." % $ARG, ...)
          - pattern: subprocess.run("...{}...".format($ARG), ...)
```

#### 3.5.4 protocol/capability-check.yaml

```yaml
rules:
  - id: mcp-missing-capability-check
    message: |
      MCP handler does not check client capabilities before using feature.
      Always verify capabilities before using optional features.
    severity: WARNING
    languages: [python]
    metadata:
      category: security
      subcategory: authorization
      cwe: CWE-862
      mcp-component: protocol
    patterns:
      - pattern: |
          def $HANDLER(...):
              ...
              $CLIENT.send_progress(...)
      - pattern-not-inside: |
          if $CAPABILITIES.experimental.progress:
              ...
```

### 3.6 SARIF Aggregation

> **See**: [SARIF Strategy](../../docs/strategies/sarif-strategy.md) for detailed aggregation workflow.

This phase contributes SARIF files that are merged with outputs from other security phases:

| Source | SARIF Artifact Name | Tool |
|--------|---------------------|------|
| security-sast.yml | sarif-semgrep | Semgrep |
| security-sast-rust.yml | sarif-clippy | Clippy |
| security-sast-python.yml | sarif-bandit | Bandit |
| security-sast-go.yml | sarif-gosec | gosec |

### 3.7 Quality Gate Configuration

```yaml
# configs/sast/gate-config.yaml (Phase 16 contribution)
pr_gate:
  blocking_levels:
    - error

  # Block on these CWEs regardless of confidence
  critical_cwes:
    - CWE-78   # Command Injection
    - CWE-22   # Path Traversal
    - CWE-94   # Code Injection

  # MCP-specific rule blocking
  blocking_rules:
    - mcp-command-injection-shell
    - mcp-path-traversal-resource

  min_confidence: high
  new_findings_only: true
  timeout: 5m
```

### 3.8 Baseline Management

```yaml
# configs/sast/suppressions.yaml (Phase 16 contribution)
suppressions:
  # Example: Known issue tracked elsewhere
  - id: mcp-path-traversal-resource
    file: src/legacy/file_handler.py
    reason: "Legacy code, migration tracked in #456"
    expires: 2025-06-01
    approved_by: security-team

  # Example: Test code exclusion
  - id: mcp-command-injection-shell
    file: tests/**
    reason: "Test fixtures intentionally trigger warnings"
    expires: never
```

---

## 4. Review & Validation

- [ ] Semgrep scans complete in < 3 minutes
- [ ] Language-specific workflows trigger on correct paths
- [ ] SARIF uploads appear in GitHub Security tab
- [ ] MCP rules detect test vulnerabilities
- [ ] False positive rate acceptable (< 10%)
- [ ] Gate blocks on HIGH/CRITICAL findings
- [ ] Baseline comparison works for PRs
- [ ] Implementation tracking checklist updated
