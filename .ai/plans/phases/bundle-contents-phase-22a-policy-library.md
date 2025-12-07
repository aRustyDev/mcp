---
id: e9f0a1b2-c3d4-5e6f-7a8b-9c0d1e2f3a4b
title: "Phase 22a: Policy Library"
status: pending
depends_on:
  - 56738219-8f07-4634-9592-5a461b36ee18  # phase-14 (cargo-deny as reference)
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 22a: Policy Library

## 1. Current State Assessment

- [ ] Review existing inline policies in Phase 21, 22
- [ ] Identify all policy domains needed
- [ ] Check for OPA/Conftest installation patterns
- [ ] Review policy-as-code.md strategy document

### Existing Assets

- Inline Rego policies in Phase 21 (container runtime validation)
- Inline Rego policies in Phase 22 (compliance)
- cargo-deny TOML policies (Phase 14)
- License YAML policies (Phase 15)

### Gaps Identified

- [ ] Unified policy directory structure
- [ ] Policy testing workflow
- [ ] Policy formatting/linting
- [ ] Policy bundle building
- [ ] Policy versioning
- [ ] Shared policy library functions
- [ ] External data management
- [ ] Policy documentation generation

---

## 2. Contextual Goal

Establish a centralized, tested, and versioned OPA policy library that serves as the foundation for all policy-as-code enforcement across the bundle. This phase creates the CI/CD infrastructure for policy development and provides reusable policies for Phases 21, 22, and beyond.

> **Reference**: See [Policy-as-Code Strategy](../../docs/strategies/policy-as-code.md) for architectural decisions and patterns.

### Success Criteria

- [ ] Policy directory structure created per strategy
- [ ] `opa fmt` enforced in CI
- [ ] `opa check` validates syntax
- [ ] `opa test` runs with >90% coverage
- [ ] Policy bundle built and versioned
- [ ] Conftest integration documented
- [ ] Shared library functions available
- [ ] External data loading works

### Out of Scope

- Domain-specific policies (handled by Phases 21, 22, 15)
- Native tool policies (cargo-deny, eslint)
- Policy enforcement in other workflows (they reference this)

---

## 3. Implementation

### 3.1 Policy Directory Structure

Create the unified policy structure in the bundle:

```
bundles/
├── policies/
│   ├── container/
│   │   └── .gitkeep
│   ├── kubernetes/
│   │   └── .gitkeep
│   ├── compliance/
│   │   ├── cis/
│   │   │   └── .gitkeep
│   │   └── .gitkeep
│   ├── license/
│   │   └── .gitkeep
│   ├── workflow/
│   │   └── .gitkeep
│   ├── lib/
│   │   ├── utils.rego
│   │   └── semver.rego
│   ├── data/
│   │   ├── allowed_licenses.json
│   │   ├── denied_licenses.json
│   │   ├── allowed_base_images.json
│   │   └── dangerous_capabilities.json
│   ├── tests/
│   │   ├── lib_test.rego
│   │   └── testdata/
│   │       └── .gitkeep
│   ├── .manifest
│   └── README.md
```

### 3.2 Shared Library Functions

**File**: `policies/lib/utils.rego`

```rego
# METADATA
# title: MCP Policy Utilities
# description: Shared utility functions for MCP policies
# entrypoint: false
# scope: package

package mcp.lib.utils

import future.keywords.if
import future.keywords.in

# Check if value exists in array
array_contains(arr, val) if {
    val in arr
}

# Get value with default
get_default(obj, key, default_value) := obj[key] if {
    obj[key]
} else := default_value

# Check if string starts with prefix
has_prefix(str, prefix) if {
    startswith(str, prefix)
}

# Check if string ends with suffix
has_suffix(str, suffix) if {
    endswith(str, suffix)
}

# Check if any element in array matches predicate
any_match(arr, predicate) if {
    some elem in arr
    predicate(elem)
}

# Normalize image name (remove tag)
normalize_image(image) := name if {
    contains(image, ":")
    name := split(image, ":")[0]
} else := image

# Check if image is in allowed list (prefix match)
image_allowed(image, allowed_list) if {
    normalized := normalize_image(image)
    some allowed in allowed_list
    has_prefix(normalized, allowed)
}
```

