---
id: a9b8c7d6-e5f4-3a2b-1c0d-9e8f7a6b5c4d
title: "SARIF Strategy"
status: active
created: 2025-12-05
type: strategy
related:
  - sast-strategy.md
  - policy-as-code.md
phases:
  - 03  # Code Quality (SARIF output)
  - 14  # Dependency Scanning
  - 16  # Security - SAST
  - 17  # Security - Secrets
  - 18  # Security - Memory
  - 19  # Security - Fuzzing
  - 20  # Security - Taint
  - 21  # Security - Containers
---

# SARIF Strategy

## 1. Overview

SARIF (Static Analysis Results Interchange Format) is the standard format for representing static analysis results. This strategy defines how to aggregate, deduplicate, enrich, and act on SARIF output from multiple security tools.

### Goals

1. **Unified View**: All findings in GitHub Security tab
2. **Deduplication**: No duplicate alerts from overlapping tools
3. **Enrichment**: Consistent metadata across tools
4. **Gating**: Automated merge blocking based on findings
5. **Tracking**: Trend analysis and metrics

---

## 2. SARIF Fundamentals

### Format Structure

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "semgrep",
          "version": "1.50.0",
          "rules": [...]
        }
      },
      "results": [
        {
          "ruleId": "mcp-path-traversal",
          "level": "error",
          "message": { "text": "..." },
          "locations": [...],
          "fingerprints": {...}
        }
      ]
    }
  ]
}
```

### Key Fields

| Field | Purpose | Usage |
|-------|---------|-------|
| `ruleId` | Unique rule identifier | Deduplication, suppression |
| `level` | Severity (error/warning/note) | Gating decisions |
| `fingerprint` | Stable identifier for finding | Baseline comparison |
| `locations` | Code location | Developer navigation |
| `properties` | Custom metadata | Enrichment |

---

## 3. Tool SARIF Support

### Tools with Native SARIF Output

| Tool | Phase | SARIF Support | Notes |
|------|-------|---------------|-------|
| Semgrep | 16, 20 | Native | `--sarif` flag |
| CodeQL | 16, 20 | Native | GitHub Actions default |
| Trivy | 14, 21 | Native | `--format sarif` |
| Gitleaks | 17 | Native | `--report-format sarif` |
| Hadolint | 03 | Native | `--format sarif` |
| Clippy | 03, 16 | Via converter | `clippy-sarif` |
| Bandit | 16 | Native | `--format sarif` |
| gosec | 16 | Native | `-fmt sarif` |
| ESLint | 03, 16 | Via plugin | `@microsoft/eslint-formatter-sarif` |
| Shellcheck | 03 | Via converter | `shellcheck-sarif` |
| Checkov | 21 | Native | `--output sarif` |

### Tools Requiring SARIF Conversion

```yaml
# Converters used in workflows
converters:
  clippy-sarif: "https://github.com/psastras/sarif-rs"
  cargo-audit-sarif: "https://github.com/pvillela/cargo-audit-sarif"
  shellcheck-sarif: "https://github.com/aegistudio/shellcheck-sarif"
  mypy-sarif: "Custom script"
  pylint-sarif: "Custom script"
```

---

## 4. SARIF Workflow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SARIF PIPELINE                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│  │ Semgrep │ │ CodeQL  │ │  Trivy  │ │ Bandit  │ │ Clippy  │               │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘               │
│       │           │           │           │           │                     │
│       │    *.sarif files      │           │           │                     │
│       └───────────┼───────────┼───────────┼───────────┘                     │
│                   ↓           ↓           ↓                                 │
│              ┌─────────────────────────────────┐                            │
│              │       SARIF MERGE               │                            │
│              │  (sarif-multitool merge)        │                            │
│              └───────────────┬─────────────────┘                            │
│                              ↓                                              │
│              ┌─────────────────────────────────┐                            │
│              │     DEDUPLICATION               │                            │
│              │  (fingerprint-based)            │                            │
│              └───────────────┬─────────────────┘                            │
│                              ↓                                              │
│              ┌─────────────────────────────────┐                            │
│              │      ENRICHMENT                 │                            │
│              │  (add CWE, CVSS, metadata)      │                            │
│              └───────────────┬─────────────────┘                            │
│                              ↓                                              │
│              ┌─────────────────────────────────┐                            │
│              │    BASELINE COMPARISON          │                            │
│              │  (identify new findings)        │                            │
│              └───────────────┬─────────────────┘                            │
│                              ↓                                              │
│       ┌──────────────────────┼──────────────────────┐                       │
│       ↓                      ↓                      ↓                       │
│  ┌─────────┐          ┌─────────────┐        ┌──────────┐                  │
│  │ GitHub  │          │   Quality   │        │  Report  │                  │
│  │Security │          │    Gate     │        │Generator │                  │
│  │  Tab    │          │  Decision   │        │          │                  │
│  └─────────┘          └─────────────┘        └──────────┘                  │
│                              │                                              │
│                    ┌─────────┴─────────┐                                   │
│                    ↓                   ↓                                   │
│               [PASS]              [FAIL]                                    │
│            Continue PR         Block Merge                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. SARIF Aggregation

### Merge Workflow

```yaml
# .github/workflows/sarif-aggregate.yml
name: SARIF Aggregation

