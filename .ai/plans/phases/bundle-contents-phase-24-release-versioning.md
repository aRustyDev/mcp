---
id: 0b4c7d81-ee56-43dd-b14d-9af8a7a8759c
title: "Phase 24: Release - Versioning"
status: pending
depends_on:
  - dfeca409-20f3-46f0-94d3-c8e1c8f6fb19  # phase-23
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 24: Release - Versioning

## 1. Current State Assessment

- [ ] Check for existing versioning strategy
- [ ] Review semantic-release configuration
- [ ] Identify changelog generation
- [ ] Check for release drafter usage

### Existing Assets

Conventional commits (Phase 01) enable automated versioning.

### Gaps Identified

- [ ] semantic-release.yml workflow
- [ ] .releaserc.json configuration
- [ ] scripts/update-versions.sh (manifest updater)
- [ ] release-drafter.yml workflow (PR categorization only)
- [ ] .github/release-drafter.yml config (version resolution disabled)
- [ ] version-check.yml (drift detection)

---

## 2. Contextual Goal

Implement automated semantic versioning based on conventional commits. Use semantic-release to determine version bumps, generate changelogs, create GitHub releases, tag releases, **and update all package manifest files**. The git tag is the single source of truth for versioning.

### Version Source of Truth

> **IMPORTANT**: The git tag created by semantic-release is the single source of truth.
>
> All package manifests (Cargo.toml, package.json, pyproject.toml, Chart.yaml)
> are updated by semantic-release to match the git tag version.
>
> ```
> semantic-release determines version from commits
>          │
>          ├── Creates Git Tag: v1.3.0
>          ├── Creates GitHub Release: v1.3.0
>          ├── Updates CHANGELOG.md
>          └── Updates ALL package manifests:
>               ├── Cargo.toml
>               ├── package.json
>               ├── pyproject.toml
>               └── charts/*/Chart.yaml (appVersion)
> ```
>
> **Do not manually edit version numbers in manifest files.**

### Success Criteria

- [ ] Automatic version bumping from commits
- [ ] Changelog generated from commit messages
- [ ] GitHub releases created automatically
- [ ] **All package manifests updated to match git tag**
- [ ] **Version consistency validated in CI**
- [ ] Breaking changes trigger major bumps
- [ ] Prerelease branches supported (optional)

### Out of Scope

- Package publishing (Phase 26)
- Container tagging (Phase 25)

---

## 3. Implementation

### 3.1 semantic-release.yml

```yaml
name: Semantic Release

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install semantic-release
        run: npm install -g semantic-release @semantic-release/changelog @semantic-release/git

      - name: Run semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: npx semantic-release
```

### 3.2 .releaserc.json

```json
{
  "branches": [
    "main",
    { "name": "beta", "prerelease": true },
    { "name": "alpha", "prerelease": true }
  ],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/changelog",
      {
        "changelogFile": "CHANGELOG.md"
      }
    ],
    [
      "@semantic-release/exec",
      {
        "prepareCmd": "scripts/update-versions.sh ${nextRelease.version}"
      }
    ],
    [
      "@semantic-release/git",
      {
        "assets": [
          "CHANGELOG.md",
          "Cargo.toml",
          "Cargo.lock",
          "package.json",
          "package-lock.json",
          "pyproject.toml",
          "charts/*/Chart.yaml"
        ],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ],
    "@semantic-release/github"
  ]
}
```

### 3.3 scripts/update-versions.sh

Version update script called by semantic-release:

```bash
#!/usr/bin/env bash
# scripts/update-versions.sh
# Updates all package manifests to the specified version
set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

echo "Updating versions to: $VERSION"

# Rust: Cargo.toml
if [ -f "Cargo.toml" ]; then
  echo "  → Cargo.toml"
  sed -i.bak "s/^version = \".*\"/version = \"$VERSION\"/" Cargo.toml
  rm -f Cargo.toml.bak
  # Update Cargo.lock if it exists
  if [ -f "Cargo.lock" ]; then
    cargo update --workspace 2>/dev/null || true
  fi
fi

# Node: package.json
if [ -f "package.json" ]; then
  echo "  → package.json"
  # Use npm version to properly update package.json and package-lock.json
  npm version "$VERSION" --no-git-tag-version --allow-same-version 2>/dev/null || \
    sed -i.bak "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" package.json
  rm -f package.json.bak
fi

# Python: pyproject.toml
if [ -f "pyproject.toml" ]; then
  echo "  → pyproject.toml"
  sed -i.bak "s/^version = \".*\"/version = \"$VERSION\"/" pyproject.toml
  rm -f pyproject.toml.bak
fi

# Helm: Chart.yaml (update appVersion, not version)
# Chart version can be managed independently or synced
for chart in charts/*/Chart.yaml; do
  if [ -f "$chart" ]; then
    echo "  → $chart (appVersion)"
    sed -i.bak "s/^appVersion:.*/appVersion: \"$VERSION\"/" "$chart"
    rm -f "${chart}.bak"
  fi
done

echo "Version update complete: $VERSION"
```

