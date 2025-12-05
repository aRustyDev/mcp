---
id: b357c053-9d64-4efa-a06f-34bdd138271e
title: "Phase 22: Security - Compliance"
status: pending
depends_on:
  - 6330d055-1bfd-46ec-9458-f006fff1e9b9  # phase-21
  - e9f0a1b2-c3d4-5e6f-7a8b-9c0d1e2f3a4b  # phase-22a (policy library)
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
  - 4e593fba-d836-4aa6-9a27-d833df63e90f  # gap-analysis
references:
  - ../../docs/strategies/policy-as-code.md  # Unified policy strategy
issues: []
---

# Phase 22: Security - Compliance

## 1. Current State Assessment

- [ ] Check for existing compliance workflows
- [ ] Review CIS benchmark coverage
- [ ] Identify compliance requirements
- [ ] Check for OPA/Conftest usage

### Existing Assets

Docker Bench (Phase 21) covers CIS for containers.

### Gaps Identified

- [ ] compliance-cis.yml (CIS benchmarks)
- [ ] compliance-pci.yml (PCI-DSS)
- [ ] compliance-hipaa.yml (HIPAA)
- [ ] OPA/Rego policy library
- [ ] Compliance documentation templates

---

## 2. Contextual Goal

Establish compliance checking workflows for common frameworks. Implement CIS benchmarks for infrastructure, PCI-DSS checklists for payment handling, and HIPAA checklists for health data. Use OPA/Rego for policy-as-code enforcement. Generate compliance evidence documentation automatically.

### Success Criteria

- [ ] CIS benchmark workflow functional
- [ ] PCI-DSS checklist automation
- [ ] HIPAA checklist automation
- [ ] OPA policies reusable
- [ ] Evidence documentation generated

### Out of Scope

- Full compliance audits (requires human review)
- SOC 2 / ISO 27001 (future phases)

---

## 3. Implementation

### 3.1 compliance-cis.yml

```yaml
name: CIS Compliance

on:
  schedule:
    - cron: '0 6 * * 1'
  workflow_dispatch:

jobs:
  docker-cis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Docker CIS Benchmark
        run: |
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            docker/docker-bench-security

      - name: Parse results
        run: |
          # Convert to machine-readable format

  kubernetes-cis:
    runs-on: ubuntu-latest
    if: false  # Enable when K8s is used
    steps:
      - name: Install kube-bench
        run: |
          curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.7.0/kube-bench_0.7.0_linux_amd64.tar.gz | tar xz

      - name: Run kube-bench
        run: ./kube-bench run --targets node
```

### 3.2 Compliance Policies (in policies/compliance/)

> **Policy Source**: These policies are part of the unified policy library (Phase 22a).
> See [Policy-as-Code Strategy](../../docs/strategies/policy-as-code.md) for policy patterns.

This phase contributes the following policies to the library:

**File**: `policies/compliance/cis/docker.rego`

```rego
# METADATA
# title: CIS Docker Benchmark Policies
# description: Policy checks aligned with CIS Docker Benchmark
# custom:
#   framework: CIS
#   version: "1.5.0"
#   phase: 22

package mcp.compliance.cis.docker

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# CIS 4.1 - Ensure a user for the container has been created
deny contains msg if {
    input.User == "root"
    msg := "CIS 4.1: Container must not run as root"
}

deny contains msg if {
    input.User == ""
    msg := "CIS 4.1: Container must specify a non-root user"
}

# CIS 4.2 - Ensure that containers use only trusted base images
# (Implemented in Phase 21 base-image-policy.yml)

# CIS 4.6 - Ensure that HEALTHCHECK instructions have been added
warn contains msg if {
    not input.Healthcheck
    msg := "CIS 4.6: Container should have HEALTHCHECK instruction"
}

# CIS 5.2 - Ensure SELinux security options are set
warn contains msg if {
    not input.SecurityOpt
    msg := "CIS 5.2: Container should have security options defined"
}

# CIS 5.4 - Ensure that privileged containers are not used
deny contains msg if {
    input.Privileged == true
    msg := "CIS 5.4: Container must not be privileged"
}

# CIS 5.12 - Ensure that the container's root filesystem is mounted as read only
warn contains msg if {
    input.ReadOnlyRootFilesystem != true
    msg := "CIS 5.12: Container should have read-only root filesystem"
}

# CIS 5.25 - Ensure that the container is restricted from acquiring additional privileges
deny contains msg if {
    not no_new_privileges(input)
    msg := "CIS 5.25: Container should not acquire additional privileges"
}

no_new_privileges(config) if {
    some opt in config.SecurityOpt
    opt == "no-new-privileges:true"
}

no_new_privileges(config) if {
    config.SecurityOpt == null
}
```

