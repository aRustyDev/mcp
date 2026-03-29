---
id: 0093b808-3915-460a-aed9-e60ea13f32e7
title: "Quick Start Guide"
type: reference
---

# Bundle Expansion Quick Start Guide

## Getting Started

### Prerequisites

1. Clone the repository:
   ```bash
   git clone https://github.com/aRustyDev/mcp.git
   cd mcp
   ```

2. Install tools:
   ```bash
   # Just (task runner)
   brew install just  # or cargo install just

   # Validation tools
   brew install actionlint yamllint
   ```

### Directory Structure

```
bundles/
├── .github/
│   ├── ISSUE_TEMPLATE/     # Issue templates
│   ├── workflows/          # GitHub Actions workflows
│   ├── labels.yml          # Label definitions
│   ├── labeler.yml         # Path-based labeler config
│   └── dependabot.yml      # Dependency updates
├── configs/
│   ├── .releaserc.json      # Semantic release config
│   ├── codecov.yml         # Coverage config
│   └── .gitleaks.toml      # Secret scanning config
├── docs/
│   └── ...                 # Documentation
├── justfile                # Setup automation
└── MANIFEST.md             # Bundle contents
```

---

## Development Workflow

### 1. Create Placeholder Workflow

```bash
# Create new workflow file
touch bundles/.github/workflows/my-workflow.yml
```

```yaml
# bundles/.github/workflows/my-workflow.yml
name: My Workflow

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

jobs:
  placeholder:
    runs-on: ubuntu-latest
    steps:
      - name: Placeholder
        run: echo "TODO: Implement"
```

### 2. Validate Workflow

```bash
# Check syntax
actionlint bundles/.github/workflows/my-workflow.yml

# Check YAML
yamllint bundles/.github/workflows/my-workflow.yml
```

### 3. Implement Workflow

Use the phase guides for reference:
- Phase 01: Foundation - Templates, labels
- Phases 02-03: Build, lint
- Phases 04-13: Testing
- Phases 14-23: Security
- Phases 24-27: Release
- Phases 28-30: Automation

### 4. Test Locally (optional)

```bash
# Use act to test workflows locally
brew install act
act -j my-job-name
```

### 5. Update Tracking

Update `checklists/implementation-tracking.md`:
```markdown
- [x] `my-workflow.yml` - Description
```

---

## Common Patterns

### Path-Filtered Workflow

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'Cargo.toml'
  pull_request:
    paths:
      - 'src/**'
```

### Matrix Build

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        version: ['3.10', '3.11', '3.12']
    runs-on: ${{ matrix.os }}
```

### Reusable Workflow

```yaml
# In the bundle
on:
  workflow_call:
    inputs:
      version:
        type: string
        default: 'latest'

# In consuming repo
jobs:
  call:
    uses: aRustyDev/mcp/.github/workflows/reusable.yml@main
    with:
      version: '1.0.0'
```

### SARIF Upload (Security)

```yaml
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: results.sarif
```

### Caching

```yaml
# Rust
- uses: Swatinem/rust-cache@v2

# Python
- uses: actions/setup-python@v5
  with:
    cache: 'pip'

# Node
- uses: actions/setup-node@v4
  with:
    cache: 'npm'
```

---

## Workflow Categories

### By Trigger

| Trigger | Use Case | Example |
|---------|----------|---------|
| `push` | Main branch changes | Build, test |
| `pull_request` | PR validation | Lint, test |
| `schedule` | Periodic tasks | Security scan |
| `release` | Publishing | Deploy |
| `workflow_dispatch` | Manual runs | Debug |

### By Purpose

| Category | Workflows |
|----------|-----------|
| Build | build-*.yml |
| Lint | lint-*.yml |
| Test | test-*.yml |
| Security | security-*.yml, secret-scan.yml |
| Publish | publish-*.yml |
| Automation | stale-*.yml, triage.yml, welcome.yml |

---

## Secrets Required

| Secret | Workflows | Required For |
|--------|-----------|--------------|
| `GITHUB_TOKEN` | All | Built-in |
| `DOCKERHUB_USERNAME` | publish-container | Docker Hub |
| `DOCKERHUB_TOKEN` | publish-container | Docker Hub |
| `CARGO_REGISTRY_TOKEN` | publish-rust | crates.io |
| `NPM_TOKEN` | publish-node | npm |
| `SLACK_BOT_TOKEN` | notify-slack | Slack |
| `DISCORD_WEBHOOK` | notify-discord | Discord |
| `SNYK_TOKEN` | security-* | Snyk (optional) |
| `CLOUDFLARE_API_TOKEN` | publish-mdbook | Cloudflare |
| `OP_SVC_TOKEN` | Any | 1Password |

---

## Validation Checklist

Before committing:

- [ ] `actionlint` passes
- [ ] `yamllint` passes
- [ ] File is in correct directory
- [ ] Permissions are correct
- [ ] Secrets are documented
- [ ] Tracking doc updated

---

## Commands

```bash
# Validate all workflows
just validate-workflows

# Build bundle locally
just build-bundle

# Test bundle installation
just test-bundle /tmp/test-repo

# Update tracking
just update-tracking
```

---

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Awesome Actions](https://github.com/sdras/awesome-actions)
- [actionlint](https://github.com/rhysd/actionlint)
- [act - Local Testing](https://github.com/nektos/act)
