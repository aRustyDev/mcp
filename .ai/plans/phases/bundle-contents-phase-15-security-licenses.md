---
id: 998f42c0-584d-4dcb-8b02-07116f0f03e3
title: "Phase 15: Security - Licenses"
status: pending
depends_on:
  - 56738219-8f07-4634-9592-5a461b36ee18  # phase-14
  - e9f0a1b2-c3d4-5e6f-7a8b-9c0d1e2f3a4b  # phase-22a (policy library)
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - ../../docs/strategies/policy-as-code.md  # Unified policy strategy
issues: []
---

# Phase 15: Security - Licenses

## 1. Current State Assessment

- [ ] Check for existing license scanning
- [ ] Review allowed/denied license lists
- [ ] Identify SBOM requirements
- [ ] Check for REUSE compliance

### Existing Assets

cargo-deny (Phase 14) includes license checking for Rust.

### Gaps Identified

- [ ] security-license.yml (ScanCode)
- [ ] reuse-lint.yml (REUSE compliance)
- [ ] License policy configuration
- [ ] SBOM generation integration

---

## 2. Contextual Goal

Establish comprehensive license compliance checking across all dependencies. This includes scanning dependencies for license information using ScanCode, enforcing project-level compliance with REUSE, maintaining allowed/denied license lists, and correlating license data with SBOMs for complete visibility.

### Success Criteria

- [ ] ScanCode scans all dependencies
- [ ] REUSE compliance verified
- [ ] Allowed/denied license policy enforced
- [ ] License compatibility matrix documented
- [ ] SBOM contains license information

### Out of Scope

- SBOM generation (Phase 23 Attestation)
- Legal review of licenses

---

## 3. Implementation

### 3.1 security-license.yml

```yaml
name: License Compliance

on:
  push:
    branches: [main]
    paths:
      - '**/Cargo.toml'
      - '**/package.json'
      - '**/pyproject.toml'
      - '**/requirements*.txt'
  pull_request:
  schedule:
    - cron: '0 5 * * 1'  # Weekly

jobs:
  scancode:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup ScanCode
        run: |
          pip install scancode-toolkit

      - name: Scan licenses
        run: |
          scancode --license --license-text --json-pp licenses.json .

      - name: Check for denied licenses
        run: |
          # Parse licenses.json and check against policy

      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: license-scan
          path: licenses.json
```

### 3.2 reuse-lint.yml

```yaml
name: REUSE Compliance

on:
  push:
    branches: [main]
  pull_request:

jobs:
  reuse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: REUSE Compliance Check
        uses: fsfe/reuse-action@v3
```

### 3.3 License Policy

> **Policy Source**: License data is centralized in the unified policy library (Phase 22a).
> See [Policy-as-Code Strategy](../../docs/strategies/policy-as-code.md) for policy patterns.

#### 3.3.1 Native Tool Configuration (cargo-deny)

Rust-specific license checking remains in `deny.toml` (Phase 14) due to deep Cargo integration.

#### 3.3.2 Unified License Policies (in policies/license/)

For cross-language license enforcement and reporting, use OPA/Rego policies with shared data.

**File**: `policies/license/enforcement.rego`

```rego
# METADATA
# title: License Enforcement
# description: Enforce allowed/denied license policy across all languages
# custom:
#   phase: 15

package mcp.license.enforcement

import future.keywords.contains
import future.keywords.if
import future.keywords.in

import data.mcp.allowed_licenses
import data.mcp.denied_licenses
import data.mcp.require_review

# Deny packages with denied licenses
deny contains msg if {
    some pkg in input.packages
    pkg.license in denied_licenses
    msg := sprintf("Denied license '%s' found in package '%s'", [pkg.license, pkg.name])
}

# Warn on licenses requiring review
warn contains msg if {
    some pkg in input.packages
    pkg.license in require_review
    msg := sprintf("License '%s' in package '%s' requires legal review", [pkg.license, pkg.name])
}

# Warn on unknown licenses
warn contains msg if {
    some pkg in input.packages
    not pkg.license in allowed_licenses
    not pkg.license in denied_licenses
    not pkg.license in require_review
    msg := sprintf("Unknown license '%s' in package '%s' - please classify", [pkg.license, pkg.name])
}
```

**File**: `policies/license/compatibility.rego`

