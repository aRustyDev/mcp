---
id: d8f1e2a3-4b5c-6d7e-8f9a-0b1c2d3e4f5a
title: "Policy-as-Code Strategy"
status: active
created: 2025-12-05
type: strategy
related:
  - ai-context.md
  - tagging-and-versioning.md
  - ../../plans/phases/bundle-contents-phase-22a-policy-library.md
---

# Policy-as-Code Strategy

## Overview

This document defines the strategy for implementing policy-as-code across the MCP bundle. The goal is to establish a unified, testable, and maintainable policy framework using Open Policy Agent (OPA) and Rego as the primary policy language.

---

## Philosophy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      POLICY-AS-CODE PRINCIPLES                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. DECLARATIVE         Policies describe WHAT, not HOW                     │
│  2. TESTABLE            Every policy has corresponding tests                │
│  3. VERSIONED           Policies follow semantic versioning                 │
│  4. DOCUMENTED          Self-documenting with metadata                      │
│  5. REUSABLE            Shared library, not copy-paste                      │
│  6. AUDITABLE           Decision logging for compliance                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Language Selection

### Primary: Rego (OPA)

Rego is the primary policy language for all JSON/YAML-based configurations.

**Use Rego for**:
- Container configurations (Dockerfile, docker-compose)
- Kubernetes manifests
- Terraform/OpenTofu
- GitHub Actions workflows
- Generic JSON/YAML validation
- License compliance (unified)
- Compliance frameworks (CIS, PCI-DSS, HIPAA)

**Why Rego**:
- Purpose-built for policy decisions
- Rich standard library
- Strong testing framework
- Active community and tooling
- Supports data-driven policies

### Native Tools (Keep As-Is)

Some domain-specific tools have superior native policy support:

| Tool | Domain | Keep Because |
|------|--------|--------------|
| `cargo-deny` | Rust dependencies | Deep Cargo.toml understanding, advisory DB integration |
| `cargo-vet` | Rust supply chain | Audit trail, community imports |
| `eslint` | JavaScript/TypeScript | AST-level analysis |
| `ruff` | Python | AST-level analysis |
| `clippy` | Rust | Compiler integration |

**Rule**: If a tool provides AST-level or compiler-level analysis, keep using it natively. Rego is for configuration validation, not code analysis.

---

## Unified Policy Structure

### Directory Layout

```
policies/
├── bundles/                      # Built policy bundles (gitignored)
│   └── mcp-policies-v1.0.0.tar.gz
│
├── container/                    # Container security policies
│   ├── privileged.rego          # No privileged containers
│   ├── root_user.rego           # No root user
│   ├── capabilities.rego        # Dangerous capability checks
│   ├── networking.rego          # Host networking restrictions
│   ├── volumes.rego             # Volume mount restrictions
│   ├── resources.rego           # Resource limit requirements
│   └── base_image.rego          # Allowed base images
│
├── kubernetes/                   # Kubernetes policies
│   ├── pod_security.rego        # Pod security standards
│   ├── network_policy.rego      # Network policy requirements
│   ├── rbac.rego                # RBAC best practices
│   └── resource_quotas.rego     # Resource quota enforcement
│
├── compliance/                   # Compliance framework policies
│   ├── cis/
│   │   ├── docker.rego          # CIS Docker Benchmark
│   │   └── kubernetes.rego      # CIS Kubernetes Benchmark
│   ├── pci_dss.rego             # PCI-DSS requirements
│   └── hipaa.rego               # HIPAA requirements
│
├── license/                      # License compliance policies
│   ├── enforcement.rego         # Allow/deny enforcement
│   └── compatibility.rego       # License compatibility checks
│
├── workflow/                     # CI/CD workflow policies
│   ├── actions.rego             # GitHub Actions security
│   └── secrets.rego             # Secret handling
│
├── lib/                          # Shared library functions
│   ├── utils.rego               # Common utilities
│   ├── semver.rego              # Semantic version parsing
│   └── strings.rego             # String manipulation
│
├── data/                         # External data for policies
│   ├── allowed_licenses.json    # License allowlist
│   ├── denied_licenses.json     # License denylist
│   ├── allowed_base_images.json # Base image allowlist
│   └── dangerous_capabilities.json
│
├── tests/                        # Policy tests
│   ├── container_test.rego
│   ├── kubernetes_test.rego
│   ├── compliance_test.rego
│   ├── license_test.rego
│   └── testdata/                # Test fixtures
│       ├── valid_compose.yaml
│       ├── invalid_compose.yaml
│       └── ...
│
├── .manifest                     # OPA bundle manifest
└── README.md                     # Policy documentation
```

