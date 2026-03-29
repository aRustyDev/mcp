---
id: 0e96d833-2d1f-4d8a-b7d3-3711ea49f320
title: "Phase 20: Security - Taint"
status: pending
depends_on:
  - b3db6c9b-ec1e-4298-b8f5-2149afcd5050  # phase-19
  - 4690fa44-71ef-4f5d-84f4-943c8c50a34b  # phase-16 (shares MCP rule definitions)
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - ../../docs/strategies/sast-strategy.md   # Phase boundary and tool selection
  - ../../docs/strategies/sarif-strategy.md  # SARIF aggregation
issues: []
---

# Phase 20: Security - Taint

## 1. Current State Assessment

- [ ] Check for existing data flow analysis
- [ ] Review CodeQL taint tracking usage
- [ ] Identify MCP-specific data flows
- [ ] Check for Pysa configuration

### Existing Assets

Phase 16 provides pattern-based detection; this phase adds dataflow depth.

### Gaps Identified

- [ ] security-taint.yml (CodeQL dataflow)
- [ ] security-taint-python.yml (Pysa)
- [ ] Semgrep taint mode rules for MCP
- [ ] Custom CodeQL queries for MCP
- [ ] MCP source/sink definitions
- [ ] SARIF aggregation integration

---

## 2. Contextual Goal

Implement **dataflow and taint analysis** to track how untrusted input flows through code to dangerous sinks. This complements Phase 16's pattern matching with semantic understanding of data propagation. Critical for MCP servers where tool inputs flow to system operations.

> **See**: [SAST Strategy](../../docs/strategies/sast-strategy.md) for tool selection rationale and phase boundaries.

### Success Criteria

- [ ] CodeQL taint queries functional
- [ ] Semgrep taint mode rules for MCP
- [ ] Pysa configured for Python servers
- [ ] Custom MCP sources/sinks documented
- [ ] SARIF results aggregated
- [ ] No false negatives on known patterns

### Out of Scope

- Pattern-based detection (Phase 16)
- Runtime taint tracking (RASP)
- Full formal verification
- Memory safety (Phase 18)

### Phase Boundary