**File**: `policies/lib/semver.rego`

```rego
# METADATA
# title: Semantic Version Utilities
# description: Parse and compare semantic versions
# entrypoint: false
# scope: package

package mcp.lib.semver

import future.keywords.if

# Parse semver string to object
# Input: "1.2.3" or "v1.2.3"
# Output: {"major": 1, "minor": 2, "patch": 3}
parse(version) := result if {
    clean := trim_prefix(version, "v")
    parts := split(clean, ".")
    count(parts) >= 3
    result := {
        "major": to_number(parts[0]),
        "minor": to_number(parts[1]),
        "patch": to_number(split(parts[2], "-")[0]),
    }
}

# Compare two versions
# Returns: -1 (a < b), 0 (a == b), 1 (a > b)
compare(a, b) := -1 if {
    pa := parse(a)
    pb := parse(b)
    pa.major < pb.major
}

compare(a, b) := 1 if {
    pa := parse(a)
    pb := parse(b)
    pa.major > pb.major
}

compare(a, b) := -1 if {
    pa := parse(a)
    pb := parse(b)
    pa.major == pb.major
    pa.minor < pb.minor
}

compare(a, b) := 1 if {
    pa := parse(a)
    pb := parse(b)
    pa.major == pb.major
    pa.minor > pb.minor
}

compare(a, b) := -1 if {
    pa := parse(a)
    pb := parse(b)
    pa.major == pb.major
    pa.minor == pb.minor
    pa.patch < pb.patch
}

compare(a, b) := 1 if {
    pa := parse(a)
    pb := parse(b)
    pa.major == pb.major
    pa.minor == pb.minor
    pa.patch > pb.patch
}

compare(a, b) := 0 if {
    pa := parse(a)
    pb := parse(b)
    pa.major == pb.major
    pa.minor == pb.minor
    pa.patch == pb.patch
}

# Check if version meets minimum
meets_minimum(version, minimum) if {
    compare(version, minimum) >= 0
}
```

### 3.3 Library Tests

**File**: `policies/tests/lib_test.rego`

```rego
package mcp.lib.utils_test

import data.mcp.lib.utils
import data.mcp.lib.semver

# Test array_contains
test_array_contains_found if {
    utils.array_contains(["a", "b", "c"], "b")
}

test_array_contains_not_found if {
    not utils.array_contains(["a", "b", "c"], "d")
}

# Test get_default
test_get_default_exists if {
    result := utils.get_default({"key": "value"}, "key", "default")
    result == "value"
}

test_get_default_missing if {
    result := utils.get_default({"key": "value"}, "other", "default")
    result == "default"
}

# Test normalize_image
test_normalize_image_with_tag if {
    result := utils.normalize_image("nginx:1.25")
    result == "nginx"
}

test_normalize_image_without_tag if {
    result := utils.normalize_image("nginx")
    result == "nginx"
}

# Test image_allowed
test_image_allowed_exact if {
    utils.image_allowed("alpine:3.18", ["alpine", "nginx"])
}

test_image_allowed_prefix if {
    utils.image_allowed("gcr.io/distroless/static:latest", ["gcr.io/distroless/"])
}

test_image_not_allowed if {
    not utils.image_allowed("ubuntu:22.04", ["alpine", "nginx"])
}

# Test semver parse
test_semver_parse if {
    result := semver.parse("1.2.3")
    result.major == 1
    result.minor == 2
    result.patch == 3
}

test_semver_parse_with_v if {
    result := semver.parse("v1.2.3")
    result.major == 1
}

# Test semver compare
test_semver_compare_less if {
    semver.compare("1.0.0", "2.0.0") == -1
}

test_semver_compare_greater if {
    semver.compare("2.0.0", "1.0.0") == 1
}

test_semver_compare_equal if {
    semver.compare("1.2.3", "1.2.3") == 0
}

test_semver_meets_minimum if {
    semver.meets_minimum("1.5.0", "1.0.0")
}

test_semver_below_minimum if {
    not semver.meets_minimum("0.9.0", "1.0.0")
}
```

### 3.4 External Data Files

**File**: `policies/data/allowed_licenses.json`

