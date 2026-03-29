---
id: b0116cbd-58d7-4a2e-8720-9d3860ad9232
title: "Phase 25: Release - Containers"
status: pending
depends_on:
  - 0b4c7d81-ee56-43dd-b14d-9af8a7a8759c  # phase-24
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 25: Release - Containers

## 1. Current State Assessment

- [ ] Check for existing container publishing
- [ ] Review registry configuration
- [ ] Identify tag strategies
- [ ] Check for multi-arch publishing

### Existing Assets

- Container build workflow (Phase 02)
- Container signing (Phase 23)

### Gaps Identified

- [ ] publish-container.yml (release publishing)
- [ ] Multi-registry support (GHCR + Docker Hub)
- [ ] Tag strategy configuration

---

## 2. Contextual Goal

Implement container publishing workflows that publish release images to GHCR and optionally Docker Hub. Tags should follow semantic versioning with additional tags for latest, major version, and SHA. Include attestations and SBOM from Phase 23.

### Success Criteria

- [ ] Publish to GHCR on release
- [ ] Optional Docker Hub publishing
- [ ] Semantic version tags applied
- [ ] Multi-arch images published
- [ ] Attestations attached

### Out of Scope

- Development/preview images (covered in Phase 02)
- Helm chart publishing (Phase 27)

---

## 3. Implementation

### 3.1 publish-container.yml

```yaml
name: Publish Container

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag:
        description: 'Image tag'
        required: true

env:
  REGISTRY_GHCR: ghcr.io
  REGISTRY_DOCKER: docker.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY_GHCR }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Login to Docker Hub
        if: secrets.DOCKERHUB_TOKEN != ''
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: |
            ${{ env.REGISTRY_GHCR }}/${{ env.IMAGE_NAME }}
            ${{ env.REGISTRY_DOCKER }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha

      - name: Build and push
        id: build
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          provenance: true
          sbom: true

      - name: Attest
        uses: actions/attest-build-provenance@v1
        with:
          subject-name: ${{ env.REGISTRY_GHCR }}/${{ env.IMAGE_NAME }}
          subject-digest: ${{ steps.build.outputs.digest }}
          push-to-registry: true

      - name: Sign with cosign
        run: |
          cosign sign --yes ${{ env.REGISTRY_GHCR }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}
```

### 3.2 Tag Strategy

| Event | Tags Applied |
|-------|--------------|
| Release v1.2.3 | `1.2.3`, `1.2`, `1`, `latest` |
| Release v2.0.0 | `2.0.0`, `2.0`, `2`, `latest` |
| Manual dispatch | Custom tag input |

---

## 4. Review & Validation

- [ ] Images publish to GHCR
- [ ] Docker Hub optional and working
- [ ] All expected tags present
- [ ] Multi-arch images functional
- [ ] Implementation tracking checklist updated