### Package Naming Convention

```rego
# Pattern: mcp.{domain}.{subdomain}
package mcp.container.privileged
package mcp.container.root_user
package mcp.kubernetes.pod_security
package mcp.compliance.cis.docker
package mcp.license.enforcement
```

### Policy Metadata

Every policy file should include metadata:

```rego
# METADATA
# title: No Privileged Containers
# description: Containers must not run in privileged mode
# authors:
#   - MCP Bundle Team
# entrypoint: true
# scope: package
# schemas:
#   - input: schema.compose
# custom:
#   severity: high
#   remediation: Remove 'privileged: true' from service definition
#   references:
#     - https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities

package mcp.container.privileged

import future.keywords.contains
import future.keywords.if
import future.keywords.in
```

---

## Policy Patterns

### Standard Deny Pattern

```rego
package mcp.container.privileged

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny privileged containers in docker-compose
deny contains msg if {
    some name, service in input.services
    service.privileged == true
    msg := sprintf("Service '%s' must not run in privileged mode", [name])
}
```

### Standard Warn Pattern

```rego
package mcp.container.resources

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Warn on missing resource limits
warn contains msg if {
    some name, service in input.services
    not service.deploy.resources.limits
    not service.mem_limit
    msg := sprintf("Service '%s' has no memory limits defined", [name])
}
```

### Data-Driven Pattern

```rego
package mcp.container.capabilities

import future.keywords.contains
import future.keywords.if
import future.keywords.in

import data.mcp.dangerous_capabilities

# Deny dangerous capabilities using external data
deny contains msg if {
    some name, service in input.services
    some cap in service.cap_add
    cap in dangerous_capabilities
    msg := sprintf("Service '%s' has dangerous capability: %s", [name, cap])
}
```

### Shared Library Pattern

```rego
# policies/lib/utils.rego
package mcp.lib.utils

import future.keywords.if

# Check if value is in array
array_contains(arr, val) if {
    arr[_] == val
}

# Get with default
get_default(obj, key, default_value) := obj[key] if {
    obj[key]
} else := default_value
```

Using shared library:

```rego
package mcp.container.base_image

import data.mcp.lib.utils
import data.mcp.allowed_base_images

deny contains msg if {
    image := input.image
    not utils.array_contains(allowed_base_images, image)
    msg := sprintf("Base image '%s' is not in allowed list", [image])
}
```

---

## Testing Strategy

### Test File Structure

```rego
# policies/tests/container_test.rego
package mcp.container.privileged_test

import data.mcp.container.privileged

# Test: privileged container is denied
test_deny_privileged_container if {
    result := privileged.deny with input as {
        "services": {
            "web": {"privileged": true}
        }
    }
    count(result) == 1
    result[_] == "Service 'web' must not run in privileged mode"
}

# Test: non-privileged container is allowed
test_allow_non_privileged_container if {
    result := privileged.deny with input as {
        "services": {
            "web": {"privileged": false}
        }
    }
    count(result) == 0
}

# Test: missing privileged key defaults to allowed
test_allow_missing_privileged_key if {
    result := privileged.deny with input as {
        "services": {
            "web": {"image": "nginx"}
        }
    }
    count(result) == 0
}
```

### Test Data Files