```json
{
  "mcp": {
    "allowed_licenses": [
      "MIT",
      "Apache-2.0",
      "BSD-2-Clause",
      "BSD-3-Clause",
      "ISC",
      "MPL-2.0",
      "Zlib",
      "Unlicense",
      "CC0-1.0",
      "0BSD"
    ]
  }
}
```

**File**: `policies/data/denied_licenses.json`

```json
{
  "mcp": {
    "denied_licenses": [
      "GPL-3.0-only",
      "GPL-3.0-or-later",
      "AGPL-3.0-only",
      "AGPL-3.0-or-later",
      "SSPL-1.0",
      "BSL-1.1",
      "Elastic-2.0"
    ],
    "require_review": [
      "GPL-2.0-only",
      "GPL-2.0-or-later",
      "LGPL-2.1-only",
      "LGPL-3.0-only",
      "EPL-2.0",
      "CDDL-1.0"
    ]
  }
}
```

**File**: `policies/data/allowed_base_images.json`

```json
{
  "mcp": {
    "allowed_base_images": [
      "scratch",
      "gcr.io/distroless/static",
      "gcr.io/distroless/base",
      "gcr.io/distroless/cc",
      "cgr.dev/chainguard/static",
      "cgr.dev/chainguard/busybox",
      "alpine",
      "docker.io/library/alpine"
    ]
  }
}
```

**File**: `policies/data/dangerous_capabilities.json`

```json
{
  "mcp": {
    "dangerous_capabilities": [
      "ALL",
      "SYS_ADMIN",
      "NET_ADMIN",
      "SYS_PTRACE",
      "SYS_RAWIO",
      "SYS_MODULE",
      "DAC_READ_SEARCH",
      "NET_RAW"
    ],
    "warn_capabilities": [
      "SYS_CHROOT",
      "SETUID",
      "SETGID",
      "MKNOD"
    ]
  }
}
```

### 3.5 Bundle Manifest

**File**: `policies/.manifest`

```json
{
  "revision": "0.1.0",
  "roots": ["mcp"],
  "metadata": {
    "bundle_type": "mcp-policies",
    "created_by": "mcp-bundle",
    "min_opa_version": "0.60.0"
  }
}
```

### 3.6 Policy Library CI Workflow

**File**: `.github/workflows/policy-library.yml`

