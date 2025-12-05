---
id: 0e96d833-2d1f-4d8a-b7d3-3711ea49f320
title: "Phase 20: Security - Taint"
status: pending
depends_on:
  - b3db6c9b-ec1e-4298-b8f5-2149afcd5050  # phase-19
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 20: Security - Taint

## 1. Current State Assessment

- [ ] Check for existing data flow analysis
- [ ] Review CodeQL taint tracking usage
- [ ] Identify MCP-specific data flows
- [ ] Check for Pysa configuration

### Existing Assets

CodeQL (Phase 16) provides some taint tracking.

### Gaps Identified

- [ ] security-taint.yml (CodeQL data flow)
- [ ] Semgrep taint rules for MCP
- [ ] Pysa configuration for Python
- [ ] Custom source/sink definitions

---

## 2. Contextual Goal

Implement taint analysis to track data flow from untrusted sources to sensitive sinks. This is critical for MCP servers where tool inputs flow to system operations. Define MCP-specific sources (tool arguments, resource URIs) and sinks (file operations, command execution) to detect injection vulnerabilities.

### Success Criteria

- [ ] CodeQL taint queries functional
- [ ] Semgrep taint rules for MCP
- [ ] Pysa configured for Python servers
- [ ] Custom sources/sinks documented
- [ ] No false negatives on known patterns

### Out of Scope

- Runtime taint tracking (RASP)
- Full formal verification

---

## 3. Implementation

### 3.1 security-taint.yml

```yaml
name: Taint Analysis

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 5 * * 1'

jobs:
  codeql-taint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: python
          queries: security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Analyze
        uses: github/codeql-action/analyze@v3

  semgrep-taint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Semgrep Taint
        uses: returntocorp/semgrep-action@v1
        with:
          config: .semgrep/taint-rules.yml
```

### 3.2 MCP Taint Rules

```yaml
# .semgrep/taint-rules.yml
rules:
  - id: mcp-taint-tool-to-file
    mode: taint
    message: Untrusted tool input flows to file operation
    severity: ERROR
    languages: [python]
    pattern-sources:
      - patterns:
          - pattern: $ARGS["$KEY"]
          - pattern-inside: |
              def $TOOL(..., $ARGS: dict, ...):
                  ...
    pattern-sinks:
      - pattern: open($PATH, ...)
      - pattern: os.path.join(..., $PATH, ...)

  - id: mcp-taint-resource-to-command
    mode: taint
    message: Resource URI flows to command execution
    severity: ERROR
    languages: [python]
    pattern-sources:
      - pattern: $URI
        pattern-inside: |
            def read_resource($URI, ...):
                ...
    pattern-sinks:
      - pattern: subprocess.run($CMD, ...)
      - pattern: os.system($CMD)
```

### 3.3 MCP Sources and Sinks

| Category | Sources | Sinks |
|----------|---------|-------|
| Tools | `arguments` dict, `name` param | File ops, subprocess, DB |
| Resources | `uri` param, template vars | File read, network fetch |
| Prompts | `arguments` dict | Any output |

### 3.4 Pysa Configuration

```python
# .pyre/taint.config
{
  "sources": [
    {"name": "MCPToolInput", "comment": "Tool arguments from client"},
    {"name": "MCPResourceURI", "comment": "Resource URI from client"}
  ],
  "sinks": [
    {"name": "FileSystem", "comment": "File system operations"},
    {"name": "CommandExecution", "comment": "Shell/subprocess"}
  ],
  "features": [],
  "rules": [
    {
      "name": "MCP Injection",
      "code": 1001,
      "sources": ["MCPToolInput", "MCPResourceURI"],
      "sinks": ["FileSystem", "CommandExecution"]
    }
  ]
}
```

---

## 4. Review & Validation

- [ ] Taint analysis detects known vulnerabilities
- [ ] Custom rules cover MCP patterns
- [ ] No false negatives on test cases
- [ ] Sources and sinks are complete
- [ ] Implementation tracking checklist updated