**File**: `policies/compliance/pci_dss.rego`

```rego
# METADATA
# title: PCI-DSS Compliance Checks
# description: Policy checks for PCI-DSS requirements
# custom:
#   framework: PCI-DSS
#   version: "4.0"
#   phase: 22

package mcp.compliance.pci_dss

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# PCI-DSS 2.2.1 - Configuration standards
deny contains msg if {
    input.Privileged == true
    msg := "PCI-DSS 2.2.1: Privileged containers violate configuration standards"
}

# PCI-DSS 8.3.1 - Strong authentication
warn contains msg if {
    some env in input.Env
    contains(env, "PASSWORD=")
    msg := "PCI-DSS 8.3.1: Passwords should not be in environment variables"
}

# PCI-DSS 10.2 - Audit logging
warn contains msg if {
    not has_logging_config(input)
    msg := "PCI-DSS 10.2: Container should have logging configuration"
}

has_logging_config(config) if {
    config.LogConfig
}

has_logging_config(config) if {
    config.Labels["logging"]
}
```

### 3.3 conftest-compliance.yml

```yaml
name: Compliance Policy Check

on:
  pull_request:
    paths:
      - 'Dockerfile*'
      - 'docker/**'
      - 'policies/compliance/**'
  schedule:
    - cron: '0 6 * * 1'  # Weekly compliance check

jobs:
  conftest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Conftest
        uses: instrumenta/conftest-action@master
        with:
          version: latest

      - name: Parse Dockerfile to JSON
        run: |
          # Use dockerfile-json or hadolint --format json
          docker run --rm -i hadolint/hadolint hadolint --format json - < Dockerfile > dockerfile.json || true

      - name: Run compliance checks
        run: |
          conftest test dockerfile.json \
            --policy policies/compliance/ \
            --data policies/data/ \
            --output github \
            --all-namespaces

      - name: Generate compliance report
        if: always()
        run: |
          echo "## Compliance Check Results" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "### Frameworks Checked" >> $GITHUB_STEP_SUMMARY
          echo "- CIS Docker Benchmark v1.5.0" >> $GITHUB_STEP_SUMMARY
          echo "- PCI-DSS v4.0 (container requirements)" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "See [Policy-as-Code Strategy](docs/strategies/policy-as-code.md) for details." >> $GITHUB_STEP_SUMMARY
```

### 3.3.1 Compliance Policy Tests

**File**: `policies/tests/compliance_test.rego`

```rego
package mcp.compliance_test

import data.mcp.compliance.cis.docker as cis
import data.mcp.compliance.pci_dss as pci

# CIS Docker tests
test_cis_deny_root_user if {
    result := cis.deny with input as {"User": "root"}
    count(result) == 1
}

test_cis_deny_empty_user if {
    result := cis.deny with input as {"User": ""}
    count(result) == 1
}

test_cis_allow_nonroot_user if {
    result := cis.deny with input as {"User": "1000:1000"}
    count(result) == 0
}

test_cis_deny_privileged if {
    result := cis.deny with input as {"Privileged": true}
    count(result) == 1
}

test_cis_warn_no_healthcheck if {
    result := cis.warn with input as {"User": "app"}
    some msg in result
    contains(msg, "HEALTHCHECK")
}

# PCI-DSS tests
test_pci_deny_privileged if {
    result := pci.deny with input as {"Privileged": true}
    count(result) == 1
}

test_pci_warn_password_env if {
    result := pci.warn with input as {
        "Env": ["APP_NAME=test", "PASSWORD=secret123"]
    }
    count(result) >= 1
}
```

### 3.4 Compliance Documentation

Generate evidence reports:
- Scan timestamps
- Tool versions
- Pass/fail status
- Remediation notes

---

## 4. Review & Validation

- [ ] CIS benchmarks run on schedule
- [ ] OPA policies enforce standards
- [ ] Evidence documentation generated
- [ ] No false positives
- [ ] Implementation tracking checklist updated
