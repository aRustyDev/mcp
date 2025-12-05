---
id: f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c
title: "SAST Strategy"
status: active
created: 2025-12-05
type: strategy
related:
  - sarif-strategy.md
  - policy-as-code.md
phases:
  - 03  # Code Quality
  - 16  # Security - SAST
  - 18  # Security - Memory
  - 19  # Security - Fuzzing
  - 20  # Security - Taint
---

# SAST Strategy

## 1. Overview

This document defines the Static Application Security Testing (SAST) strategy for the MCP bundle. It establishes tool responsibilities, phase boundaries, severity mappings, and quality gates to ensure comprehensive security coverage without duplicate findings or unclear ownership.

### Goals

1. **Clear Ownership**: Each tool has defined responsibilities
2. **No Duplication**: Findings deduplicated across tools
3. **Fast Feedback**: Quick PR checks with deep scheduled analysis
4. **MCP Focus**: Custom rules for MCP-specific vulnerabilities
5. **Actionable Results**: Low false positive rate, clear remediation

---

## 2. Tool Selection Philosophy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TOOL SELECTION CRITERIA                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PRIMARY SELECTION FACTORS                                                   │
│  ─────────────────────────────────────────────────────────────────────────  │
│  1. Language Coverage    - Does it support our language stack?              │
│  2. Analysis Depth       - Pattern vs semantic vs dataflow?                 │
│  3. Customizability      - Can we write MCP-specific rules?                 │
│  4. SARIF Output         - Can results go to GitHub Security tab?           │
│  5. Speed                - Fast enough for PR checks?                       │
│                                                                              │
│  SECONDARY FACTORS                                                           │
│  ─────────────────────────────────────────────────────────────────────────  │
│  6. False Positive Rate  - Acceptable noise level?                          │
│  7. Community Rules      - Existing rule packs available?                   │
│  8. CI Integration       - GitHub Actions support?                          │
│  9. Cost                 - Free tier sufficient?                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Selected Tools

| Tool | Role | Strengths | Limitations |
|------|------|-----------|-------------|
| **Semgrep** | Pattern SAST | Fast, custom rules, multi-language | Limited dataflow (Pro only) |
| **CodeQL** | Semantic SAST | Deep analysis, dataflow, GitHub native | Slower, build required |
| **Clippy** | Rust SAST | Deep Rust knowledge, unsafe detection | Rust only |
| **Bandit** | Python SAST | Python-specific patterns | Pattern-only |
| **gosec** | Go SAST | Go-specific patterns | Pattern-only |
| **cargo-geiger** | Unsafe audit | Counts unsafe code | Rust only |
| **Pysa** | Python taint | Facebook-grade taint analysis | Complex setup |
| **Miri** | Rust memory | Undefined behavior detection | Slow, nightly only |

---

## 3. Phase Boundaries

