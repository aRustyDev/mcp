---
id: b3db6c9b-ec1e-4298-b8f5-2149afcd5050
title: "Phase 19: Security - Fuzzing"
status: pending
depends_on:
  - c8643976-ddd4-4753-b307-b5b4db81b068  # phase-18
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - ../../docs/strategies/sast-strategy.md   # Phase boundary context
  - ../../docs/strategies/sarif-strategy.md  # SARIF integration for crash reports
issues: []
---

# Phase 19: Security - Fuzzing

## 1. Current State Assessment

- [ ] Check for existing fuzz targets
- [ ] Review cargo-fuzz configuration
- [ ] Identify fuzzing corpus location
- [ ] Check for OSS-Fuzz integration

### Existing Assets

None - fuzzing not yet configured.

### Gaps Identified

- [ ] security-fuzz-rust.yml (cargo-fuzz + AFL++)
- [ ] security-fuzz-python.yml (Atheris + Hypothesis)
- [ ] security-fuzz-go.yml (go-fuzz)
- [ ] security-fuzz-api.yml (Schemathesis)
- [ ] MCP protocol fuzzer
- [ ] Fuzz corpus management
- [ ] Crash triage workflow

---

## 2. Contextual Goal

Implement comprehensive fuzzing for discovering edge cases and security vulnerabilities. Create language-specific fuzz targets, an MCP protocol fuzzer, and API fuzzers. Manage corpus storage for regression testing, automate crash triage, and integrate with OSS-Fuzz for continuous fuzzing.

### Success Criteria

- [ ] Fuzz targets for each language
- [ ] MCP protocol fuzzer operational
- [ ] API fuzzing with Schemathesis
- [ ] Corpus stored and versioned
- [ ] Crash triage automated

### Out of Scope

- OSS-Fuzz setup (requires separate process)
- Long-running fuzzing campaigns
- Static vulnerability detection (Phase 16, 20)

### Phase Boundary

> **See**: [SAST Strategy](../../docs/strategies/sast-strategy.md) for detailed phase boundaries.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        PHASE 19 RESPONSIBILITIES                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  IN SCOPE (Dynamic Fuzzing)                                                  │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✓ cargo-fuzz / libFuzzer - Rust parser fuzzing                             │
│  ✓ AFL++ - Coverage-guided fuzzing                                          │
│  ✓ Schemathesis - OpenAPI endpoint fuzzing                                  │
│  ✓ Atheris - Python fuzzing                                                 │
│  ✓ MCP protocol message fuzzing                                             │
│  ✓ Corpus management and crash triage                                       │
│                                                                              │
│  OUT OF SCOPE (Other Phases)                                                 │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✗ Pattern-based vulnerability detection → Phase 16                         │
│  ✗ Dataflow/taint analysis → Phase 20                                       │
│  ✗ Memory safety interpretation → Phase 18 (but crashes feed here)          │
│                                                                              │
│  Analysis Type: DYNAMIC (random input generation)                            │
│  Execution Frequency: Daily (scheduled, continuous for OSS-Fuzz)            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Integration with MCP Rules

Fuzzing targets should cover patterns identified in Phase 16 MCP rules:

| MCP Component | Fuzz Target | Related Semgrep Rule |
|---------------|-------------|----------------------|
| JSON-RPC Parser | `fuzz_target/json_rpc.rs` | mcp-protocol-validation |
| Resource URI | `fuzz_target/resource_uri.rs` | mcp-path-traversal |
| Tool Arguments | `fuzz_target/tool_args.rs` | mcp-command-injection |

---

## 3. Implementation

### 3.1 security-fuzz-rust.yml

```yaml
name: Rust Fuzzing

on:
  schedule:
    - cron: '0 3 * * *'  # Daily
  workflow_dispatch:
    inputs:
      duration:
        description: 'Fuzzing duration (seconds)'
        default: '300'

jobs:
  cargo-fuzz:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target: [parse_json, parse_request, tool_call]

    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@nightly

      - run: cargo install cargo-fuzz

      - name: Restore corpus
        uses: actions/cache@v4
        with:
          path: fuzz/corpus/${{ matrix.target }}
          key: fuzz-corpus-${{ matrix.target }}-${{ github.sha }}
          restore-keys: fuzz-corpus-${{ matrix.target }}-

      - name: Run fuzzer
        run: |
          cargo fuzz run ${{ matrix.target }} -- \
            -max_total_time=${{ inputs.duration || 300 }}
        continue-on-error: true

      - name: Upload crashes
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: crashes-${{ matrix.target }}
          path: fuzz/artifacts/${{ matrix.target }}
          if-no-files-found: ignore
```

### 3.2 security-fuzz-api.yml

```yaml
name: API Fuzzing

on:
  schedule:
    - cron: '0 4 * * 1'
  workflow_dispatch:

jobs:
  schemathesis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start API server
        run: docker compose up -d

      - name: Run Schemathesis
        run: |
          pip install schemathesis
          schemathesis run http://localhost:8080/openapi.json \
            --stateful=links \
            --checks all \
            --report schemathesis-report.json

      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: schemathesis-report
          path: schemathesis-report.json
```

### 3.3 MCP Protocol Fuzzer

```rust
// fuzz/fuzz_targets/mcp_protocol.rs
#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    if let Ok(s) = std::str::from_utf8(data) {
        // Try to parse as JSON-RPC request
        let _ = serde_json::from_str::<JsonRpcRequest>(s);
    }
});
```

### 3.4 Crash Triage

```yaml
name: Triage Crashes

on:
  workflow_run:
    workflows: ["Rust Fuzzing"]
    types: [completed]

jobs:
  triage:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    steps:
      - name: Download crashes
        uses: actions/download-artifact@v4

      - name: Deduplicate crashes
        run: |
          # Hash-based deduplication

      - name: Create issues
        run: |
          # Auto-create issues for new crashes
```

### 3.5 SARIF Integration for Crashes

> **See**: [SARIF Strategy](../../docs/strategies/sarif-strategy.md) for aggregation details.

Fuzz crashes are converted to SARIF for unified security reporting:

```yaml
# In crash-triage.yml
- name: Convert crashes to SARIF
  run: |
    python scripts/fuzz-crashes-to-sarif.py \
      --crashes-dir fuzz/artifacts/ \
      --output fuzz-crashes.sarif \
      --severity critical

- name: Upload crashes SARIF
  uses: actions/upload-artifact@v4
  with:
    name: sarif-fuzz-crashes
    path: fuzz-crashes.sarif
```

**Crash SARIF Format**:
```json
{
  "ruleId": "fuzz-crash-parse_json",
  "level": "error",
  "message": {
    "text": "Fuzzer found crash in parse_json target"
  },
  "properties": {
    "crash_input": "base64_encoded_input",
    "stack_trace": "...",
    "fuzz_target": "parse_json",
    "reproducer": "fuzz/artifacts/parse_json/crash-abc123"
  }
}
```

---

## 4. Review & Validation

- [ ] All fuzz targets run successfully
- [ ] Crashes are captured and triaged
- [ ] Corpus grows over time
- [ ] No crashes in stable code
- [ ] Crash SARIF reports generated
- [ ] Implementation tracking checklist updated
