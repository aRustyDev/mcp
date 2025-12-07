---
title: Tagging and Versioning Strategy
status: approved
date: 2025-12-05
decision-makers: [arustydev]
tags: [release, versioning, tagging, ci-cd, semantic-release]
related-phases: [24, 25, 26, 27]
---

# Tagging and Versioning Strategy

## Context

This document defines the versioning and tagging strategy for the MCP bundle. Multiple artifacts require version coordination: git tags, GitHub releases, container images, package manifests (Cargo.toml, package.json, pyproject.toml), and Helm charts. Without a clear strategy, version drift between these artifacts causes publishing failures and confusion.

## Terminology

| Term | Definition | Created By | Location |
|------|------------|------------|----------|
| **Version** | Semantic version number (1.2.3) | Determined by semantic-release | Abstract concept |
| **Git Tag** | Immutable pointer to commit SHA | semantic-release | `.git/refs/tags/` |
| **GitHub Release** | GitHub feature wrapping a git tag | semantic-release | GitHub API |
| **Package Version** | Version string in manifest file | `scripts/update-versions.sh` | Manifest files |
| **Container Tag** | Label on container image | `docker/metadata-action` | Container registry |
| **Chart Version** | Helm chart version | Developer/chart-releaser | `Chart.yaml` |
| **Chart appVersion** | Application version in chart | `scripts/update-versions.sh` | `Chart.yaml` |

### Relationship Diagram

```
                            VERSION (the number: 1.2.3)
                                      │
          ┌───────────────────────────┼───────────────────────────┐
          │                           │                           │
          ▼                           ▼                           ▼
    SOURCE CODE                  ARTIFACTS                   METADATA
          │                           │                           │
    ┌─────┴─────┐              ┌──────┴──────┐              ┌─────┴─────┐
    │           │              │             │              │           │
    ▼           ▼              ▼             ▼              ▼           ▼
 Git Tag    Manifests     Container     Packages      GitHub      Changelog
 v1.2.3    Cargo.toml    ghcr.io/x:    crates.io     Release     CHANGELOG.md
           package.json    1.2.3       pypi/npm
           pyproject.toml
           Chart.yaml
```

## Decision

### Single Source of Truth

**The git tag created by semantic-release is the single source of truth for versioning.**

All package manifests are updated by semantic-release to match the git tag version before any publishing occurs.

### Version Flow

```
Commit to main
      │
      ▼
semantic-release analyzes commits
      │
      ├── Determines next version: 1.3.0
      │
      ├── Runs: scripts/update-versions.sh 1.3.0
      │         ├── Updates Cargo.toml
      │         ├── Updates package.json
      │         ├── Updates pyproject.toml
      │         └── Updates Chart.yaml appVersion
      │
      ├── Commits: "chore(release): 1.3.0 [skip ci]"
      │
      ├── Creates git tag: v1.3.0
      │
      └── Creates GitHub Release: v1.3.0
              │
              ▼
      Triggers Phase 25/26/27 workflows
              │
              ├── publish-container.yml → tags from git ref
              ├── publish-rust.yml → reads Cargo.toml (now 1.3.0)
              ├── publish-python.yml → reads pyproject.toml (now 1.3.0)
              ├── publish-node.yml → reads package.json (now 1.3.0)
              └── publish-helm-oci.yml → reads Chart.yaml
```

### Tool Responsibilities

| Phase | Tool | Responsibility | Trigger |
|-------|------|----------------|---------|
| 24 | **semantic-release** | Determine version, create tag, create release | `push` to main |
| 24 | **scripts/update-versions.sh** | Update all manifest files | Called by semantic-release |
| 24 | **release-drafter** | Categorize PRs (NOT version resolution) | `pull_request` |
| 24 | **version-check.yml** | Detect version drift | `push`, `pull_request` |
| 25 | **docker/metadata-action** | Generate container tags from git ref | `release: [published]` |
| 26 | **cargo publish** | Publish to crates.io (reads Cargo.toml) | `release: [published]` |
| 26 | **pypa/gh-action-pypi-publish** | Publish to PyPI (reads pyproject.toml) | `release: [published]` |
| 26 | **npm publish** | Publish to npm (reads package.json) | `release: [published]` |
| 27 | **chart-releaser** | Create Helm release | `release: [published]` |
| 27 | **helm push** | Publish to OCI registry | `release: [published]` |

### Version Determination

semantic-release determines version bumps from conventional commit messages:

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `fix:` | Patch (0.0.X) | `fix: resolve null pointer` |
| `feat:` | Minor (0.X.0) | `feat: add new endpoint` |
| `BREAKING CHANGE:` | Major (X.0.0) | Footer or `feat!:` |
| `chore:`, `docs:`, `style:` | No release | `docs: update README` |

### Helm Chart Versioning

