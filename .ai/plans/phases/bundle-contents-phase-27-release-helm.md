---
id: 10252d3a-1d19-4bf7-ad39-e4288ac6a3e2
title: "Phase 27: Release - Helm"
status: pending
depends_on:
  - 045fa19d-a65d-4fca-b6e0-2a813af692a8  # phase-26
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 27: Release - Helm

## 1. Current State Assessment

- [ ] Check for existing Helm chart infrastructure
- [ ] Review chart template patterns
- [ ] Identify chart repository strategy
- [ ] Check for OCI registry support

### Existing Assets

None - Helm infrastructure not yet created.

### Gaps Identified

- [ ] lint-helm.yml
- [ ] test-helm.yml
- [ ] release-helm.yml
- [ ] publish-helm-oci.yml
- [ ] Chart templates for MCP servers

---

## 2. Contextual Goal

Implement Helm chart infrastructure using a centralized chart repository pattern. Create workflows for linting, testing with kind, releasing with chart-releaser, and publishing to OCI registries. Provide chart templates optimized for MCP server deployment.

### Chart Version vs App Version

> **Important**: Helm charts have two version fields with different purposes:
>
> | Field | Purpose | Updated By | Example |
> |-------|---------|------------|---------|
> | `version` | Chart version (chart changes) | Developer/chart-releaser | `0.1.5` |
> | `appVersion` | Application version (code changes) | semantic-release (Phase 24) | `1.3.0` |
>
> **Strategy**: The chart `version` is managed independently (can release chart updates
> without app changes). The `appVersion` is synced with git tags by `scripts/update-versions.sh`.

### Success Criteria

- [ ] Helm lint workflow functional
- [ ] Chart testing with kind works
- [ ] chart-releaser publishes to gh-pages
- [ ] OCI registry publishing works
- [ ] **appVersion synced with semantic-release**
- [ ] **Chart release triggered on GitHub release (not push)**
- [ ] MCP chart template provided

### Out of Scope

- Kubernetes deployment automation
- Helm operator/Flux integration

---

## 3. Implementation

### 3.1 lint-helm.yml

```yaml
name: Lint Helm Charts

on:
  push:
    paths:
      - 'charts/**'
  pull_request:
    paths:
      - 'charts/**'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Helm
        uses: azure/setup-helm@v4

      - name: Set up chart-testing
        uses: helm/chart-testing-action@v2

      - name: Lint charts
        run: ct lint --config .github/ct.yaml
```

### 3.2 test-helm.yml

```yaml
name: Test Helm Charts

on:
  push:
    paths:
      - 'charts/**'
  pull_request:
    paths:
      - 'charts/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Helm
        uses: azure/setup-helm@v4

      - name: Set up chart-testing
        uses: helm/chart-testing-action@v2

      - name: Create kind cluster
        uses: helm/kind-action@v1

      - name: Test charts
        run: ct install --config .github/ct.yaml
```

### 3.3 release-helm.yml

> **Note**: This workflow triggers on GitHub release (created by semantic-release in Phase 24),
> ensuring chart releases are synchronized with application releases. The `appVersion` in
> Chart.yaml is already updated by `scripts/update-versions.sh` before the release is created.