Clear separation of concerns between phases prevents duplicate work and unclear ownership.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PHASE RESPONSIBILITIES                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 03: CODE QUALITY                                                      │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Focus: Style, formatting, complexity, non-security lints                   │
│  Tools: Linters in "quality" mode (not security)                            │
│  NOT: Security vulnerabilities, unsafe code                                 │
│                                                                              │
│  Examples:                                                                   │
│  ✓ clippy::complexity, clippy::style                                        │
│  ✓ ruff format checking, import sorting                                     │
│  ✓ eslint style rules                                                       │
│  ✗ clippy::suspicious (→ Phase 16)                                          │
│  ✗ bandit security checks (→ Phase 16)                                      │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 16: PATTERN SAST                                                      │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Focus: Pattern-based security detection, fast PR feedback                  │
│  Tools: Semgrep patterns, security lints, cargo-geiger                      │
│  NOT: Dataflow analysis, deep semantic analysis                             │
│                                                                              │
│  Examples:                                                                   │
│  ✓ Semgrep security-audit ruleset                                           │
│  ✓ clippy::suspicious, clippy::correctness                                  │
│  ✓ bandit, gosec pattern detection                                          │
│  ✓ MCP-specific Semgrep patterns                                            │
│  ✗ CodeQL dataflow queries (→ Phase 20)                                     │
│  ✗ Pysa taint tracking (→ Phase 20)                                         │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 18: MEMORY SAFETY                                                     │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Focus: Runtime memory safety, undefined behavior                           │
│  Tools: Miri, sanitizers (ASan, MSan, TSan), Valgrind                       │
│  NOT: Pattern detection, static analysis                                    │
│                                                                              │
│  Examples:                                                                   │
│  ✓ Miri undefined behavior detection                                        │
│  ✓ AddressSanitizer buffer overflow detection                               │
│  ✓ ThreadSanitizer race condition detection                                 │
│  ✗ Static unsafe code counting (→ Phase 16 cargo-geiger)                    │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 19: FUZZING                                                           │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Focus: Dynamic input fuzzing, crash discovery                              │
│  Tools: cargo-fuzz, AFL++, Schemathesis, Atheris                            │
│  NOT: Static analysis, deterministic testing                                │
│                                                                              │
│  Examples:                                                                   │
│  ✓ Protocol parser fuzzing                                                  │
│  ✓ API endpoint fuzzing                                                     │
│  ✓ MCP JSON-RPC message fuzzing                                             │
│  ✗ Static vulnerability detection (→ Phases 16, 20)                         │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 20: DATAFLOW/TAINT ANALYSIS                                           │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Focus: Data flow tracking, source-to-sink analysis                         │
│  Tools: CodeQL dataflow, Semgrep taint mode, Pysa                           │
│  NOT: Pattern matching, memory safety                                       │
│                                                                              │
│  Examples:                                                                   │
│  ✓ CodeQL taint tracking queries                                            │
│  ✓ MCP tool input → file operation tracking                                 │
│  ✓ Pysa source/sink definitions                                             │
│  ✗ Simple pattern matching (→ Phase 16)                                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Phase Execution Order

```
Code Quality (03) → Pattern SAST (16) → Memory (18) → Fuzzing (19) → Taint (20)
       ↓                   ↓                ↓             ↓              ↓
   Style/Lint         Patterns          Runtime       Dynamic        Dataflow
   (Every PR)        (Every PR)        (Weekly)      (Daily)        (Weekly)
```

---

## 4. Tool Responsibility Matrix

### By Vulnerability Class

| Vulnerability | Primary Tool | Secondary Tool | Phase |
|---------------|--------------|----------------|-------|
| SQL Injection | CodeQL | Semgrep | 20, 16 |
| Command Injection | Semgrep | CodeQL | 16, 20 |
| Path Traversal | Semgrep | CodeQL | 16, 20 |
| XSS | Semgrep | CodeQL | 16, 20 |
| SSRF | CodeQL | Semgrep | 20, 16 |
| Unsafe Deserialization | Bandit/Semgrep | CodeQL | 16, 20 |
| Hardcoded Secrets | Gitleaks | Semgrep | 17, 16 |
| Buffer Overflow | Miri/Sanitizers | - | 18 |
| Use After Free | Miri/Sanitizers | - | 18 |
| Data Races | ThreadSanitizer | - | 18 |
| Unsafe Rust | cargo-geiger | Clippy | 16 |
| MCP Tool Injection | Semgrep MCP rules | CodeQL | 16, 20 |

### By Language

| Language | Phase 16 (Pattern) | Phase 20 (Dataflow) | Phase 18 (Memory) |
|----------|-------------------|---------------------|-------------------|
| Rust | Clippy, cargo-geiger, Semgrep | CodeQL* | Miri, sanitizers |
| Python | Bandit, Semgrep | CodeQL, Pysa | - |
| Go | gosec, Semgrep | CodeQL | - |
| JavaScript | ESLint security, Semgrep | CodeQL | - |
| TypeScript | ESLint security, Semgrep | CodeQL | - |

*CodeQL Rust support is limited; rely primarily on Clippy + Miri.

---

## 5. MCP-Specific Security Rules

All MCP-specific rules are centralized in `configs/semgrep/rules/mcp/`.

### Rule Categories