### 3.4 release-drafter.yml (Optional - PR Labeling Only)

> **Note**: release-drafter is configured for **PR categorization only**, not version resolution.
> Version determination is handled exclusively by semantic-release from commit messages.
>
> **Why?** release-drafter resolves versions from PR labels, while semantic-release
> resolves from commit messages. Using both for versioning causes conflicts.

```yaml
name: Release Drafter

on:
  pull_request:
    types: [opened, reopened, synchronize, labeled, unlabeled]

permissions:
  contents: read
  pull-requests: write

jobs:
  update_release_draft:
    runs-on: ubuntu-latest
    steps:
      - uses: release-drafter/release-drafter@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3.5 .github/release-drafter.yml

```yaml
# NOTE: Version resolution DISABLED - semantic-release is the source of truth
# release-drafter is used only for PR categorization and draft notes

name-template: 'v$RESOLVED_VERSION'
tag-template: 'v$RESOLVED_VERSION'

categories:
  - title: 'Breaking Changes'
    labels:
      - 'breaking'
  - title: 'Features'
    labels:
      - 'type:feature'
      - 'enhancement'
  - title: 'Bug Fixes'
    labels:
      - 'type:bug'
      - 'bugfix'
  - title: 'Security'
    labels:
      - 'security'
  - title: 'Documentation'
    labels:
      - 'type:docs'
      - 'documentation'
  - title: 'Maintenance'
    labels:
      - 'chore'
      - 'dependencies'

# VERSION RESOLUTION DISABLED
# semantic-release determines version from commit messages, not PR labels
# Uncommenting this would cause conflicts with semantic-release
#
# version-resolver:
#   major:
#     labels:
#       - 'breaking'
#   minor:
#     labels:
#       - 'type:feature'
#   patch:
#     labels:
#       - 'type:bug'
#   default: patch

template: |
  ## Changes

  $CHANGES

  ## Contributors

  $CONTRIBUTORS

  ---
  *Note: Final version determined by semantic-release from commit messages.*
```

### 3.6 version-check.yml

Validates version consistency across all package manifests:

```yaml
name: Version Consistency Check

on:
  pull_request:
  push:
    branches: [main]
    paths:
      - 'Cargo.toml'
      - 'package.json'
      - 'pyproject.toml'
      - 'charts/*/Chart.yaml'

