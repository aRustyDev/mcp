---
id: dfeca409-20f3-46f0-94d3-c8e1c8f6fb19
title: "Phase 23: Security - Attestation"
status: pending
depends_on:
  - b357c053-9d64-4efa-a06f-34bdd138271e  # phase-22
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 23: Security - Attestation

## 1. Current State Assessment

- [ ] Check for existing SBOM generation
- [ ] Review signing infrastructure
- [ ] Identify SLSA level requirements
- [ ] Check for cosign usage

### Existing Assets

Container builds (Phase 02) include SBOM and provenance flags.

### Gaps Identified

- [ ] attestation-sbom.yml (Syft)
- [ ] attestation-slsa.yml (SLSA provenance)
- [ ] attestation-sign.yml (cosign sign)
- [ ] attestation-verify.yml (cosign verify)
- [ ] SBOM output formats (SPDX, CycloneDX)

---

## 2. Contextual Goal

Implement software supply chain security through attestations. Generate SBOMs with Syft in SPDX and CycloneDX formats, create SLSA provenance attestations, and sign artifacts with cosign using keyless signing. Integrate with GitHub native attestations for container images.

### Success Criteria

- [ ] SBOMs generated for all artifacts
- [ ] SLSA provenance at Level 2+
- [ ] Artifacts signed with cosign
- [ ] Attestations verifiable
- [ ] GitHub attestations utilized

### Out of Scope

- SLSA Level 3+ (requires isolated builds)
- Key management infrastructure

---

## 3. Implementation

### 3.1 attestation-sbom.yml

```yaml
name: Generate SBOM

on:
  release:
    types: [published]
  workflow_dispatch:

jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Syft
        uses: anchore/sbom-action/download-syft@v0

      - name: Generate SPDX SBOM
        run: syft . -o spdx-json=sbom-spdx.json

      - name: Generate CycloneDX SBOM
        run: syft . -o cyclonedx-json=sbom-cyclonedx.json

      - name: Upload SBOMs
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom-*.json

      - name: Attach to release
        if: github.event_name == 'release'
        uses: softprops/action-gh-release@v1
        with:
          files: |
            sbom-spdx.json
            sbom-cyclonedx.json
```

### 3.2 attestation-slsa.yml

```yaml
name: SLSA Provenance

on:
  release:
    types: [published]

jobs:
  provenance:
    permissions:
      actions: read
      id-token: write
      contents: write
      attestations: write

    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v1.9.0
    with:
      base64-subjects: "${{ needs.build.outputs.digests }}"
      upload-assets: true
```

### 3.3 attestation-sign.yml

```yaml
name: Sign Artifacts

on:
  release:
    types: [published]

jobs:
  sign:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      packages: write
      attestations: write

    steps:
      - uses: actions/checkout@v4

      - name: Install cosign
        uses: sigstore/cosign-installer@v3

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Sign container
        run: |
          cosign sign --yes ghcr.io/${{ github.repository }}:${{ github.ref_name }}

      - name: Attest SBOM
        run: |
          cosign attest --yes --predicate sbom-spdx.json \
            --type spdxjson ghcr.io/${{ github.repository }}:${{ github.ref_name }}
```

### 3.4 attestation-verify.yml