```rego
# METADATA
# title: License Compatibility
# description: Check license compatibility for distribution
# custom:
#   phase: 15

package mcp.license.compatibility

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Define compatibility matrix
# MIT is compatible with: MIT, BSD, Apache-2.0, MPL-2.0
mit_compatible := {"MIT", "BSD-2-Clause", "BSD-3-Clause", "Apache-2.0", "MPL-2.0", "ISC", "Zlib"}

# Apache-2.0 is NOT compatible with GPL-2.0 (one-way)
apache_incompatible := {"GPL-2.0-only", "GPL-2.0-or-later"}

deny contains msg if {
    input.project_license == "Apache-2.0"
    some pkg in input.packages
    pkg.license in apache_incompatible
    msg := sprintf("Apache-2.0 project cannot include GPL-2.0 package '%s'", [pkg.name])
}

warn contains msg if {
    input.project_license == "MIT"
    some pkg in input.packages
    not pkg.license in mit_compatible
    msg := sprintf("License '%s' in '%s' may have compatibility issues with MIT", [pkg.license, pkg.name])
}
```

#### 3.3.3 External Data Files

License lists are stored in `policies/data/` for easy updates without policy changes.

**File**: `policies/data/allowed_licenses.json`
(See Phase 22a for full content)

```json
{
  "mcp": {
    "allowed_licenses": [
      "MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause",
      "ISC", "MPL-2.0", "Zlib", "Unlicense", "CC0-1.0", "0BSD"
    ]
  }
}
```

**File**: `policies/data/denied_licenses.json`

```json
{
  "mcp": {
    "denied_licenses": [
      "GPL-3.0-only", "GPL-3.0-or-later",
      "AGPL-3.0-only", "AGPL-3.0-or-later",
      "SSPL-1.0", "BSL-1.1", "Elastic-2.0"
    ],
    "require_review": [
      "GPL-2.0-only", "GPL-2.0-or-later",
      "LGPL-2.1-only", "LGPL-3.0-only",
      "EPL-2.0", "CDDL-1.0"
    ]
  }
}
```

#### 3.3.4 Unified License Workflow

```yaml
# .github/workflows/license-policy.yml
name: Unified License Policy

on:
  pull_request:
    paths:
      - '**/Cargo.toml'
      - '**/package.json'
      - '**/pyproject.toml'
      - 'policies/license/**'
      - 'policies/data/*licenses*.json'

jobs:
  license-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup tools
        run: |
          pip install scancode-toolkit
          curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz
          sudo mv conftest /usr/local/bin/

      - name: Scan licenses
        run: |
          scancode --license --json-pp licenses.json .

      - name: Transform to policy input
        run: |
          # Transform ScanCode output to OPA input format
          jq '{
            project_license: "MIT",
            packages: [.files[] | select(.licenses) | {
              name: .path,
              license: .licenses[0].spdx_license_key
            }]
          }' licenses.json > license-input.json

      - name: Check license policy
        run: |
          conftest test license-input.json \
            --policy policies/license/ \
            --data policies/data/ \
            --output github
```

#### 3.3.5 License Policy Tests

**File**: `policies/tests/license_test.rego`

```rego
package mcp.license_test

import data.mcp.license.enforcement
import data.mcp.license.compatibility

# Test enforcement
test_deny_gpl3 if {
    result := enforcement.deny with input as {
        "packages": [{"name": "bad-pkg", "license": "GPL-3.0-only"}]
    } with data.mcp.denied_licenses as ["GPL-3.0-only"]
    count(result) == 1
}

test_allow_mit if {
    result := enforcement.deny with input as {
        "packages": [{"name": "good-pkg", "license": "MIT"}]
    } with data.mcp.denied_licenses as ["GPL-3.0-only"]
    count(result) == 0
}

test_warn_unknown if {
    result := enforcement.warn with input as {
        "packages": [{"name": "unknown-pkg", "license": "UNKNOWN-1.0"}]
    } with data.mcp.allowed_licenses as ["MIT"]
      with data.mcp.denied_licenses as ["GPL-3.0-only"]
      with data.mcp.require_review as []
    count(result) == 1
}

# Test compatibility
test_apache_gpl2_incompatible if {
    result := compatibility.deny with input as {
        "project_license": "Apache-2.0",
        "packages": [{"name": "gpl-pkg", "license": "GPL-2.0-only"}]
    }
    count(result) == 1
}
```

### 3.4 License Compatibility Matrix

| Your License | Compatible With |
|--------------|-----------------|
| MIT | MIT, BSD, Apache-2.0, MPL-2.0 |
| Apache-2.0 | MIT, BSD, Apache-2.0 |
| MPL-2.0 | MIT, BSD, Apache-2.0, MPL-2.0 |

---

## 4. Review & Validation

- [ ] ScanCode detects all licenses
- [ ] REUSE compliance passes
- [ ] Policy blocks denied licenses
- [ ] Compatibility matrix is accurate
- [ ] Implementation tracking checklist updated