on:
  workflow_call:
    inputs:
      sarif_files:
        description: 'Glob pattern for SARIF files'
        type: string
        default: '**/*.sarif'

jobs:
  aggregate:
    runs-on: ubuntu-latest
    steps:
      - name: Download all SARIF artifacts
        uses: actions/download-artifact@v4
        with:
          pattern: sarif-*
          path: sarif-results/
          merge-multiple: true

      - name: Setup SARIF tools
        run: |
          npm install -g @microsoft/sarif-multitool

      - name: Merge SARIF files
        run: |
          sarif-multitool merge sarif-results/*.sarif \
            --output-file merged.sarif \
            --force

      - name: Validate merged SARIF
        run: |
          sarif-multitool validate merged.sarif

      - name: Upload merged SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: merged.sarif
          category: security-scan

      - name: Store for gating
        uses: actions/upload-artifact@v4
        with:
          name: merged-sarif
          path: merged.sarif
```

### Tool-Specific SARIF Jobs

Each tool uploads its own SARIF as an artifact:

```yaml
# Example: Semgrep SARIF output
- name: Semgrep Scan
  run: |
    semgrep scan --config auto --sarif --output semgrep.sarif

- name: Upload Semgrep SARIF
  uses: actions/upload-artifact@v4
  with:
    name: sarif-semgrep
    path: semgrep.sarif
```

---

## 6. Deduplication Strategy

### Deduplication Levels

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     DEDUPLICATION HIERARCHY                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  LEVEL 1: SAME TOOL, SAME FILE, SAME LINE                                   │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Method: Exact match on file path + line number + ruleId                    │
│  Action: Keep single instance                                               │
│                                                                              │
│  LEVEL 2: SAME FILE, SAME LINE, DIFFERENT TOOLS                             │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Method: Match on file path + line range overlap + CWE mapping              │
│  Action: Keep finding from PRIMARY tool, reference others                   │
│                                                                              │
│  LEVEL 3: SAME VULNERABILITY CLASS, DIFFERENT LOCATIONS                     │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Method: Pattern-based grouping (same CWE, same function)                   │
│  Action: Group into single alert with multiple locations                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tool Priority for Duplicates

When multiple tools detect the same issue, keep the finding from:

| Priority | Tool | Reason |
|----------|------|--------|
| 1 | CodeQL | Deepest analysis, best explanations |
| 2 | Semgrep | Good context, customizable |
| 3 | Language-specific (Bandit, gosec) | Domain expertise |
| 4 | Generic linters | Broadest but shallowest |

### Deduplication Script

```python
#!/usr/bin/env python3
# scripts/sarif-dedup.py

import json
import sys
from collections import defaultdict

def fingerprint_result(result):
    """Generate stable fingerprint for deduplication."""
    location = result.get('locations', [{}])[0]
    physical = location.get('physicalLocation', {})
    artifact = physical.get('artifactLocation', {}).get('uri', '')
    region = physical.get('region', {})

    return f"{artifact}:{region.get('startLine', 0)}:{result.get('ruleId', '')}"

def deduplicate_sarif(sarif_data):
    """Deduplicate results across all runs."""
    seen = {}

    for run in sarif_data.get('runs', []):
        tool_name = run.get('tool', {}).get('driver', {}).get('name', 'unknown')
        deduped_results = []

        for result in run.get('results', []):
            fp = fingerprint_result(result)

            if fp not in seen:
                seen[fp] = (tool_name, result)
                deduped_results.append(result)
            else:
                # Add reference to duplicate
                result.setdefault('properties', {})['duplicateOf'] = {
                    'tool': seen[fp][0],
                    'ruleId': seen[fp][1].get('ruleId')
                }

        run['results'] = deduped_results

    return sarif_data

if __name__ == '__main__':
    sarif = json.load(sys.stdin)
    deduped = deduplicate_sarif(sarif)
    json.dump(deduped, sys.stdout, indent=2)
```

---

## 7. SARIF Enrichment

### Enrichment Fields

Add consistent metadata to all findings:

```yaml
enrichment:
  # CWE mapping
  cwe:
    source: rule metadata or manual mapping
    format: "CWE-XXX"

  # CVSS score (if applicable)
  cvss:
    source: NVD or manual assessment
    version: "3.1"

  # OWASP Top 10
  owasp:
    source: rule metadata
    format: "A01:2021"

  # Custom MCP metadata
  mcp:
    component: tools|resources|prompts|transport
    severity_override: based on MCP context
```

### Enrichment Workflow

```yaml
- name: Enrich SARIF
  run: |
    python scripts/sarif-enrich.py \
      --input merged.sarif \
      --output enriched.sarif \
      --cwe-mapping configs/sast/cwe-mapping.yaml \
      --severity-overrides configs/sast/severity-overrides.yaml
```

### CWE Mapping File

```yaml
# configs/sast/cwe-mapping.yaml
rules:
  # Semgrep rules
  mcp-path-traversal:
    cwe: CWE-22
    owasp: "A01:2021"

  mcp-command-injection:
    cwe: CWE-78
    owasp: "A03:2021"

  # Bandit rules
  B102:
    cwe: CWE-78
    owasp: "A03:2021"

  B301:
    cwe: CWE-502
    owasp: "A08:2021"
```

---

## 8. Baseline Management

### Baseline Files

```
.sast-baseline/
├── main.sarif           # Baseline for main branch
├── baseline.json        # Fingerprint index
└── history/
    └── 2025-01-01.sarif # Historical baselines
```

### Baseline Comparison Workflow

```yaml
- name: Compare against baseline
  run: |
    python scripts/sarif-baseline.py \
      --current merged.sarif \
      --baseline .sast-baseline/main.sarif \
      --output new-findings.sarif \
      --stats baseline-stats.json

- name: Report new findings only
  if: hashFiles('new-findings.sarif') != ''
  run: |
    echo "## New Security Findings" >> $GITHUB_STEP_SUMMARY
    python scripts/sarif-summary.py new-findings.sarif >> $GITHUB_STEP_SUMMARY
```

### Baseline Update Process

```yaml
# On merge to main
- name: Update baseline
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: |
    cp merged.sarif .sast-baseline/main.sarif

    # Archive historical baseline
    DATE=$(date +%Y-%m-%d)
    cp merged.sarif ".sast-baseline/history/${DATE}.sarif"

    git add .sast-baseline/
    git commit -m "chore: update SAST baseline"
    git push
```

---

## 9. Quality Gate Implementation

### Gate Decision Logic

```python
#!/usr/bin/env python3
# scripts/sarif-gate.py

import json
import sys

def evaluate_gate(sarif_data, config):
    """Evaluate quality gate based on SARIF findings."""

    blocking_findings = []
    warning_findings = []

    for run in sarif_data.get('runs', []):
        for result in run.get('results', []):
            level = result.get('level', 'warning')
            rule_id = result.get('ruleId', '')

            # Check CWE-based blocking
            cwe = result.get('properties', {}).get('cwe', '')
            if cwe in config['critical_cwes']:
                blocking_findings.append(result)
                continue

            # Check level-based blocking
            if level == 'error':
                blocking_findings.append(result)
            elif level == 'warning':
                warning_findings.append(result)

    return {
        'pass': len(blocking_findings) == 0,
        'blocking': blocking_findings,
        'warnings': warning_findings,
        'summary': {
            'blocking_count': len(blocking_findings),
            'warning_count': len(warning_findings)
        }
    }

if __name__ == '__main__':
    sarif = json.load(open(sys.argv[1]))
    config = json.load(open(sys.argv[2]))

    result = evaluate_gate(sarif, config)

    print(json.dumps(result, indent=2))
    sys.exit(0 if result['pass'] else 1)
```

### Gate Configuration

```yaml
# configs/sast/gate-config.yaml
pr_gate:
  # Block on these severity levels
  blocking_levels:
    - error

  # Block on these CWEs regardless of level
  critical_cwes:
    - CWE-78   # Command Injection
    - CWE-89   # SQL Injection
    - CWE-94   # Code Injection
    - CWE-22   # Path Traversal (for MCP)

  # Minimum confidence to block
  min_confidence: high

  # Only consider new findings (vs baseline)
  new_findings_only: true

main_gate:
  blocking_levels:
    - error
    - warning

  critical_cwes:
    - CWE-78
    - CWE-89
    - CWE-94
    - CWE-22
    - CWE-502  # Deserialization

  min_confidence: medium
  new_findings_only: false
```

### Gate Workflow

```yaml
# .github/workflows/sarif-gate.yml
name: Security Gate

on:
  workflow_call:

jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download merged SARIF
        uses: actions/download-artifact@v4
        with:
          name: merged-sarif

      - name: Evaluate gate
        id: gate
        run: |
          python scripts/sarif-gate.py \
            merged.sarif \
            configs/sast/gate-config.yaml \
            > gate-result.json

          PASS=$(jq -r '.pass' gate-result.json)
          echo "pass=$PASS" >> $GITHUB_OUTPUT

          if [ "$PASS" = "false" ]; then
            echo "## Security Gate Failed" >> $GITHUB_STEP_SUMMARY
            echo "" >> $GITHUB_STEP_SUMMARY
            jq -r '.blocking[] | "- **\(.ruleId)**: \(.message.text)"' gate-result.json >> $GITHUB_STEP_SUMMARY
          fi

      - name: Fail if blocking findings
        if: steps.gate.outputs.pass == 'false'
        run: exit 1
```

---

## 10. GitHub Security Integration

### Upload Strategy

```yaml
# Single upload for merged results
- name: Upload to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: merged.sarif
    category: mcp-security-scan
    wait-for-processing: true
```

### Categories

Use categories to organize findings:

| Category | Tools | Purpose |
|----------|-------|---------|
| `sast-pattern` | Semgrep, linters | Pattern-based findings |
| `sast-dataflow` | CodeQL, Pysa | Dataflow findings |
| `dependency` | Trivy, cargo-audit | Dependency vulnerabilities |
| `secrets` | Gitleaks | Secret detection |
| `container` | Trivy, Checkov | Container security |

### Alert Dismissal

Configure default dismissal reasons:

```yaml
# .github/security-advisories.yml
dismissal_reasons:
  false_positive: "Finding is incorrect"
  wont_fix: "Accepted risk, documented in issue"
  used_in_tests: "Only used in test code"
  mitigated: "Mitigated by other controls"
```

---

## 11. Reporting

### PR Summary Report

```yaml
- name: Generate PR summary
  run: |
    python scripts/sarif-report.py \
      --sarif merged.sarif \
      --format github-summary \
      >> $GITHUB_STEP_SUMMARY
```

### Summary Format

```markdown
## Security Scan Results

### Summary
| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | :white_check_mark: |
| High | 2 | :x: Blocking |
| Medium | 5 | :warning: |
| Low | 12 | :information_source: |

### Blocking Findings (2)

#### 1. Command Injection in tool handler
- **Rule**: mcp-command-injection
- **File**: `src/tools/shell.py:45`
- **CWE**: CWE-78

<details>
<summary>Details</summary>

Tool arguments flow to subprocess without sanitization.

```python
subprocess.run(args["command"], shell=True)  # Line 45
```

**Remediation**: Use `shlex.split()` and avoid `shell=True`.
</details>

### Warnings (5)
[Collapsed by default...]
```

### Trend Report

Weekly trend report for security dashboard:

```yaml
# .github/workflows/security-report.yml
name: Weekly Security Report

on:
  schedule:
    - cron: '0 9 * * 1'  # Monday 9 AM

jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - name: Generate trend report
        run: |
          python scripts/sarif-trend.py \
            --baseline-dir .sast-baseline/history/ \
            --output trend-report.md

      - name: Post to Slack/Discord
        uses: slackapi/slack-github-action@v1
        with:
          payload-file-path: trend-report.json
```

---

## 12. Tooling Reference

### sarif-multitool Commands

```bash
# Merge multiple SARIF files
sarif-multitool merge a.sarif b.sarif --output merged.sarif

# Validate SARIF format
sarif-multitool validate merged.sarif

# Convert formats
sarif-multitool convert --input result.json --output result.sarif --tool semgrep

# Query SARIF
sarif-multitool query --expression "runs[*].results[?level=='error']" merged.sarif
```

### jq Queries for SARIF

```bash
# Count findings by severity
jq '[.runs[].results[].level] | group_by(.) | map({key: .[0], count: length})' merged.sarif

# List all rule IDs
jq '[.runs[].results[].ruleId] | unique' merged.sarif

# Get findings for specific file
jq '.runs[].results[] | select(.locations[0].physicalLocation.artifactLocation.uri | contains("handler.py"))' merged.sarif

# Extract fingerprints
jq '.runs[].results[] | {ruleId, fingerprint: .fingerprints}' merged.sarif
```

---

## 13. Related Documents

- [SAST Strategy](sast-strategy.md) - Tool selection and phase boundaries
- [Policy-as-Code Strategy](policy-as-code.md) - OPA/Rego policy enforcement
- Phase 16: Pattern-based SAST implementation
- Phase 20: Dataflow analysis implementation
