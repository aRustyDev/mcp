---
id: 6330d055-1bfd-46ec-9458-f006fff1e9b9
title: "Phase 21: Security - Containers"
status: pending
depends_on:
  - 0e96d833-2d1f-4d8a-b7d3-3711ea49f320  # phase-20
  - e9f0a1b2-c3d4-5e6f-7a8b-9c0d1e2f3a4b  # phase-22a (policy library)
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - container-scanning-strategy-adr  # ADR for Grype-only decision
  - ../../docs/strategies/policy-as-code.md  # Unified policy strategy
issues: []
---

# Phase 21: Security - Containers

## 1. Current State Assessment

- [ ] Check for existing container scanning
- [ ] Review Dockerfile hardening practices
- [ ] Identify base image policies
- [ ] Check for runtime security configs

### Existing Assets

- Hadolint (Phase 03) lints Dockerfiles
- Container structure tests (Phase 04)

### Gaps Identified

- [ ] security-container.yml (Grype + Docker Bench)
- [ ] base-image-policy.yml (with scratch support)
- [ ] runtime-config-validation.yml (OPA/Conftest)
- [ ] image-size-check.yml
- [ ] Seccomp profile templates
- [ ] Container hardening checklist

---

## 2. Contextual Goal

Implement comprehensive container security scanning and hardening using SRP-compliant tooling. Use Grype exclusively for CVE scanning (not Trivy, which violates SRP by bundling multiple capabilities). Enforce base image policies including scratch images, verify CIS benchmarks with Docker Bench, validate runtime configs with OPA/Conftest, and enforce image size limits.

### Tool Selection Rationale

