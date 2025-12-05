---
id: b3db6c9b-ec1e-4298-b8f5-2149afcd5050
title: "Phase 19: Security - Fuzzing"
status: pending
depends_on:
  - c8643976-ddd4-4753-b307-b5b4db81b068  # phase-18
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
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

---

## 4. Review & Validation

- [ ] All fuzz targets run successfully
- [ ] Crashes are captured and triaged
- [ ] Corpus grows over time
- [ ] No crashes in stable code
- [ ] Implementation tracking checklist updated