```
configs/semgrep/rules/mcp/
├── injection/
│   ├── path-traversal.yaml      # Resource URI path injection
│   ├── command-injection.yaml   # Tool → subprocess flows
│   └── sql-injection.yaml       # Tool → database flows
├── protocol/
│   ├── json-rpc-validation.yaml # JSON-RPC message validation
│   ├── capability-check.yaml    # Missing capability enforcement
│   └── transport-security.yaml  # Transport layer issues
├── taint/
│   ├── tool-sources.yaml        # Tool argument sources
│   ├── resource-sources.yaml    # Resource URI sources
│   └── dangerous-sinks.yaml     # File, subprocess, network sinks
└── mcp-all.yaml                 # Aggregates all MCP rules
```

### Rule Ownership

| Rule Category | Created In | Used By |
|---------------|------------|---------|
| `injection/` | Phase 16 | Phase 16, 20 |
| `protocol/` | Phase 16 | Phase 16, 19 |
| `taint/` | Phase 20 | Phase 20 |

### Example MCP Rule Structure

```yaml
# configs/semgrep/rules/mcp/injection/path-traversal.yaml
rules:
  - id: mcp-path-traversal-resource
    message: |
      Resource URI contains path traversal sequence.
      MCP resource handlers must validate URIs before filesystem access.
    severity: ERROR
    languages: [python, javascript, typescript]
    metadata:
      category: security
      subcategory: path-traversal
      cwe: CWE-22
      owasp: A01:2021
      mcp-component: resources
      confidence: HIGH
      likelihood: HIGH
      impact: HIGH
      references:
        - https://spec.modelcontextprotocol.io/specification/server/resources/
    patterns:
      - pattern-either:
          - pattern: |
              def read_resource($URI, ...):
                  ...
                  open($PATH, ...)
          - pattern: |
              async def read_resource($URI, ...):
                  ...
                  open($PATH, ...)
      - metavariable-regex:
          metavariable: $PATH
          regex: '.*\.\./.*'
```

---

## 6. Severity Mapping

Unified severity across all tools for consistent gating.

### Severity Levels

| Level | Description | Gate Action |
|-------|-------------|-------------|
| **CRITICAL** | Exploitable, high impact | Block merge |
| **HIGH** | Likely exploitable | Block merge |
| **MEDIUM** | Potential vulnerability | Warning |
| **LOW** | Best practice violation | Info only |
| **INFO** | Informational finding | Info only |

### Tool-to-Unified Mapping

| Tool | Tool Severity | Unified Severity |
|------|---------------|------------------|
| Semgrep | ERROR | CRITICAL/HIGH |
| Semgrep | WARNING | MEDIUM |
| Semgrep | INFO | LOW |
| CodeQL | error | CRITICAL/HIGH |
| CodeQL | warning | MEDIUM |
| CodeQL | note | LOW |
| Clippy | deny | HIGH |
| Clippy | warn | MEDIUM |
| Clippy | allow | INFO |
| Bandit | HIGH | HIGH |
| Bandit | MEDIUM | MEDIUM |
| Bandit | LOW | LOW |

### CWE-Based Severity Override

Certain CWEs always map to specific severities regardless of tool confidence:

```yaml
# configs/sast/severity-overrides.yaml
critical_cwes:
  - CWE-78   # OS Command Injection
  - CWE-89   # SQL Injection
  - CWE-94   # Code Injection
  - CWE-502  # Deserialization of Untrusted Data

high_cwes:
  - CWE-22   # Path Traversal
  - CWE-79   # XSS
  - CWE-918  # SSRF
  - CWE-434  # Unrestricted Upload
```

---

## 7. Quality Gates

### PR Gate (Fast)

Runs on every PR, must complete in < 5 minutes.

```yaml
pr_gate:
  tools:
    - semgrep (p/security-audit + MCP rules)
    - clippy --deny warnings (security categories only)
    - bandit (high confidence only)

  blocking:
    - severity >= HIGH
    - any CRITICAL/HIGH CWE

  warning:
    - severity == MEDIUM

  timeout: 5m
```

### Main Branch Gate (Thorough)

Runs on push to main, can take longer.