```yaml
name: Release Helm Charts

on:
  # Trigger on GitHub release - synced with semantic-release (Phase 24)
  release:
    types: [published]

  # Also allow chart-only releases via manual trigger
  workflow_dispatch:
    inputs:
      bump_chart_version:
        description: 'Bump chart version (patch/minor/major)'
        required: false
        type: choice
        options:
          - patch
          - minor
          - major

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.name "$GITHUB_ACTOR"
          git config user.email "$GITHUB_ACTOR@users.noreply.github.com"

      - name: Set up Helm
        uses: azure/setup-helm@v4

      - name: Bump chart version (manual only)
        if: github.event_name == 'workflow_dispatch' && inputs.bump_chart_version != ''
        run: |
          for chart in charts/*/Chart.yaml; do
            if [ -f "$chart" ]; then
              echo "Bumping $chart version (${{ inputs.bump_chart_version }})"

              # Extract current version
              CURRENT=$(grep '^version:' "$chart" | awk '{print $2}')
              IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

              case "${{ inputs.bump_chart_version }}" in
                major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
                minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
                patch) PATCH=$((PATCH + 1)) ;;
              esac

              NEW_VERSION="$MAJOR.$MINOR.$PATCH"
              sed -i "s/^version:.*/version: $NEW_VERSION/" "$chart"
              echo "  $CURRENT → $NEW_VERSION"
            fi
          done

          git add charts/*/Chart.yaml
          git commit -m "chore(helm): bump chart version [skip ci]"
          git push

      - name: Run chart-releaser
        uses: helm/chart-releaser-action@v1
        env:
          CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"

      - name: Generate release summary
        run: |
          echo "## Helm Chart Release" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          for chart in charts/*/Chart.yaml; do
            if [ -f "$chart" ]; then
              NAME=$(grep '^name:' "$chart" | awk '{print $2}')
              VERSION=$(grep '^version:' "$chart" | awk '{print $2}')
              APP_VERSION=$(grep '^appVersion:' "$chart" | awk '{print $2}' | tr -d '"')
              echo "| Chart | Version | App Version |" >> $GITHUB_STEP_SUMMARY
              echo "|-------|---------|-------------|" >> $GITHUB_STEP_SUMMARY
              echo "| $NAME | $VERSION | $APP_VERSION |" >> $GITHUB_STEP_SUMMARY
            fi
          done
```

### 3.4 publish-helm-oci.yml

```yaml
name: Publish Helm OCI

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Helm
        uses: azure/setup-helm@v4

      - name: Login to GHCR
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | \
            helm registry login ghcr.io -u ${{ github.actor }} --password-stdin

      - name: Package and push
        run: |
          helm package charts/mcp-server
          helm push mcp-server-*.tgz oci://ghcr.io/${{ github.repository }}/charts
```

### 3.5 MCP Server Chart Template

```yaml
# charts/mcp-server/Chart.yaml
apiVersion: v2
name: mcp-server
description: A Helm chart for MCP server deployment
type: application

# Chart version - managed independently, bumped via workflow_dispatch
# or when chart templates change
version: 0.1.0

# App version - synced with git tags by scripts/update-versions.sh (Phase 24)
# DO NOT manually edit - updated automatically by semantic-release
appVersion: "0.1.0"

maintainers:
  - name: maintainer
    email: maintainer@example.com
```

```yaml
# charts/mcp-server/values.yaml
replicaCount: 1

image:
  repository: ghcr.io/org/mcp-server
  # Default to appVersion from Chart.yaml if not specified
  # This ensures the container tag matches the release version
  tag: ""
  pullPolicy: IfNotPresent

transport:
  type: stdio  # stdio, sse, http, websocket
  port: 3000

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true

resources:
  limits:
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

```yaml
# charts/mcp-server/templates/deployment.yaml (excerpt)
# Shows how appVersion is used for image tag
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
```

---

## 4. Review & Validation

- [ ] Helm lint passes
- [ ] Chart installs in kind cluster
- [ ] chart-releaser creates releases on GitHub release
- [ ] **appVersion matches git tag after semantic-release**
- [ ] **chart version is independent and bump-able via workflow_dispatch**
- [ ] OCI registry contains charts
- [ ] Image tag defaults to appVersion in deployment template
- [ ] Implementation tracking checklist updated

---

## 5. Versioning Integration with Phase 24

This phase integrates with Phase 24 (Release - Versioning) for consistent versioning:

```
Phase 24: semantic-release
      │
      ├── Creates git tag: v1.3.0
      │
      └── scripts/update-versions.sh 1.3.0
           │
           └── Updates charts/*/Chart.yaml appVersion: "1.3.0"
                    │
                    ▼
Phase 27: release-helm.yml (triggered by release)
      │
      ├── chart-releaser packages chart
      │   └── Chart includes appVersion: "1.3.0"
      │
      └── publish-helm-oci.yml pushes to OCI
          └── oci://ghcr.io/org/repo/charts/mcp-server:0.1.5
              (chart version 0.1.5, app version 1.3.0)
```

**Key Points**:
- `version` in Chart.yaml = chart lifecycle (template changes)
- `appVersion` in Chart.yaml = application lifecycle (synced with git tags)
- Both workflows trigger on `release: [published]` for consistency
- Manual `workflow_dispatch` allows chart-only releases when needed