Helm charts have two version fields with different lifecycles:

| Field | Purpose | Updated By | Lifecycle |
|-------|---------|------------|-----------|
| `version` | Chart version | Developer / workflow_dispatch | Chart template changes |
| `appVersion` | Application version | semantic-release | Synced with git tags |

**Strategy**: The chart `version` is managed independently (can release chart updates without app changes). The `appVersion` is synced with git tags by `scripts/update-versions.sh`.

Example:
```yaml
# Chart.yaml
version: 0.1.5      # Chart-specific version
appVersion: "1.3.0" # Synced with git tag v1.3.0
```

### Container Image Tags

Container images receive multiple tags for flexibility:

| Tag Pattern | Example | Use Case |
|-------------|---------|----------|
| Full semver | `1.3.0` | Immutable reference |
| Major.Minor | `1.3` | Latest patch in minor |
| Major only | `1` | Latest in major (careful!) |
| SHA | `sha-a1b2c3d` | Exact commit reference |
| `latest` | `latest` | Most recent release |

### Prerelease Support

semantic-release supports prerelease branches:

```json
{
  "branches": [
    "main",
    { "name": "beta", "prerelease": true },
    { "name": "alpha", "prerelease": true }
  ]
}
```

Prerelease versions: `1.3.0-beta.1`, `1.3.0-alpha.1`

## Conflicts Avoided

### 1. semantic-release vs Package Manifests

**Problem**: semantic-release creates git tags but doesn't update manifest files. Publishing workflows read manifests, causing version mismatch.

**Solution**: `scripts/update-versions.sh` updates all manifests before tag creation.

### 2. semantic-release vs release-drafter

**Problem**: Both tools resolve versions differently (commits vs PR labels).

**Solution**: release-drafter version resolution disabled. Used only for PR categorization.

### 3. Helm chart-releaser Independent Versioning

**Problem**: chart-releaser triggered on push, not release, causing unsynchronized releases.

**Solution**: Changed to trigger on `release: [published]`, ensuring coordination with semantic-release.

## Drift Detection

The `version-check.yml` workflow validates consistency:

```yaml
on:
  pull_request:
  push:
    branches: [main]
    paths:
      - 'Cargo.toml'
      - 'package.json'
      - 'pyproject.toml'
      - 'charts/*/Chart.yaml'
```

- Extracts versions from all manifests
- Compares for consistency
- Warns on PRs, fails on main branch drift

## Implementation Files

| File | Phase | Purpose |
|------|-------|---------|
| `.github/workflows/semantic-release.yml` | 24 | Version determination and release |
| `.releaserc.json` | 24 | semantic-release configuration |
| `scripts/update-versions.sh` | 24 | Manifest update script |
| `.github/workflows/release-drafter.yml` | 24 | PR categorization |
| `.github/release-drafter.yml` | 24 | release-drafter config |
| `.github/workflows/version-check.yml` | 24 | Drift detection |
| `.github/workflows/publish-container.yml` | 25 | Container publishing |
| `.github/workflows/publish-rust.yml` | 26 | crates.io publishing |
| `.github/workflows/publish-python.yml` | 26 | PyPI publishing |
| `.github/workflows/publish-node.yml` | 26 | npm publishing |
| `.github/workflows/release-helm.yml` | 27 | Helm chart release |
| `.github/workflows/publish-helm-oci.yml` | 27 | Helm OCI publishing |

## Developer Guidelines

### Do

- Use conventional commit messages (`feat:`, `fix:`, etc.)
- Let semantic-release handle all version bumps
- Use `workflow_dispatch` for chart-only releases when needed
- Check version-check.yml results on PRs

### Don't

- Manually edit version numbers in manifest files
- Create git tags manually (use semantic-release)
- Use release-drafter for version determination
- Push directly to main (use PRs for proper versioning)

## Consequences

### Positive

- Single source of truth prevents version drift
- Automated versioning reduces human error
- All artifacts consistently versioned
- Drift detection catches issues early
- Prerelease support for staged rollouts

### Negative

- Additional complexity in release process
- `scripts/update-versions.sh` must be maintained for new manifest types
- semantic-release plugins add dependencies
- Helm chart version vs appVersion distinction requires understanding

### Mitigations

- Clear documentation (this document)
- version-check.yml catches issues
- Helm chart versioning documented in Phase 27
- Prerelease branches allow testing release process

## References

- [semantic-release documentation](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [release-drafter](https://github.com/release-drafter/release-drafter)
- [Helm Chart Versioning](https://helm.sh/docs/topics/charts/#the-chartyaml-file)
- [docker/metadata-action](https://github.com/docker/metadata-action)
- Phase 24: Release - Versioning
- Phase 25: Release - Containers
- Phase 26: Release - Packages
- Phase 27: Release - Helm