jobs:
  check-versions:
    name: Validate Version Consistency
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract versions from manifests
        id: versions
        run: |
          # Extract version from each manifest (if exists)
          CARGO_VER="N/A"
          PKG_VER="N/A"
          PY_VER="N/A"
          CHART_APP_VER="N/A"

          if [ -f "Cargo.toml" ]; then
            CARGO_VER=$(grep -m1 '^version' Cargo.toml | sed 's/.*"\(.*\)".*/\1/' || echo "N/A")
          fi

          if [ -f "package.json" ]; then
            PKG_VER=$(jq -r '.version // "N/A"' package.json 2>/dev/null || echo "N/A")
          fi

          if [ -f "pyproject.toml" ]; then
            PY_VER=$(grep -m1 '^version' pyproject.toml | sed 's/.*"\(.*\)".*/\1/' || echo "N/A")
          fi

          # Get appVersion from first Chart.yaml found
          CHART_FILE=$(find charts -name 'Chart.yaml' -type f 2>/dev/null | head -1)
          if [ -n "$CHART_FILE" ]; then
            CHART_APP_VER=$(grep -m1 '^appVersion:' "$CHART_FILE" | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/' || echo "N/A")
          fi

          echo "cargo=$CARGO_VER" >> $GITHUB_OUTPUT
          echo "npm=$PKG_VER" >> $GITHUB_OUTPUT
          echo "python=$PY_VER" >> $GITHUB_OUTPUT
          echo "helm=$CHART_APP_VER" >> $GITHUB_OUTPUT

      - name: Generate version report
        run: |
          echo "## Version Consistency Report" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Manifest | Version |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|---------|" >> $GITHUB_STEP_SUMMARY
          echo "| Cargo.toml | \`${{ steps.versions.outputs.cargo }}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| package.json | \`${{ steps.versions.outputs.npm }}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| pyproject.toml | \`${{ steps.versions.outputs.python }}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| Chart.yaml (appVersion) | \`${{ steps.versions.outputs.helm }}\` |" >> $GITHUB_STEP_SUMMARY

      - name: Check for version drift
        run: |
          # Collect all non-N/A versions
          VERSIONS=""
          for v in "${{ steps.versions.outputs.cargo }}" \
                   "${{ steps.versions.outputs.npm }}" \
                   "${{ steps.versions.outputs.python }}" \
                   "${{ steps.versions.outputs.helm }}"; do
            if [ "$v" != "N/A" ]; then
              VERSIONS="$VERSIONS $v"
            fi
          done

          # Count unique versions
          UNIQUE=$(echo $VERSIONS | tr ' ' '\n' | sort -u | grep -v '^$' | wc -l)

          if [ "$UNIQUE" -gt 1 ]; then
            echo "" >> $GITHUB_STEP_SUMMARY
            echo "### ⚠️ Version Drift Detected" >> $GITHUB_STEP_SUMMARY
            echo "" >> $GITHUB_STEP_SUMMARY
            echo "Multiple different versions found across manifests." >> $GITHUB_STEP_SUMMARY
            echo "This may indicate:" >> $GITHUB_STEP_SUMMARY
            echo "- Manual version edit (should use semantic-release)" >> $GITHUB_STEP_SUMMARY
            echo "- Failed release process" >> $GITHUB_STEP_SUMMARY
            echo "- Missing manifest update in scripts/update-versions.sh" >> $GITHUB_STEP_SUMMARY
            echo "" >> $GITHUB_STEP_SUMMARY
            echo "::warning::Version mismatch detected: $(echo $VERSIONS | tr ' ' '\n' | sort -u | tr '\n' ' ')"

            # Fail on main branch, warn on PRs
            if [ "${{ github.ref }}" == "refs/heads/main" ]; then
              echo "::error::Version drift on main branch - this should not happen"
              exit 1
            fi
          else
            echo "" >> $GITHUB_STEP_SUMMARY
            echo "### ✅ Versions Consistent" >> $GITHUB_STEP_SUMMARY
            if [ -n "$(echo $VERSIONS | xargs)" ]; then
              echo "All manifests report version: \`$(echo $VERSIONS | awk '{print $1}')\`" >> $GITHUB_STEP_SUMMARY
            fi
          fi
```

---

## 4. Review & Validation

- [ ] Version bumps correctly from commits
- [ ] Changelog includes all changes
- [ ] GitHub releases created
- [ ] **All package manifests updated by semantic-release**
- [ ] **scripts/update-versions.sh handles all manifest types**
- [ ] **version-check.yml detects drift correctly**
- [ ] Release notes are readable
- [ ] Prerelease branches work (beta, alpha)
- [ ] release-drafter categorizes PRs without version resolution
- [ ] Implementation tracking checklist updated

---

## 5. Terminology Clarification

| Term | Definition | Created By |
|------|------------|------------|
| **Version** | Semantic version number (1.2.3) | Determined by semantic-release |
| **Git Tag** | Immutable pointer to commit (`v1.2.3`) | semantic-release via `@semantic-release/github` |
| **GitHub Release** | GitHub feature wrapping git tag | semantic-release via `@semantic-release/github` |
| **Package Version** | Version in manifest file | `scripts/update-versions.sh` |
| **Container Tag** | Label on container image | `docker/metadata-action` (Phase 25) |
| **Chart Version** | Version in `Chart.yaml` | Independent (chart lifecycle) |
| **Chart appVersion** | App version in `Chart.yaml` | `scripts/update-versions.sh` |

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