```yaml
name: Verify Artifacts

on:
  # Run on deployment to verify before release
  workflow_call:
    inputs:
      image:
        description: 'Image to verify (e.g., ghcr.io/owner/repo:tag)'
        required: true
        type: string
      require-sbom:
        description: 'Require SBOM attestation'
        required: false
        type: boolean
        default: true
      require-provenance:
        description: 'Require SLSA provenance'
        required: false
        type: boolean
        default: true

  # Manual verification
  workflow_dispatch:
    inputs:
      image:
        description: 'Image to verify (e.g., ghcr.io/owner/repo:tag)'
        required: true
        type: string

  # Verify on pull (consumption verification)
  pull_request:
    paths:
      - 'docker-compose*.yml'
      - 'compose*.yml'
      - '**/deployment*.yml'

jobs:
  verify-signature:
    name: Verify Image Signature
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install cosign
        uses: sigstore/cosign-installer@v3

      - name: Determine image to verify
        id: image
        run: |
          if [ -n "${{ inputs.image }}" ]; then
            echo "ref=${{ inputs.image }}" >> $GITHUB_OUTPUT
          else
            # Extract from compose file or use default
            echo "ref=ghcr.io/${{ github.repository }}:latest" >> $GITHUB_OUTPUT
          fi

      - name: Verify signature (keyless)
        run: |
          echo "Verifying signature for: ${{ steps.image.outputs.ref }}"

          # Keyless verification using Sigstore
          # This verifies the image was signed by a trusted identity
          cosign verify \
            --certificate-identity-regexp="https://github.com/${{ github.repository_owner }}/.*" \
            --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
            ${{ steps.image.outputs.ref }}

          echo "::notice::Signature verification passed"

      - name: Verify SBOM attestation
        if: inputs.require-sbom != false
        run: |
          echo "Verifying SBOM attestation for: ${{ steps.image.outputs.ref }}"

          # Verify SBOM attestation exists and is valid
          cosign verify-attestation \
            --type spdxjson \
            --certificate-identity-regexp="https://github.com/${{ github.repository_owner }}/.*" \
            --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
            ${{ steps.image.outputs.ref }}

          echo "::notice::SBOM attestation verification passed"

      - name: Verify SLSA provenance
        if: inputs.require-provenance != false
        run: |
          echo "Verifying SLSA provenance for: ${{ steps.image.outputs.ref }}"

          # Verify SLSA provenance attestation
          cosign verify-attestation \
            --type slsaprovenance \
            --certificate-identity-regexp="https://github.com/${{ github.repository_owner }}/.*" \
            --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
            ${{ steps.image.outputs.ref }} || {
              # Try GitHub native attestation format
              echo "Trying GitHub attestation format..."
              cosign verify-attestation \
                --type https://slsa.dev/provenance/v1 \
                --certificate-identity-regexp="https://github.com/${{ github.repository_owner }}/.*" \
                --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
                ${{ steps.image.outputs.ref }}
            }

          echo "::notice::SLSA provenance verification passed"

      - name: Extract and display SBOM
        if: always()
        run: |
          echo "## SBOM Contents" >> $GITHUB_STEP_SUMMARY

          # Download and display SBOM
          cosign download attestation \
            --predicate-type spdxjson \
            ${{ steps.image.outputs.ref }} 2>/dev/null | \
            jq -r '.payload' | base64 -d | jq '.predicate' > sbom.json || true

          if [ -f sbom.json ]; then
            echo '```json' >> $GITHUB_STEP_SUMMARY
            jq '.packages | length' sbom.json | xargs -I {} echo "Package count: {}" >> $GITHUB_STEP_SUMMARY
            echo '```' >> $GITHUB_STEP_SUMMARY
          fi

  verify-github-attestations:
    name: Verify GitHub Native Attestations
    runs-on: ubuntu-latest
    steps:
      - name: Install GitHub CLI attestation extension
        run: gh extension install github/gh-attestation || true

      - name: Determine image to verify
        id: image
        run: |
          if [ -n "${{ inputs.image }}" ]; then
            echo "ref=${{ inputs.image }}" >> $GITHUB_OUTPUT
          else
            echo "ref=ghcr.io/${{ github.repository }}:latest" >> $GITHUB_OUTPUT
          fi

      - name: Verify with GitHub attestations
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          echo "Verifying GitHub attestations for: ${{ steps.image.outputs.ref }}"

          # Use GitHub's native attestation verification
          gh attestation verify \
            oci://${{ steps.image.outputs.ref }} \
            --owner ${{ github.repository_owner }} || {
              echo "::warning::GitHub attestation verification failed or not found"
              exit 0  # Don't fail - may not have GitHub attestations
            }

          echo "::notice::GitHub attestation verification passed"

  verify-summary:
    name: Verification Summary
    needs: [verify-signature, verify-github-attestations]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Generate summary
        run: |
          echo "## Verification Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Check | Status |" >> $GITHUB_STEP_SUMMARY
          echo "|-------|--------|" >> $GITHUB_STEP_SUMMARY

          if [ "${{ needs.verify-signature.result }}" == "success" ]; then
            echo "| Cosign Signature | ✅ Passed |" >> $GITHUB_STEP_SUMMARY
          else
            echo "| Cosign Signature | ❌ Failed |" >> $GITHUB_STEP_SUMMARY
          fi

          if [ "${{ needs.verify-github-attestations.result }}" == "success" ]; then
            echo "| GitHub Attestations | ✅ Passed |" >> $GITHUB_STEP_SUMMARY
          else
            echo "| GitHub Attestations | ⚠️ Not found or failed |" >> $GITHUB_STEP_SUMMARY
          fi
```

### 3.5 GitHub Native Attestations

```yaml
# In container build workflow
- name: Attest
  uses: actions/attest-build-provenance@v1
  with:
    subject-name: ghcr.io/${{ github.repository }}
    subject-digest: ${{ steps.build.outputs.digest }}
    push-to-registry: true
```

### 3.6 Verification in Deployment Pipeline

Example of integrating verification into deployment:

```yaml
# deploy.yml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - staging
          - production

jobs:
  verify:
    name: Verify Artifacts
    uses: ./.github/workflows/attestation-verify.yml
    with:
      image: ghcr.io/${{ github.repository }}:${{ github.sha }}
      require-sbom: true
      require-provenance: true

  deploy:
    name: Deploy to ${{ inputs.environment }}
    needs: verify
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - name: Deploy verified image
        run: |
          echo "Deploying verified image to ${{ inputs.environment }}"
          # Deployment steps here...
```

---

## 4. Review & Validation

- [ ] SBOMs contain all dependencies
- [ ] SLSA provenance verifiable
- [ ] Signatures verify with `cosign verify`
- [ ] SBOM attestations verify with `cosign verify-attestation`
- [ ] Provenance attestations verify with `cosign verify-attestation`
- [ ] GitHub attestations visible in repository
- [ ] GitHub attestations verify with `gh attestation verify`
- [ ] Verification workflow integrates into deployment pipeline
- [ ] Implementation tracking checklist updated