```yaml
# policies/tests/testdata/valid_compose.yaml
version: "3.8"
services:
  web:
    image: nginx:alpine
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
    deploy:
      resources:
        limits:
          memory: 256M
```

```yaml
# policies/tests/testdata/invalid_compose.yaml
version: "3.8"
services:
  web:
    image: nginx:latest
    privileged: true
    user: root
    cap_add:
      - SYS_ADMIN
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

### Coverage Requirements

| Policy Domain | Minimum Coverage |
|---------------|-----------------|
| Container | 90% |
| Kubernetes | 90% |
| Compliance | 80% |
| License | 95% |
| Library | 100% |

---

## Versioning Strategy

### Semantic Versioning for Policies

```
MAJOR.MINOR.PATCH

MAJOR: Breaking changes (removed rules, changed deny→warn)
MINOR: New policies added (backward compatible)
PATCH: Bug fixes, documentation updates
```

### Version Tracking

```json
// policies/.manifest
{
  "revision": "1.2.0",
  "roots": ["mcp"],
  "metadata": {
    "created": "2025-12-05T00:00:00Z",
    "bundle_type": "mcp-policies"
  }
}
```

### Changelog

```markdown
# Policy Changelog

## [1.2.0] - 2025-12-05
### Added
- mcp.container.base_image: Allowed base image validation
- mcp.kubernetes.network_policy: Network policy requirements

### Changed
- mcp.container.resources: memory limit warning threshold from 128M to 256M

## [1.1.0] - 2025-11-15
### Added
- mcp.compliance.pci_dss: PCI-DSS compliance checks
```

---

## Integration Points

### Conftest Integration

```yaml
# .github/workflows/policy-check.yml
- name: Run Conftest
  run: |
    conftest test docker-compose.yml \
      --policy policies/ \
      --data policies/data/ \
      --output github \
      --all-namespaces
```

### OPA Eval for Testing

```bash
# Run all policy tests
opa test policies/ -v

# Run specific test
opa test policies/ -v -r 'test_deny_privileged'

# Check coverage
opa test policies/ --coverage --format=json
```

### Bundle Building

```bash
# Build policy bundle
opa build \
  --bundle policies/ \
  --output bundles/mcp-policies-v1.0.0.tar.gz \
  --revision "1.0.0"

# Verify bundle
opa inspect bundles/mcp-policies-v1.0.0.tar.gz
```

---

## Migration Guide

### From Inline Policies

**Before** (inline in workflow):
```yaml
- name: Create policy
  run: |
    cat > policy/container.rego << 'EOF'
    package main
    deny[msg] { ... }
    EOF
```

**After** (reference policy library):
```yaml
- name: Download policy bundle
  run: |
    curl -L -o policies.tar.gz \
      https://github.com/org/repo/releases/download/policies-v1.0.0/mcp-policies.tar.gz
    tar -xzf policies.tar.gz

- name: Run Conftest
  run: conftest test docker-compose.yml --policy policies/
```

### From cargo-deny License Policy

Keep `deny.toml` for Rust-specific dependency checks. Use the unified Rego policy for:
- Cross-language license reporting
- License compatibility analysis
- Compliance documentation

### From Custom Shell Scripts

**Before**:
```bash
# Check for allowed base images
if ! grep -q "FROM.*alpine\|FROM.*distroless" Dockerfile; then
  echo "Error: Must use alpine or distroless base"
  exit 1
fi
```

**After**:
```rego
package mcp.container.base_image

import data.mcp.allowed_base_images

deny contains msg if {
    instruction := input.Stages[_].Commands[_]
    instruction.Cmd == "from"
    image := instruction.Value[0]
    not image_allowed(image)
    msg := sprintf("Base image '%s' not in allowed list", [image])
}

