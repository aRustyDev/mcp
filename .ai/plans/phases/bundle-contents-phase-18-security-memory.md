---
id: c8643976-ddd4-4753-b307-b5b4db81b068
title: "Phase 18: Security - Memory"
status: pending
depends_on:
  - 9837e690-439f-42cb-811f-dbcff58a6af9  # phase-17
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - ../../docs/strategies/sast-strategy.md   # Phase boundary context
  - ../../docs/strategies/sarif-strategy.md  # SARIF integration
issues: []
---

# Phase 18: Security - Memory

## 1. Current State Assessment

- [ ] Check for existing Miri usage
- [ ] Review sanitizer configuration
- [ ] Identify unsafe code blocks
- [ ] Check for Valgrind usage

### Existing Assets

None - memory safety analysis not yet configured.

### Gaps Identified

- [ ] security-memory-rust.yml (Miri + sanitizers)
- [ ] cargo-careful integration
- [ ] RUSTFLAGS sanitizer matrix
- [ ] security-memory-native.yml (ASan/MSan/TSan)
- [ ] Valgrind workflow

---

## 2. Contextual Goal

Implement comprehensive memory safety analysis for Rust and native code. Use Miri for detecting undefined behavior in Rust, sanitizers (AddressSanitizer, MemorySanitizer, ThreadSanitizer) for runtime detection, cargo-careful for extra-strict checking, and Valgrind for native code profiling.

### Success Criteria

- [ ] Miri runs on all Rust tests
- [ ] Sanitizer matrix covers ASan, MSan, TSan
- [ ] cargo-careful checks pass
- [ ] Memory issues reported clearly
- [ ] No false positives in safe code

### Out of Scope

- Performance optimization
- Memory profiling for non-Rust code
- Static unsafe code counting (Phase 16 cargo-geiger)

### Phase Boundary

> **See**: [SAST Strategy](../../docs/strategies/sast-strategy.md) for detailed phase boundaries.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        PHASE 18 RESPONSIBILITIES                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  IN SCOPE (Dynamic Memory Analysis)                                          │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✓ Miri - Undefined behavior detection                                      │
│  ✓ AddressSanitizer - Buffer overflows, use-after-free                      │
│  ✓ MemorySanitizer - Uninitialized reads                                    │
│  ✓ ThreadSanitizer - Data races, deadlocks                                  │
│  ✓ LeakSanitizer - Memory leaks                                             │
│  ✓ cargo-careful - Extra runtime checks                                     │
│  ✓ Valgrind - Native code memory analysis                                   │
│                                                                              │
│  OUT OF SCOPE (Other Phases)                                                 │
│  ─────────────────────────────────────────────────────────────────────────  │
│  ✗ cargo-geiger (static unsafe audit) → Phase 16                            │
│  ✗ clippy unsafe lints → Phase 16                                           │
│  ✗ Fuzzing input generation → Phase 19                                      │
│                                                                              │
│  Analysis Type: DYNAMIC (runtime)                                            │
│  Execution Frequency: Weekly (scheduled)                                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Implementation

### 3.1 security-memory-rust.yml

```yaml
name: Rust Memory Safety

on:
  push:
    branches: [main]
    paths:
      - '**.rs'
      - 'Cargo.toml'
  pull_request:
    paths:
      - '**.rs'
  schedule:
    - cron: '0 4 * * 1'  # Weekly

jobs:
  miri:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@nightly
        with:
          components: miri

      - uses: Swatinem/rust-cache@v2

      - name: Run Miri
        run: cargo miri test
        env:
          MIRIFLAGS: -Zmiri-disable-isolation

  sanitizers:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        sanitizer: [address, memory, thread]

    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@nightly

      - name: Run with ${{ matrix.sanitizer }} sanitizer
        run: cargo test
        env:
          RUSTFLAGS: -Zsanitizer=${{ matrix.sanitizer }}
          RUSTDOCFLAGS: -Zsanitizer=${{ matrix.sanitizer }}

  cargo-careful:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@nightly

      - run: cargo install cargo-careful

      - name: Run cargo-careful
        run: cargo careful test
```

### 3.2 Sanitizer Matrix

| Sanitizer | Detects |
|-----------|---------|
| AddressSanitizer | Buffer overflows, use-after-free |
| MemorySanitizer | Uninitialized reads |
| ThreadSanitizer | Data races, deadlocks |
| LeakSanitizer | Memory leaks |

### 3.3 security-memory-native.yml

For native code (C/C++ FFI):

```yaml
name: Native Memory Safety

on:
  push:
    branches: [main]
    paths:
      - '**.c'
      - '**.cpp'
  schedule:
    - cron: '0 4 * * 1'

jobs:
  valgrind:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Valgrind
        run: sudo apt-get install -y valgrind

      - name: Run Valgrind
        run: valgrind --error-exitcode=1 ./target/release/binary
```

### 3.4 SARIF Integration

> **See**: [SARIF Strategy](../../docs/strategies/sarif-strategy.md) for aggregation details.

Memory safety findings are reported but not in standard SARIF format. Custom conversion is needed:

```yaml
# In security-memory-rust.yml
- name: Convert Miri output to SARIF
  if: failure()
  run: |
    python scripts/miri-to-sarif.py \
      --input miri-output.txt \
      --output miri.sarif

- name: Upload Miri SARIF
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: sarif-miri
    path: miri.sarif
```

**Note**: Memory safety findings typically indicate critical bugs that should always block.

---

## 4. Review & Validation

- [ ] Miri detects UB in test code
- [ ] Sanitizers run without crashes
- [ ] No false positives in clean code
- [ ] Clear error reporting
- [ ] SARIF conversion works for failures
- [ ] Implementation tracking checklist updated
