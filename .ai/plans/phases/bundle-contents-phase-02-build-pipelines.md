---
id: 173e85b4-ff31-4f5f-bc87-f09a8067a75b
title: "Phase 02: Build Pipelines"
status: pending
depends_on:
  - 367b75a1-dd7d-4d34-9bf9-6aaab692c2ee  # phase-01
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 02: Build Pipelines

## 1. Current State Assessment

- [ ] Check for existing build workflows
- [ ] Review caching strategies in place
- [ ] Identify supported language versions
- [ ] Check for matrix build configurations

### Existing Assets

None - build workflows not yet created.

### Gaps Identified

- [ ] Container build workflow (multi-arch)
- [ ] Rust build workflow (stable, beta, nightly)
- [ ] Python build workflow (3.10, 3.11, 3.12)
- [ ] Node build workflow (18, 20, 22)
- [ ] mdBook build workflow

---

## 2. Contextual Goal

Create standardized build workflows for all supported languages and platforms. Each workflow should include proper caching, matrix builds across supported versions, artifact uploads, and path-based triggering to avoid unnecessary builds. The container workflow must support multi-architecture builds (amd64, arm64) using buildx.

### Success Criteria

- [ ] All 5 build workflows created and validated
- [ ] Caching configured for each language
- [ ] Matrix builds cover all supported versions
- [ ] Path filters prevent unnecessary runs
- [ ] Artifacts uploaded with appropriate retention

### Out of Scope

- Linting (Phase 03)
- Testing (Phase 04+)
- Publishing (Phase 25-26)

---

## 3. Implementation

### 3.1 build-container.yml

```yaml
# Features:
# - Multi-arch builds (linux/amd64, linux/arm64)
# - Layer caching via GHA cache
# - Metadata extraction for tags
# - SBOM and provenance generation
# - Push only on non-PR events
```

Key steps:
- Setup QEMU for multi-arch
- Setup Docker Buildx
- Login to GHCR (non-PR only)
- Extract metadata for tags
- Build and push with caching

### 3.2 build-rust.yml

```yaml
# Features:
# - Matrix: stable, beta, nightly on ubuntu/macos/windows
# - cargo caching via Swatinem/rust-cache
# - Format check on stable only
# - Release build on stable only
# - Minimal versions check
```

### 3.3 build-python.yml

```yaml
# Features:
# - Matrix: Python 3.10, 3.11, 3.12 on ubuntu/macos/windows
# - pip caching
# - Build wheel and sdist
# - Artifact upload
```

### 3.4 build-node.yml

```yaml
# Features:
# - Matrix: Node 18, 20, 22
# - Auto-detect package manager (npm/pnpm/yarn)
# - Appropriate caching per manager
# - Build and artifact upload
```

### 3.5 build-mdbook.yml

```yaml
# Features:
# - Build mdBook documentation
# - Install common plugins (mermaid, toc, linkcheck)
# - Link validation
# - Artifact upload
```

---

## 4. Review & Validation

- [ ] All workflows pass `actionlint`
- [ ] Path filters work correctly
- [ ] Caching provides measurable speedup
- [ ] Matrix covers all supported versions
- [ ] Artifacts are correctly named and uploaded
- [ ] Implementation tracking checklist updated