```yaml
main_gate:
  tools:
    - semgrep (full ruleset)
    - codeql (security-extended)
    - cargo-geiger
    - pysa (if Python)

  blocking:
    - severity >= MEDIUM with HIGH confidence
    - new findings only (baseline comparison)

  timeout: 30m
```

### Scheduled Deep Scan

Runs weekly, comprehensive analysis.

```yaml
scheduled_scan:
  tools:
    - codeql (security-and-quality)
    - semgrep (all rules including experimental)
    - miri
    - sanitizers

  actions:
    - create_issues_for_high_severity
    - update_security_dashboard
    - generate_trend_report

  schedule: "0 5 * * 1"  # Weekly Monday 5AM
```

---

## 8. Baseline and Suppression Management

### Baseline Strategy

New findings only approach for existing codebases.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BASELINE WORKFLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. INITIAL BASELINE                                                         │
│     └── Run full scan on main branch                                        │
│     └── Store results as baseline in .sast-baseline/                        │
│                                                                              │
│  2. PR COMPARISON                                                            │
│     └── Run scan on PR branch                                               │
│     └── Compare against baseline                                            │
│     └── Report NEW findings only                                            │
│                                                                              │
│  3. BASELINE UPDATE                                                          │
│     └── After merge to main, update baseline                                │
│     └── Track baseline drift over time                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Suppression Files

```
.semgrepignore           # Semgrep path exclusions
.codeql/                 # CodeQL configuration
  └── queries/
      └── excludes.qll   # CodeQL query exclusions
configs/sast/
  └── suppressions.yaml  # Unified suppression list
```

### Suppression Format

```yaml
# configs/sast/suppressions.yaml
suppressions:
  - id: mcp-path-traversal-resource
    file: src/legacy/old_handler.py
    reason: "Legacy code, tracked in issue #123"
    expires: 2025-03-01
    approved_by: security-team

  - id: bandit-B101
    file: tests/**
    reason: "Assert statements acceptable in tests"
    expires: never
```

### Suppression Review Process

1. All suppressions require `approved_by` field
2. Suppressions with `expires` are auto-removed after date
3. Monthly review of all suppressions
4. Suppressions tracked in security dashboard

---

## 9. Workflow Integration

### Unified SAST Workflow

See [SARIF Strategy](sarif-strategy.md) for result aggregation.

```yaml
# .github/workflows/sast.yml (simplified)
name: SAST

on:
  pull_request:
  push:
    branches: [main]

jobs:
  # Fast pattern checks
  semgrep:
    uses: ./.github/workflows/sast-semgrep.yml

  # Language-specific security lints
  security-lints:
    uses: ./.github/workflows/sast-lints.yml

  # Deep analysis (main only)
  codeql:
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/sast-codeql.yml

  # Aggregate and gate
  gate:
    needs: [semgrep, security-lints]
    uses: ./.github/workflows/sarif-gate.yml
```

---

## 10. Metrics and Reporting

### Key Metrics

| Metric | Target | Measured By |
|--------|--------|-------------|
| False Positive Rate | < 10% | Manual review sampling |
| Mean Time to Fix (MTTF) | < 7 days for HIGH | Issue tracking |
| Coverage | 100% of languages | Tool matrix |
| Scan Time (PR) | < 5 minutes | Workflow duration |
| Baseline Drift | < 5% monthly | Baseline comparison |

### Dashboard Requirements

- Findings by severity over time
- Findings by vulnerability class
- Tool effectiveness comparison
- Fix rate trends
- Coverage gaps

---

## 11. Migration Guide

### From No SAST

1. Implement Phase 16 (Pattern SAST) first
2. Create baseline from initial scan
3. Enable PR blocking for HIGH/CRITICAL only
4. Gradually add Phase 20 (Dataflow)

### From Existing Tools

1. Map existing tools to phase responsibilities
2. Consolidate overlapping rules
3. Migrate to unified SARIF workflow
4. Update suppression format

---

## 12. Related Documents

- [SARIF Strategy](sarif-strategy.md) - Result aggregation and gating
- [Policy-as-Code Strategy](policy-as-code.md) - OPA/Rego policy enforcement
- Phase 16: Pattern-based SAST implementation
- Phase 20: Dataflow analysis implementation