> **See**: [SAST Strategy](../../docs/strategies/sast-strategy.md) for detailed phase boundaries.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        PHASE 20 RESPONSIBILITIES                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  IN SCOPE (Dataflow/Taint Analysis)                                          │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✓ CodeQL dataflow queries (security-and-quality)                           │
│  ✓ CodeQL custom taint queries for MCP                                      │
│  ✓ Semgrep taint mode (source → sink tracking)                              │
│  ✓ Pysa (Facebook's Python taint analyzer)                                  │
│  ✓ Cross-function vulnerability detection                                   │
│  ✓ MCP-specific source/sink definitions                                     │
│                                                                              │
│  OUT OF SCOPE (Other Phases)                                                 │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✗ Pattern matching without dataflow → Phase 16                             │
│  ✗ Semgrep patterns (non-taint mode) → Phase 16                             │
│  ✗ Language-specific lints → Phase 16                                       │
│  ✗ Memory safety → Phase 18                                                 │
│  ✗ Fuzzing → Phase 19                                                       │
│                                                                              │
│  Analysis Type: STATIC (semantic dataflow)                                   │
│  Execution Frequency: Weekly (scheduled) + main branch push                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Relationship with Phase 16

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PHASE 16 vs PHASE 20 TOOL SPLIT                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  SEMGREP                                                                     │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Phase 16: pattern, pattern-either, pattern-inside (no taint tracking)      │
│  Phase 20: mode: taint, pattern-sources, pattern-sinks                      │
│                                                                              │
│  CODEQL                                                                      │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Phase 16: Not used (defer to Semgrep for speed)                            │
│  Phase 20: Full dataflow queries, security-and-quality suite                │
│                                                                              │
│  MCP RULES                                                                   │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Phase 16: configs/semgrep/rules/mcp/injection/ (patterns)                  │
│  Phase 20: configs/semgrep/rules/mcp/taint/ (taint tracking)                │
│            .codeql/queries/mcp/ (CodeQL dataflow)                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

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
    - cron: '0 5 * * 1'  # Weekly deep scan

jobs:
  codeql-taint:
    name: CodeQL Dataflow Analysis
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
          queries: security-and-quality
          config-file: .codeql/codeql-config.yml

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Analyze
        uses: github/codeql-action/analyze@v3
        with:
          category: taint-${{ matrix.language }}
          output: codeql-${{ matrix.language }}.sarif

      - name: Upload CodeQL SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-codeql-${{ matrix.language }}
          path: codeql-${{ matrix.language }}.sarif

  semgrep-taint:
    name: Semgrep Taint Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Semgrep Taint Scan
        uses: returntocorp/semgrep-action@v1
        with:
          config: configs/semgrep/rules/mcp/taint/
          generateSarif: true

      - name: Upload Semgrep Taint SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-semgrep-taint
          path: semgrep.sarif

  # Aggregate and upload to Security tab
  aggregate:
    needs: [codeql-taint, semgrep-taint]
    uses: ./.github/workflows/sarif-aggregate.yml
```

### 3.2 security-taint-python.yml (Pysa)

```yaml
name: Python Taint Analysis (Pysa)

on:
  push:
    branches: [main]
    paths: ['**.py']
  schedule:
    - cron: '0 5 * * 1'

jobs:
  pysa:
    name: Pysa Taint Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Pyre/Pysa
        run: pip install pyre-check

      - name: Setup Pyre
        run: |
          pyre init || true

      - name: Run Pysa
        run: |
          pyre analyze \
            --taint-models-path .pyre/taint.config \
            --save-results-to pysa-results/

      - name: Convert to SARIF
        run: |
          python scripts/pysa-to-sarif.py \
            --input pysa-results/ \
            --output pysa.sarif

      - name: Upload Pysa SARIF
        uses: actions/upload-artifact@v4
        with:
          name: sarif-pysa
          path: pysa.sarif
```

### 3.3 MCP Taint Rules (Semgrep)

> **Rule Location**: `configs/semgrep/rules/mcp/taint/`

These rules use Semgrep's taint mode to track data from MCP sources to dangerous sinks.

#### 3.3.1 taint/tool-to-file.yaml

```yaml
rules:
  - id: mcp-taint-tool-to-file
    mode: taint
    message: |
      Untrusted tool input flows to file operation without validation.
      MCP tool arguments must be validated before use in file operations.

      Remediation:
      - Validate paths against allowlist
      - Use Path.resolve() and check with is_relative_to()
      - Sanitize filenames with secure_filename()
    severity: ERROR
    languages: [python]
    metadata:
      category: security
      subcategory: path-traversal
      cwe: CWE-22
      owasp: "A01:2021"
      mcp-component: tools
      confidence: HIGH

    pattern-sources:
      - patterns:
          - pattern: $ARGS["$KEY"]
          - pattern-inside: |
              async def $TOOL($CTX, $ARGS: dict, ...):
                  ...
      - patterns:
          - pattern: $ARGS.get("$KEY", ...)
          - pattern-inside: |
              async def $TOOL($CTX, $ARGS: dict, ...):
                  ...

    pattern-sinks:
      - pattern: open($PATH, ...)
      - pattern: Path($PATH).read_text(...)
      - pattern: Path($PATH).write_text(...)
      - pattern: os.path.join($BASE, $PATH)
      - pattern: shutil.copy($SRC, $PATH)
      - pattern: shutil.move($SRC, $PATH)

    pattern-sanitizers:
      - pattern: os.path.realpath($X)
      - pattern: Path($X).resolve()
      - pattern: secure_filename($X)
```

#### 3.3.2 taint/tool-to-command.yaml

```yaml
rules:
  - id: mcp-taint-tool-to-command
    mode: taint
    message: |
      Untrusted tool input flows to command execution.
      MCP tool arguments must never reach shell commands.

      Remediation:
      - Use subprocess with shell=False and argument list
      - Validate against strict allowlist
      - Consider if command execution is necessary
    severity: ERROR
    languages: [python]
    metadata:
      category: security
      subcategory: command-injection
      cwe: CWE-78
      owasp: "A03:2021"
      mcp-component: tools
      confidence: HIGH

    pattern-sources:
      - patterns:
          - pattern: $ARGS["$KEY"]
          - pattern-inside: |
              async def $TOOL($CTX, $ARGS: dict, ...):
                  ...

    pattern-sinks:
      - pattern: subprocess.run($CMD, shell=True, ...)
      - pattern: subprocess.call($CMD, shell=True, ...)
      - pattern: subprocess.Popen($CMD, shell=True, ...)
      - pattern: os.system($CMD)
      - pattern: os.popen($CMD)
      - pattern: eval($CMD)
      - pattern: exec($CMD)

    pattern-sanitizers:
      - pattern: shlex.quote($X)
      - pattern: shlex.split($X)
```

#### 3.3.3 taint/resource-to-network.yaml

```yaml
rules:
  - id: mcp-taint-resource-to-network
    mode: taint
    message: |
      Resource URI flows to network request (potential SSRF).
      Validate URLs against allowlist before making requests.
    severity: ERROR
    languages: [python]
    metadata:
      cwe: CWE-918
      owasp: "A10:2021"
      mcp-component: resources

    pattern-sources:
      - patterns:
          - pattern: $URI
          - pattern-inside: |
              async def read_resource($URI: str, ...):
                  ...

    pattern-sinks:
      - pattern: requests.get($URL, ...)
      - pattern: requests.post($URL, ...)
      - pattern: httpx.get($URL, ...)
      - pattern: aiohttp.ClientSession().get($URL, ...)
      - pattern: urllib.request.urlopen($URL)
```

### 3.4 CodeQL Custom Queries

> **Query Location**: `.codeql/queries/mcp/`

#### 3.4.1 .codeql/codeql-config.yml

```yaml
name: "MCP Security Configuration"

queries:
  - uses: security-and-quality
  - uses: ./.codeql/queries/mcp/

paths-ignore:
  - '**/tests/**'
  - '**/test_*.py'
  - '**/node_modules/**'
```

#### 3.4.2 .codeql/queries/mcp/tool-injection.ql

```ql
/**
 * @name MCP Tool Argument Injection
 * @description Tracks flow from MCP tool arguments to dangerous sinks
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.0
 * @precision high
 * @id mcp/tool-injection
 * @tags security
 *       external/cwe/cwe-78
 *       mcp
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.dataflow.new.TaintTracking
import semmle.python.ApiGraphs

/**
 * A source of untrusted data from MCP tool arguments
 */
class McpToolArgumentSource extends DataFlow::Node {
  McpToolArgumentSource() {
    exists(Function f, Parameter p |
      // Function named with 'tool' pattern
      f.getName().matches("%tool%") and
      p = f.getArg(_) and
      p.getName() = "arguments" and
      this.asExpr() = p.asName().getAUse()
    )
  }
}

/**
 * A sink for command execution
 */
class CommandExecutionSink extends DataFlow::Node {
  CommandExecutionSink() {
    exists(Call c |
      c.getFunc().(Attribute).getName() = "run" and
      c.getFunc().(Attribute).getObject().(Name).getId() = "subprocess" and
      this.asExpr() = c.getArg(0)
    )
    or
    exists(Call c |
      c.getFunc().(Name).getId() = "system" and
      this.asExpr() = c.getArg(0)
    )
  }
}

class McpToolInjectionConfig extends TaintTracking::Configuration {
  McpToolInjectionConfig() { this = "McpToolInjectionConfig" }

  override predicate isSource(DataFlow::Node source) {
    source instanceof McpToolArgumentSource
  }

  override predicate isSink(DataFlow::Node sink) {
    sink instanceof CommandExecutionSink
  }
}

from McpToolInjectionConfig config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink.getNode(), source, sink,
  "MCP tool argument flows to command execution without sanitization"
```

### 3.5 MCP Sources and Sinks Reference

| Category | Sources | Sinks |
|----------|---------|-------|
| **Tools** | `arguments` dict, `name` param | File ops, subprocess, DB queries |
| **Resources** | `uri` param, template vars | File read, network fetch, path construction |
| **Prompts** | `arguments` dict | Any output (XSS if rendered) |
| **Transport** | Request body, headers | Response construction |

### 3.6 Pysa Configuration

```python
# .pyre/taint.config
{
  "sources": [
    {
      "name": "MCPToolInput",
      "comment": "Tool arguments from MCP client"
    },
    {
      "name": "MCPResourceURI",
      "comment": "Resource URI from MCP client"
    },
    {
      "name": "MCPPromptArgs",
      "comment": "Prompt arguments from MCP client"
    }
  ],
  "sinks": [
    {
      "name": "FileSystem",
      "comment": "File system operations"
    },
    {
      "name": "CommandExecution",
      "comment": "Shell/subprocess calls"
    },
    {
      "name": "NetworkRequest",
      "comment": "HTTP/network requests"
    },
    {
      "name": "SQLQuery",
      "comment": "Database queries"
    }
  ],
  "features": [
    {
      "name": "mcp-validated",
      "comment": "Input has been validated"
    }
  ],
  "rules": [
    {
      "name": "MCP Tool Injection",
      "code": 1001,
      "sources": ["MCPToolInput"],
      "sinks": ["FileSystem", "CommandExecution"],
      "message_format": "MCP tool input flows to {sink} without validation"
    },
    {
      "name": "MCP SSRF",
      "code": 1002,
      "sources": ["MCPResourceURI"],
      "sinks": ["NetworkRequest"],
      "message_format": "MCP resource URI flows to network request"
    },
    {
      "name": "MCP SQL Injection",
      "code": 1003,
      "sources": ["MCPToolInput", "MCPPromptArgs"],
      "sinks": ["SQLQuery"],
      "message_format": "MCP input flows to SQL query"
    }
  ]
}
```

### 3.7 SARIF Aggregation

> **See**: [SARIF Strategy](../../docs/strategies/sarif-strategy.md) for detailed aggregation workflow.

This phase contributes SARIF files that are merged with Phase 16 outputs:

| Source | SARIF Artifact Name | Tool |
|--------|---------------------|------|
| security-taint.yml | sarif-codeql-python | CodeQL Python |
| security-taint.yml | sarif-codeql-javascript | CodeQL JavaScript |
| security-taint.yml | sarif-semgrep-taint | Semgrep Taint |
| security-taint-python.yml | sarif-pysa | Pysa |

### 3.8 Deduplication with Phase 16

Since both Phase 16 and Phase 20 may detect similar vulnerabilities (pattern vs dataflow), deduplication is handled by the SARIF aggregation workflow:

```yaml
# In sarif-aggregate.yml
- name: Deduplicate findings
  run: |
    python scripts/sarif-dedup.py \
      --priority-order "codeql,semgrep-taint,semgrep,pysa,bandit" \
      --input merged.sarif \
      --output deduped.sarif
```

**Priority**: CodeQL findings are preferred over Semgrep pattern findings for the same location, as CodeQL provides deeper analysis context.

---

## 4. Review & Validation

- [ ] CodeQL taint analysis completes successfully
- [ ] Semgrep taint rules detect test vulnerabilities
- [ ] Pysa configured and running
- [ ] Custom MCP queries functional
- [ ] SARIF aggregation includes taint findings
- [ ] Deduplication works with Phase 16
- [ ] No false negatives on known patterns
- [ ] Implementation tracking checklist updated