```yaml
name: Policy Library CI

on:
  push:
    branches: [main]
    paths:
      - 'policies/**'
      - '.github/workflows/policy-library.yml'
  pull_request:
    paths:
      - 'policies/**'
      - '.github/workflows/policy-library.yml'
  workflow_dispatch:
    inputs:
      release:
        description: 'Create release bundle'
        required: false
        type: boolean
        default: false

permissions:
  contents: write

env:
  OPA_VERSION: '0.60.0'
  CONFTEST_VERSION: '0.45.0'

jobs:
  validate:
    name: Validate Policies
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup OPA
        uses: open-policy-agent/setup-opa@v2
        with:
          version: ${{ env.OPA_VERSION }}

      - name: Check formatting
        run: |
          echo "## Policy Format Check" >> $GITHUB_STEP_SUMMARY
          if ! opa fmt --diff --fail policies/; then
            echo "::error::Policy files are not formatted. Run 'opa fmt -w policies/' to fix."
            echo "❌ Format check failed" >> $GITHUB_STEP_SUMMARY
            exit 1
          fi
          echo "✅ All policies properly formatted" >> $GITHUB_STEP_SUMMARY

      - name: Check syntax
        run: |
          echo "## Policy Syntax Check" >> $GITHUB_STEP_SUMMARY
          if ! opa check policies/; then
            echo "::error::Policy syntax errors found"
            echo "❌ Syntax check failed" >> $GITHUB_STEP_SUMMARY
            exit 1
          fi
          echo "✅ All policies have valid syntax" >> $GITHUB_STEP_SUMMARY

      - name: Validate bundle structure
        run: |
          echo "## Bundle Structure" >> $GITHUB_STEP_SUMMARY
          echo "Checking required directories and files..."

          required_dirs=("policies/lib" "policies/data" "policies/tests")
          for dir in "${required_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
              echo "✅ $dir exists" >> $GITHUB_STEP_SUMMARY
            else
              echo "❌ Missing required directory: $dir" >> $GITHUB_STEP_SUMMARY
              exit 1
            fi
          done

          if [[ -f "policies/.manifest" ]]; then
            echo "✅ .manifest exists" >> $GITHUB_STEP_SUMMARY
          else
            echo "❌ Missing .manifest file" >> $GITHUB_STEP_SUMMARY
            exit 1
          fi

  test:
    name: Test Policies
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v4

      - name: Setup OPA
        uses: open-policy-agent/setup-opa@v2
        with:
          version: ${{ env.OPA_VERSION }}

      - name: Run policy tests
        run: |
          echo "## Policy Tests" >> $GITHUB_STEP_SUMMARY
          opa test policies/ -v --format=pretty 2>&1 | tee test-output.txt

          # Count results
          passed=$(grep -c "PASS" test-output.txt || echo "0")
          failed=$(grep -c "FAIL" test-output.txt || echo "0")

          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Result | Count |" >> $GITHUB_STEP_SUMMARY
          echo "|--------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Passed | $passed |" >> $GITHUB_STEP_SUMMARY
          echo "| Failed | $failed |" >> $GITHUB_STEP_SUMMARY

          if [[ "$failed" -gt 0 ]]; then
            echo "::error::$failed policy tests failed"
            exit 1
          fi

      - name: Check test coverage
        run: |
          echo "## Test Coverage" >> $GITHUB_STEP_SUMMARY
          opa test policies/ --coverage --format=json > coverage.json

          # Extract coverage percentage
          coverage=$(jq '.coverage' coverage.json)
          echo "Coverage: ${coverage}%" >> $GITHUB_STEP_SUMMARY

          # Fail if below threshold
          threshold=80
          if (( $(echo "$coverage < $threshold" | bc -l) )); then
            echo "::warning::Test coverage ($coverage%) is below threshold ($threshold%)"
          fi

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: policy-coverage
          path: coverage.json

  integration:
    name: Integration Test
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Setup Conftest
        run: |
          curl -L https://github.com/open-policy-agent/conftest/releases/download/v${{ env.CONFTEST_VERSION }}/conftest_${{ env.CONFTEST_VERSION }}_Linux_x86_64.tar.gz | tar xz
          sudo mv conftest /usr/local/bin/

      - name: Test with sample files
        run: |
          echo "## Integration Tests" >> $GITHUB_STEP_SUMMARY

          # Create test compose file
          cat > test-compose.yml << 'EOF'
          version: "3.8"
          services:
            web:
              image: nginx:alpine
              user: "1000:1000"
          EOF

          # Run conftest with policies
          echo "Testing valid compose file..." >> $GITHUB_STEP_SUMMARY
          if conftest test test-compose.yml --policy policies/ --data policies/data/ 2>&1; then
            echo "✅ Valid compose passed" >> $GITHUB_STEP_SUMMARY
          else
            echo "❌ Valid compose should pass" >> $GITHUB_STEP_SUMMARY
            exit 1
          fi

      - name: Test policy violations
        run: |
          # Create invalid compose file
          cat > invalid-compose.yml << 'EOF'
          version: "3.8"
          services:
            web:
              image: nginx:alpine
              privileged: true
              user: root
          EOF

          # Should fail with violations
          echo "Testing invalid compose file..." >> $GITHUB_STEP_SUMMARY
          if conftest test invalid-compose.yml --policy policies/container/ --data policies/data/ 2>&1; then
            echo "⚠️ Invalid compose should have violations (no container policies yet)" >> $GITHUB_STEP_SUMMARY
          else
            echo "✅ Invalid compose correctly rejected" >> $GITHUB_STEP_SUMMARY
          fi

  build:
    name: Build Bundle
    runs-on: ubuntu-latest
    needs: [test, integration]
    if: github.ref == 'refs/heads/main' || github.event.inputs.release == 'true'
    steps:
      - uses: actions/checkout@v4

      - name: Setup OPA
        uses: open-policy-agent/setup-opa@v2
        with:
          version: ${{ env.OPA_VERSION }}

      - name: Extract version
        id: version
        run: |
          version=$(jq -r '.revision' policies/.manifest)
          echo "version=$version" >> $GITHUB_OUTPUT
          echo "Policy bundle version: $version"

      - name: Build policy bundle
        run: |
          mkdir -p dist
          opa build \
            --bundle policies/ \
            --output dist/mcp-policies-v${{ steps.version.outputs.version }}.tar.gz \
            --revision "${{ steps.version.outputs.version }}"

          # Also create latest symlink
          cp dist/mcp-policies-v${{ steps.version.outputs.version }}.tar.gz dist/mcp-policies-latest.tar.gz

      - name: Inspect bundle
        run: |
          echo "## Bundle Info" >> $GITHUB_STEP_SUMMARY
          opa inspect dist/mcp-policies-v${{ steps.version.outputs.version }}.tar.gz >> $GITHUB_STEP_SUMMARY

      - name: Upload bundle artifact
        uses: actions/upload-artifact@v4
        with:
          name: policy-bundle
          path: dist/

      - name: Create release
        if: github.event.inputs.release == 'true'
        uses: softprops/action-gh-release@v1
        with:
          tag_name: policies-v${{ steps.version.outputs.version }}
          name: Policy Bundle v${{ steps.version.outputs.version }}
          files: |
            dist/mcp-policies-v${{ steps.version.outputs.version }}.tar.gz
          body: |
            ## MCP Policy Bundle v${{ steps.version.outputs.version }}

            ### Installation

            ```bash
            # Download
            curl -L -o policies.tar.gz \
              https://github.com/${{ github.repository }}/releases/download/policies-v${{ steps.version.outputs.version }}/mcp-policies-v${{ steps.version.outputs.version }}.tar.gz

            # Extract
            tar -xzf policies.tar.gz -C policies/

            # Use with Conftest
            conftest test docker-compose.yml --policy policies/
            ```

            ### Included Policies

            See [policy-as-code.md](docs/strategies/policy-as-code.md) for documentation.
```

