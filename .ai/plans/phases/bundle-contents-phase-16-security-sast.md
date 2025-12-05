---
id: 4690fa44-71ef-4f5d-84f4-943c8c50a34b
title: "Phase 16: Security - SAST"
status: pending
depends_on:
  - 998f42c0-584d-4dcb-8b02-07116f0f03e3  # phase-15
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 16: Security - SAST

## 1. Current State Assessment

- [ ] Check for existing SAST configuration
- [ ] Review CodeQL setup if present
- [ ] Identify Semgrep rules in use
- [ ] Check for language-specific security lints

### Existing Assets

Clippy security lints (Phase 03) provide some Rust coverage.

### Gaps Identified

- [ ] security-sast.yml (unified SAST)
- [ ] Semgrep custom rules
- [ ] CodeQL query packs
- [ ] SARIF aggregation
- [ ] Language-specific SAST workflows

---

## 2. Contextual Goal

Implement comprehensive static application security testing using Semgrep and CodeQL. Create custom rules for MCP-specific patterns, aggregate SARIF results to GitHub Security tab, and provide language-specific security analysis for Rust, Python, Go, and JavaScript. Focus on vulnerability detection without generating excessive false positives.

### Success Criteria

- [ ] Unified SAST workflow with Semgrep + CodeQL
- [ ] MCP-specific Semgrep rules created
- [ ] SARIF results appear in Security tab
- [ ] False positive rate acceptable
- [ ] Custom query packs for each language

### Out of Scope

- DAST (runtime testing)
- Fuzzing (Phase 19)

---

## 3. Implementation

### 3.1 security-sast.yml

```yaml
name: SAST

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 5 * * *'

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Semgrep Scan
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/rust
            p/python
            p/javascript
            .semgrep/
          generateSarif: true

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: semgrep.sarif

  codeql:
    runs-on: ubuntu-latest
    permissions:
      security-events: write

    strategy:
      matrix:
        language: [python, javascript]

    steps:
      - uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          queries: security-extended

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform Analysis
        uses: github/codeql-action/analyze@v3
```

### 3.2 MCP-Specific Semgrep Rules

```yaml
# .semgrep/mcp-security.yml
rules:
  - id: mcp-path-traversal
    patterns:
      - pattern: |
          resources/read($URI)
      - metavariable-regex:
          metavariable: $URI
          regex: '.*\.\./.*'
    message: Potential path traversal in resource URI
    severity: ERROR

  - id: mcp-command-injection
    patterns:
      - pattern: |
          subprocess.run($CMD, shell=True)
      - pattern-inside: |
          def $TOOL(...):
              ...
    message: Command injection risk in MCP tool
    severity: ERROR
```

### 3.3 Language-Specific Workflows

- `security-sast-rust.yml`: Clippy security lints + cargo-geiger
- `security-sast-python.yml`: Bandit + Pylint security
- `security-sast-go.yml`: gosec + staticcheck

---

## 4. Review & Validation

- [ ] All SAST tools run without errors
- [ ] SARIF uploads to Security tab
- [ ] Custom MCP rules detect issues
- [ ] False positive rate < 10%
- [ ] Implementation tracking checklist updated