> **Decision**: Use Grype instead of Trivy for vulnerability scanning.
>
> **Rationale**: Trivy violates Single Responsibility Principle by combining CVE scanning, secret detection, misconfiguration scanning, IaC scanning, and license scanning into one tool. We prefer specialized tools:
>
> | Capability | Tool | Phase |
> |------------|------|-------|
> | CVE Scanning | **Grype** | 21 |
> | SBOM Generation | Syft | 23 |
> | Secret Scanning | Gitleaks | 17 |
> | Misconfiguration | Conftest/OPA | 21 |
> | License Scanning | cargo-deny, Syft | 15 |
>
> **Trade-offs**:
> - Grype v6 includes CISA KEV and EPSS data (Trivy doesn't)
> - Grype has fewer false positives (prioritizes GitHub Advisory over CPE)
> - Losing: Arch, AlmaLinux, Rocky Linux, Photon OS coverage (acceptable for MCP servers)
> - Losing: Go Vulnerability Database integration (add govulncheck separately if needed)

### Success Criteria

- [ ] Container scanning with Grype (CISA KEV + EPSS enabled)
- [ ] Base image allowlist enforced (including scratch)
- [ ] Docker Bench compliance checked
- [ ] Runtime configs validated with Conftest
- [ ] Image size limits enforced
- [ ] Seccomp profiles provided
- [ ] Non-root enforcement verified

### Out of Scope

- Kubernetes-specific security (deployment configs)
- Runtime monitoring (Falco)
- Trivy (replaced by specialized tools per SRP)

---

## 3. Implementation

### 3.1 security-container.yml

```yaml
name: Container Security

on:
  push:
    branches: [main]
    paths:
      - 'Dockerfile*'
      - 'docker/**'
  pull_request:
    paths:
      - 'Dockerfile*'
      - 'docker/**'
  schedule:
    - cron: '0 6 * * *'

env:
  IMAGE_NAME: app
  IMAGE_TAG: test
  # Grype v6 settings
  GRYPE_DB_AUTO_UPDATE: true
  GRYPE_DB_VALIDATE_AGE: true

jobs:
  grype:
    name: Vulnerability Scan (Grype)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }} .

      - name: Scan with Grype
        uses: anchore/scan-action@v4
        id: scan
        with:
          image: ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }}
          fail-build: true
          severity-cutoff: high
          output-format: sarif
          # v6 features: include KEV and EPSS data
          add-cpes-if-none: false  # Reduce false positives

      - name: Upload SARIF to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: ${{ steps.scan.outputs.sarif }}

      - name: Check for CISA KEV matches
        run: |
          # Grype v6 outputs KEV matches - fail if any found
          if grep -q '"kev":true' ${{ steps.scan.outputs.json }} 2>/dev/null; then
            echo "::error::Image contains vulnerabilities in CISA Known Exploited Vulnerabilities catalog"
            exit 1
          fi

  docker-bench:
    name: CIS Benchmark (Docker Bench)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }} .

      - name: Run Docker Bench
        run: |
          docker run --rm --net host --pid host --userns host --cap-add audit_control \
            -v /var/lib:/var/lib:ro \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            -v /etc:/etc:ro \
            -v "$(pwd)":/workspace:ro \
            docker/docker-bench-security \
            -c container_images \
            -i ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }} \
            -l /workspace/docker-bench-results.log

      - name: Check critical failures
        run: |
          if grep -E "\[WARN\].*4\.[0-9]+" docker-bench-results.log; then
            echo "::warning::Docker Bench found container image warnings"
          fi
          # Fail on critical container image checks
          if grep -E "\[WARN\].*4\.(1|2|3|6)" docker-bench-results.log; then
            echo "::error::Critical Docker Bench failures detected"
            exit 1
          fi

      - name: Upload results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: docker-bench-results
          path: docker-bench-results.log

  image-size:
    name: Image Size Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }} .

      - name: Check image size
        run: |
          SIZE_BYTES=$(docker image inspect ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }} --format='{{.Size}}')
          SIZE_MB=$((SIZE_BYTES / 1024 / 1024))

          echo "Image size: ${SIZE_MB}MB"

          # Configurable thresholds
          WARN_THRESHOLD=${IMAGE_SIZE_WARN_MB:-100}
          FAIL_THRESHOLD=${IMAGE_SIZE_FAIL_MB:-500}

          if [ "$SIZE_MB" -gt "$FAIL_THRESHOLD" ]; then
            echo "::error::Image size ${SIZE_MB}MB exceeds maximum allowed ${FAIL_THRESHOLD}MB"
            exit 1
          elif [ "$SIZE_MB" -gt "$WARN_THRESHOLD" ]; then
            echo "::warning::Image size ${SIZE_MB}MB exceeds recommended ${WARN_THRESHOLD}MB"
          else
            echo "::notice::Image size ${SIZE_MB}MB is within acceptable limits"
          fi

      - name: Analyze layers
        run: |
          echo "## Layer Analysis" >> $GITHUB_STEP_SUMMARY
          docker history ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }} --no-trunc --format "table {{.Size}}\t{{.CreatedBy}}" >> $GITHUB_STEP_SUMMARY
```

### 3.2 base-image-policy.yml

```yaml
name: Base Image Policy

on:
  pull_request:
    paths:
      - 'Dockerfile*'
      - '**/Dockerfile*'

jobs:
  check-base-image:
    name: Verify Base Image Allowlist
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Find all Dockerfiles
        id: find
        run: |
          FILES=$(find . -name 'Dockerfile*' -type f | tr '\n' ' ')
          echo "files=$FILES" >> $GITHUB_OUTPUT

      - name: Check base images
        run: |
          # Allowlist patterns (regex)
          # - scratch: Empty base for static binaries (Go, Rust)
          # - distroless: Google's minimal images
          # - chainguard: Hardened, SLSA-attested images
          # - alpine: Small, security-focused (use with caution)
          # - debian-slim: When alpine musl is incompatible
          ALLOWLIST=(
            "^scratch$"
            "^gcr\.io/distroless/"
            "^cgr\.dev/chainguard/"
            "^docker\.io/library/alpine:"
            "^alpine:"
            "^debian:.*-slim$"
            "^docker\.io/library/debian:.*-slim$"
            "^rust:.*-alpine"
            "^golang:.*-alpine"
            "^python:.*-slim"
            "^node:.*-alpine"
          )

          FAILED=0

          for dockerfile in ${{ steps.find.outputs.files }}; do
            echo "Checking: $dockerfile"

            # Extract all FROM instructions (handle multi-stage builds)
            BASES=$(grep -E '^FROM' "$dockerfile" | awk '{print $2}' | grep -v '^\$' || true)

            for base in $BASES; do
              # Skip build stage references (e.g., "FROM builder AS runtime")
              if echo "$base" | grep -qE '^[a-z]+$' && ! echo "$base" | grep -qE '^(scratch|alpine|debian|ubuntu|centos|fedora)$'; then
                echo "  Skipping build stage reference: $base"
                continue
              fi

              ALLOWED=0
              for pattern in "${ALLOWLIST[@]}"; do
                if echo "$base" | grep -qE "$pattern"; then
                  ALLOWED=1
                  echo "  ✅ $base (matches: $pattern)"
                  break
                fi
              done

              if [ "$ALLOWED" -eq 0 ]; then
                echo "  ❌ $base (not in allowlist)"
                FAILED=1
              fi
            done
          done

          if [ "$FAILED" -eq 1 ]; then
            echo ""
            echo "::error::One or more base images are not in the allowlist"
            echo ""
            echo "Allowed base images:"
            for pattern in "${ALLOWLIST[@]}"; do
              echo "  - $pattern"
            done
            exit 1
          fi

          echo "::notice::All base images are approved"
```

### 3.3 runtime-config-validation.yml

> **Policy Source**: This workflow uses policies from the unified policy library (Phase 22a).
> See [Policy-as-Code Strategy](../../docs/strategies/policy-as-code.md) for policy patterns.

```yaml
name: Runtime Config Validation

on:
  pull_request:
    paths:
      - 'docker-compose*.yml'
      - 'docker-compose*.yaml'
      - 'compose*.yml'
      - 'compose*.yaml'
      - '.docker/**'
      - 'policies/container/**'  # Re-validate on policy changes

jobs:
  conftest:
    name: Validate with Conftest/OPA
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Conftest
        uses: instrumenta/conftest-action@master
        with:
          version: latest

      - name: Find compose files
        id: find
        run: |
          FILES=$(find . -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'compose*.yml' -o -name 'compose*.yaml' | tr '\n' ' ')
          echo "files=$FILES" >> $GITHUB_OUTPUT

      - name: Validate compose files
        run: |
          for file in ${{ steps.find.outputs.files }}; do
            echo "Validating: $file"
            conftest test "$file" \
              --policy policies/container/ \
              --data policies/data/ \
              --output github \
              --all-namespaces
          done

      - name: Generate validation report
        if: always()
        run: |
          echo "## Container Config Validation" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "Policies from: \`policies/container/\`" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "See [Policy-as-Code Strategy](docs/strategies/policy-as-code.md) for details." >> $GITHUB_STEP_SUMMARY
```

### 3.3.1 Container Policies (in policies/container/)

> **Note**: These policies are implemented in the unified policy library (Phase 22a).
> This section documents the policies this phase contributes to the library.

**File**: `policies/container/privileged.rego`

```rego
# METADATA
# title: No Privileged Containers
# description: Containers must not run in privileged mode
# custom:
#   severity: high
#   phase: 21

package mcp.container.privileged

import future.keywords.contains
import future.keywords.if
import future.keywords.in

deny contains msg if {
    some name, service in input.services
    service.privileged == true
    msg := sprintf("Service '%s' must not run in privileged mode", [name])
}
```

**File**: `policies/container/root_user.rego`

```rego
# METADATA
# title: No Root User
# description: Containers must not run as root
# custom:
#   severity: high
#   phase: 21

package mcp.container.root_user

import future.keywords.contains
import future.keywords.if
import future.keywords.in

deny contains msg if {
    some name, service in input.services
    service.user == "root"
    msg := sprintf("Service '%s' must not run as root user", [name])
}

deny contains msg if {
    some name, service in input.services
    service.user == "0"
    msg := sprintf("Service '%s' must not run as UID 0", [name])
}

warn contains msg if {
    some name, service in input.services
    not service.user
    msg := sprintf("Service '%s' has no user specified (will run as root)", [name])
}
```

**File**: `policies/container/networking.rego`

```rego
# METADATA
# title: Network Isolation
# description: Containers must not use host networking
# custom:
#   severity: high
#   phase: 21

package mcp.container.networking

import future.keywords.contains
import future.keywords.if
import future.keywords.in

deny contains msg if {
    some name, service in input.services
    service.network_mode == "host"
    msg := sprintf("Service '%s' must not use host networking", [name])
}

deny contains msg if {
    some name, service in input.services
    service.pid == "host"
    msg := sprintf("Service '%s' must not use host PID namespace", [name])
}
```

**File**: `policies/container/capabilities.rego`

```rego
# METADATA
# title: Capability Restrictions
# description: Containers must not have dangerous capabilities
# custom:
#   severity: high
#   phase: 21

package mcp.container.capabilities

import future.keywords.contains
import future.keywords.if
import future.keywords.in

import data.mcp.dangerous_capabilities

deny contains msg if {
    some name, service in input.services
    some cap in service.cap_add
    cap in dangerous_capabilities
    msg := sprintf("Service '%s' has dangerous capability: %s", [name, cap])
}
```

**File**: `policies/container/resources.rego`

```rego
# METADATA
# title: Resource Limits
# description: Containers should have resource limits defined
# custom:
#   severity: medium
#   phase: 21

package mcp.container.resources

import future.keywords.contains
import future.keywords.if
import future.keywords.in

warn contains msg if {
    some name, service in input.services
    not service.deploy.resources.limits
    not service.mem_limit
    msg := sprintf("Service '%s' has no memory limits defined", [name])
}

warn contains msg if {
    some name, service in input.services
    not service.read_only
    msg := sprintf("Service '%s' does not have read-only root filesystem", [name])
}
```

**File**: `policies/container/volumes.rego`

```rego
# METADATA
# title: Volume Restrictions
# description: Containers must not mount dangerous volumes
# custom:
#   severity: critical
#   phase: 21

package mcp.container.volumes

import future.keywords.contains
import future.keywords.if
import future.keywords.in

deny contains msg if {
    some name, service in input.services
    some volume in service.volumes
    contains(volume, "docker.sock")
    msg := sprintf("Service '%s' mounts Docker socket - security risk", [name])
}
```

### 3.3.2 Container Policy Tests

**File**: `policies/tests/container_test.rego`

```rego
package mcp.container_test

import data.mcp.container.privileged
import data.mcp.container.root_user
import data.mcp.container.networking

# Privileged tests
test_deny_privileged if {
    result := privileged.deny with input as {
        "services": {"web": {"privileged": true}}
    }
    count(result) == 1
}

test_allow_non_privileged if {
    result := privileged.deny with input as {
        "services": {"web": {"privileged": false}}
    }
    count(result) == 0
}

# Root user tests
test_deny_root_user if {
    result := root_user.deny with input as {
        "services": {"web": {"user": "root"}}
    }
    count(result) == 1
}

test_deny_uid_zero if {
    result := root_user.deny with input as {
        "services": {"web": {"user": "0"}}
    }
    count(result) == 1
}

test_warn_no_user if {
    result := root_user.warn with input as {
        "services": {"web": {"image": "nginx"}}
    }
    count(result) == 1
}

# Networking tests
test_deny_host_network if {
    result := networking.deny with input as {
        "services": {"web": {"network_mode": "host"}}
    }
    count(result) == 1
}

test_deny_host_pid if {
    result := networking.deny with input as {
        "services": {"web": {"pid": "host"}}
    }
    count(result) == 1
}
```

### 3.4 Seccomp Profile

**File**: `configs/security/seccomp-default.json`

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "archMap": [
    {
      "architecture": "SCMP_ARCH_X86_64",
      "subArchitectures": ["SCMP_ARCH_X86", "SCMP_ARCH_X32"]
    },
    {
      "architecture": "SCMP_ARCH_AARCH64",
      "subArchitectures": ["SCMP_ARCH_ARM"]
    }
  ],
  "syscalls": [
    {
      "names": [
        "accept", "accept4", "access", "arch_prctl", "bind", "brk",
        "capget", "capset", "chdir", "chmod", "chown", "clock_gettime",
        "clone", "close", "connect", "dup", "dup2", "dup3", "epoll_create",
        "epoll_create1", "epoll_ctl", "epoll_pwait", "epoll_wait", "execve",
        "exit", "exit_group", "faccessat", "fadvise64", "fallocate", "fchmod",
        "fchown", "fcntl", "fdatasync", "flock", "fork", "fstat", "fstatfs",
        "fsync", "ftruncate", "futex", "getcwd", "getdents", "getdents64",
        "getegid", "geteuid", "getgid", "getgroups", "getpeername", "getpgid",
        "getpgrp", "getpid", "getppid", "getpriority", "getrandom", "getresgid",
        "getresuid", "getrlimit", "getrusage", "getsid", "getsockname",
        "getsockopt", "gettid", "gettimeofday", "getuid", "inotify_add_watch",
        "inotify_init", "inotify_init1", "inotify_rm_watch", "ioctl", "kill",
        "lchown", "link", "linkat", "listen", "lseek", "lstat", "madvise",
        "memfd_create", "mkdir", "mkdirat", "mknod", "mknodat", "mlock",
        "mlock2", "mlockall", "mmap", "mprotect", "mremap", "msync", "munlock",
        "munlockall", "munmap", "nanosleep", "newfstatat", "open", "openat",
        "pause", "pipe", "pipe2", "poll", "ppoll", "prctl", "pread64",
        "preadv", "preadv2", "prlimit64", "pselect6", "pwrite64", "pwritev",
        "pwritev2", "read", "readahead", "readlink", "readlinkat", "readv",
        "recvfrom", "recvmmsg", "recvmsg", "rename", "renameat", "renameat2",
        "restart_syscall", "rmdir", "rt_sigaction", "rt_sigpending",
        "rt_sigprocmask", "rt_sigqueueinfo", "rt_sigreturn", "rt_sigsuspend",
        "rt_sigtimedwait", "rt_tgsigqueueinfo", "sched_getaffinity",
        "sched_getparam", "sched_getscheduler", "sched_get_priority_max",
        "sched_get_priority_min", "sched_setaffinity", "sched_yield", "select",
        "sendfile", "sendmmsg", "sendmsg", "sendto", "setfsgid", "setfsuid",
        "setgid", "setgroups", "setitimer", "setpgid", "setpriority",
        "setregid", "setresgid", "setresuid", "setreuid", "setsid",
        "setsockopt", "set_robust_list", "set_tid_address", "setuid", "shutdown",
        "sigaltstack", "socket", "socketpair", "splice", "stat", "statfs",
        "statx", "symlink", "symlinkat", "sync", "sync_file_range", "tee",
        "tgkill", "time", "timer_create", "timer_delete", "timerfd_create",
        "timerfd_gettime", "timerfd_settime", "timer_getoverrun", "timer_gettime",
        "timer_settime", "times", "tkill", "truncate", "umask", "uname",
        "unlink", "unlinkat", "utime", "utimensat", "utimes", "vfork", "wait4",
        "waitid", "write", "writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### 3.5 Container Hardening Checklist

#### Build-Time Hardening

- [ ] Non-root user defined (`USER` directive)
- [ ] Multi-stage build used (smaller final image)
- [ ] No secrets in build args or layers
- [ ] `.dockerignore` excludes sensitive files
- [ ] Specific version tags used (not `:latest`)
- [ ] Base image from allowlist
- [ ] `HEALTHCHECK` defined

#### Runtime Hardening

- [ ] Read-only root filesystem (`read_only: true`)
- [ ] No privileged mode (`privileged: false`)
- [ ] Minimal capabilities (`cap_drop: [ALL]`)
- [ ] No host networking (`network_mode` not `host`)
- [ ] No host PID namespace (`pid` not `host`)
- [ ] Memory limits set (`mem_limit`)
- [ ] CPU limits set (`cpus`)
- [ ] Seccomp profile applied
- [ ] No Docker socket mount

---

## 4. Review & Validation

- [ ] Grype detects known vulnerabilities with CISA KEV flagging
- [ ] Base image policy blocks non-allowed images
- [ ] Base image policy allows `scratch` for static binaries
- [ ] Docker Bench passes critical checks (4.1, 4.2, 4.3, 4.6)
- [ ] Conftest validates compose files against OPA policies
- [ ] Image size check enforces thresholds
- [ ] Seccomp profiles don't break functionality
- [ ] Implementation tracking checklist updated

---

## 5. Vulnerability Prioritization Strategy

With Grype v6, we have multiple signals for prioritizing vulnerabilities:

### 5.1 Priority Matrix

| Signal | Source | Weight | Action |
|--------|--------|--------|--------|
| CISA KEV | Known exploited | **Critical** | Block deployment immediately |
| EPSS > 0.5 | Exploit prediction | High | Fix within 24 hours |
| CVSS >= 9.0 | Severity score | High | Fix within 7 days |
| CVSS >= 7.0 | Severity score | Medium | Fix within 30 days |
| CVSS < 7.0 | Severity score | Low | Track and plan |

### 5.2 Prioritization Workflow

```yaml
# Add to security-container.yml after Grype scan
- name: Prioritize vulnerabilities
  run: |
    # Parse Grype JSON output
    RESULTS="${{ steps.scan.outputs.json }}"

    # Count by priority
    KEV_COUNT=$(jq '[.matches[] | select(.vulnerability.kev == true)] | length' "$RESULTS")
    HIGH_EPSS=$(jq '[.matches[] | select(.vulnerability.epss > 0.5)] | length' "$RESULTS")
    CRITICAL=$(jq '[.matches[] | select(.vulnerability.severity == "Critical")] | length' "$RESULTS")

    echo "## Vulnerability Summary" >> $GITHUB_STEP_SUMMARY
    echo "| Priority | Count | Action |" >> $GITHUB_STEP_SUMMARY
    echo "|----------|-------|--------|" >> $GITHUB_STEP_SUMMARY
    echo "| CISA KEV (Active Exploit) | $KEV_COUNT | 🔴 Block |" >> $GITHUB_STEP_SUMMARY
    echo "| High EPSS (>50%) | $HIGH_EPSS | 🟠 24h fix |" >> $GITHUB_STEP_SUMMARY
    echo "| Critical CVSS | $CRITICAL | 🟡 7d fix |" >> $GITHUB_STEP_SUMMARY

    # Fail if any KEV vulnerabilities found
    if [ "$KEV_COUNT" -gt 0 ]; then
      echo "::error::Found $KEV_COUNT vulnerabilities in CISA KEV catalog"
      exit 1
    fi

    # Warn on high EPSS
    if [ "$HIGH_EPSS" -gt 0 ]; then
      echo "::warning::Found $HIGH_EPSS vulnerabilities with high exploit probability (EPSS > 50%)"
    fi
```

### 5.3 Why Not Multi-Scanner Reconciliation?

> **Previous approach**: Run both Grype and Trivy, reconcile conflicting results.
>
> **Current approach**: Single scanner (Grype) with multiple priority signals.
>
> **Rationale**:
> - Multi-scanner creates noise without clear prioritization
> - False positive reconciliation is complex and error-prone
> - Grype v6 provides sufficient signal diversity (KEV, EPSS, CVSS, vendor severity)
> - SRP: One tool for CVE scanning, multiple signals for prioritization
>
> If additional coverage is needed for specific ecosystems (Go stdlib, Arch Linux), add **targeted tools** rather than another general scanner.

---

## 6. Data Source Coverage Note

> **Note**: By choosing Grype over Trivy, we accept reduced coverage for:
>
> | OS/Source | Status | Mitigation |
> |-----------|--------|------------|
> | Arch Linux | Not covered | Not used for MCP servers |
> | AlmaLinux | Not covered | Use RHEL/CentOS base instead |
> | Rocky Linux | Not covered | Use RHEL/CentOS base instead |
> | Photon OS | Not covered | Not used for MCP servers |
> | Go stdlib vulns | Partial | Add `govulncheck` in Phase 04 if needed |
>
> **Gained capabilities in Grype v6**:
> - CISA Known Exploited Vulnerabilities (KEV) flagging
> - EPSS (Exploit Prediction Scoring System) risk scores
> - Reduced false positives via GitHub Advisory prioritization