image_allowed(image) if {
    some allowed in allowed_base_images
    startswith(image, allowed)
}
```

---

## External Data Management

### Data File Format

```json
// policies/data/allowed_base_images.json
{
  "mcp": {
    "allowed_base_images": [
      "scratch",
      "gcr.io/distroless/static",
      "gcr.io/distroless/cc",
      "alpine",
      "cgr.dev/chainguard/"
    ]
  }
}
```

### Loading External Data

```bash
# Local development
conftest test compose.yml --policy policies/ --data policies/data/

# CI/CD with remote data
conftest test compose.yml \
  --policy policies/ \
  --data https://example.com/policy-data/allowed_images.json
```

### Data Update Process

1. Update JSON file in `policies/data/`
2. Increment policy patch version
3. Run tests to verify no breakage
4. Build and release new bundle

---

## Exception Handling

### Annotation-Based Exceptions

```yaml
# docker-compose.yml
services:
  debug-sidecar:
    image: busybox
    privileged: true
    labels:
      # Policy exception annotation
      mcp.policy/exception: "privileged-allowed"
      mcp.policy/exception-reason: "Debug sidecar requires host access"
      mcp.policy/exception-expires: "2025-12-31"
      mcp.policy/exception-approved-by: "security-team"
```

```rego
package mcp.container.privileged

deny contains msg if {
    some name, service in input.services
    service.privileged == true
    not has_valid_exception(service)
    msg := sprintf("Service '%s' must not run in privileged mode", [name])
}

has_valid_exception(service) if {
    service.labels["mcp.policy/exception"] == "privileged-allowed"
    # Could add expiration check here
}
```

### Exception Registry

For tracking exceptions across the organization:

```json
// policies/data/exceptions.json
{
  "mcp": {
    "exceptions": {
      "privileged-allowed": {
        "description": "Allow privileged mode for specific use cases",
        "approved_by": "security-team",
        "valid_until": "2025-12-31",
        "services": ["debug-sidecar", "network-debug"]
      }
    }
  }
}
```

---

## Workflow Integration

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/open-policy-agent/conftest
    rev: v0.45.0
    hooks:
      - id: conftest
        args: ['test', '--policy', 'policies/', 'docker-compose.yml']
```

### GitHub Actions

```yaml
# Reference: Phase 22a implements this workflow
name: Policy Check

on:
  pull_request:
    paths:
      - 'docker-compose*.yml'
      - 'Dockerfile*'
      - 'k8s/**'
      - 'policies/**'

jobs:
  policy-check:
    uses: ./.github/workflows/policy-library.yml
```

---

## Metrics and Reporting

### Policy Evaluation Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| `policy_evaluations_total` | Total policy evaluations | N/A |
| `policy_violations_total` | Total violations found | Minimize |
| `policy_test_coverage` | Test coverage percentage | >90% |
| `policy_bundle_size` | Bundle size in bytes | <1MB |

### Compliance Reporting

```bash
# Generate compliance report
conftest test compose.yml \
  --policy policies/ \
  --output json \
  | jq '.[] | {file, violations: [.failures[].msg]}' \
  > compliance-report.json
```

---

## Related Documents

- [AI Context Strategy](ai-context.md) - How policies integrate with AI guidance
- [Tagging and Versioning Strategy](tagging-and-versioning.md) - Policy versioning alignment
- [Phase 22a: Policy Library](../../plans/phases/bundle-contents-phase-22a-policy-library.md) - Implementation phase

---

## Appendix: Quick Reference

### Common Commands

```bash
# Format all policies
opa fmt -w policies/

# Check syntax
opa check policies/

# Run all tests
opa test policies/ -v

# Run tests with coverage
opa test policies/ --coverage

# Build bundle
opa build -b policies/ -o bundle.tar.gz

# Evaluate policy locally
conftest test docker-compose.yml --policy policies/

# Verify with trace (debugging)
conftest test docker-compose.yml --policy policies/ --trace
```

### Conftest Output Formats

| Format | Use Case |
|--------|----------|
| `stdout` | Local development |
| `json` | Programmatic processing |
| `github` | GitHub Actions annotations |
| `junit` | CI/CD test reporting |
| `sarif` | Security tab integration |