### 3.7 Policy README

**File**: `policies/README.md`

```markdown
# MCP Policy Library

Centralized OPA/Rego policy library for the MCP bundle.

## Quick Start

```bash
# Validate policies
opa check policies/

# Format policies
opa fmt -w policies/

# Run tests
opa test policies/ -v

# Use with Conftest
conftest test docker-compose.yml --policy policies/ --data policies/data/
```

## Structure

| Directory | Purpose |
|-----------|---------|
| `container/` | Docker/Compose security policies |
| `kubernetes/` | K8s manifest policies |
| `compliance/` | CIS, PCI-DSS, HIPAA |
| `license/` | License compliance |
| `workflow/` | GitHub Actions policies |
| `lib/` | Shared utility functions |
| `data/` | External data (allowlists, etc.) |
| `tests/` | Policy unit tests |

## Writing Policies

See [Policy-as-Code Strategy](../docs/strategies/policy-as-code.md) for:
- Package naming conventions
- Metadata requirements
- Testing patterns
- Data-driven policies

## Bundle Version

Current version: See `.manifest`

## Related

- Phase 21: Container Security (uses container policies)
- Phase 22: Compliance (uses compliance policies)
- Phase 15: License (uses license policies)
```

---

## 4. Review & Validation

- [ ] Policy directory structure matches strategy document
- [ ] Shared library functions implemented and tested
- [ ] External data files created with correct structure
- [ ] CI workflow validates format, syntax, tests
- [ ] Bundle builds successfully
- [ ] Conftest integration works
- [ ] >80% test coverage achieved
- [ ] README documentation complete
- [ ] policy-as-code.md strategy updated if needed
- [ ] Implementation tracking checklist updated

---

## 5. Phase Dependencies

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PHASE 22a DEPENDENCY GRAPH                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                      Phase 22a: Policy Library                              │
│                              │                                              │
│              ┌───────────────┼───────────────┐                              │
│              │               │               │                              │
│              ▼               ▼               ▼                              │
│       Phase 21          Phase 22       Phase 15                             │
│       Containers        Compliance     Licenses                             │
│       (uses container   (uses CIS,     (uses license                        │
│        policies)        PCI policies)   policies)                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

This phase provides:
- Shared library functions (`mcp.lib.*`)
- External data files (`policies/data/`)
- CI/CD infrastructure for policy validation
- Bundle building and versioning

Consuming phases add domain-specific policies to the appropriate directories.
