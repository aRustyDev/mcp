---
id: 6daf1a38-745e-41f8-abf4-90757b4b1a8a
title: "Phase 00: Manual Setup"
status: pending
depends_on: []  # First phase - no dependencies
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - wiki-documentation-strategy-adr  # ADR in ../docs/adr/
issues: []
gate:
  required: true
  justfile_changes: none  # This phase is manual, no justfile changes
  review_focus:
    - Confirm bundle download location
    - Verify justfile prerequisites (gh, op CLIs)
    - Discuss workspace directory preferences
---

# Phase 00: Manual Setup

> **⚠️ GATE REQUIRED**: Before starting this phase, complete the [Justfile Review Gate](../bundle-contents.md#phase-gate-justfile-review) conversation with user.

## 0. Phase Gate: Justfile Review

### Pre-Phase Checklist

- [ ] Confirmed Phase 00 has no justfile changes (manual-only phase)
- [ ] Verified user understands prerequisite tools (gh CLI, op CLI)
- [ ] Discussed workspace directory preferences
- [ ] User approved proceeding with manual setup

### Phase 00 Justfile Impact

**No justfile changes in this phase.** Phase 00 captures manual actions that must be performed before the bundle's justfile can be used effectively.

However, this phase establishes the **prerequisites** for justfile execution:

| Prerequisite | Purpose | Validation |
|--------------|---------|------------|
| `gh` CLI | GitHub API operations | `gh auth status` |
| `op` CLI | 1Password credential storage | `op account list` |
| Wiki initialized | Documentation storage | Manual via GitHub UI |
| Secrets configured | Workflow authentication | Manual via GitHub UI |

---

## 1. Purpose

This phase captures **manual actions** that must be performed by the user after downloading/applying the bundle. These steps cannot be automated due to GitHub limitations, security requirements, or one-time setup needs.

**This phase should be completed BEFORE proceeding with Phase 01.**

---

## 2. Manual Actions Checklist

### 2.1 Repository Wiki Setup

**Why Manual**: GitHub wikis cannot be programmatically initialized - the first page must be created via the web UI.

- [ ] Navigate to repository → Wiki tab
- [ ] Click "Create the first page"
- [ ] Create `Home.md` with initial content (template below)
- [ ] Verify wiki is accessible at `https://github.com/<owner>/<repo>/wiki`

#### Home.md Template

```markdown
# Project Wiki

Welcome to the project wiki. This wiki serves as the central documentation hub for:

- **AI Agents**: LLMs.txt and context for AI-assisted development
- **ADRs**: Architecture Decision Records
- **Guides**: Tool guides, setup instructions, workflows
- **References**: API docs, protocol specs, configuration references

## Quick Links

- [LLMs.txt](LLMs.txt) - AI agent context file
- [ADRs](ADRs) - Architecture decisions
- [Setup Guide](Setup-Guide) - Getting started

## For AI Agents

This wiki is accessible via:
- **Context7**: Point to `https://github.com/<owner>/<repo>/wiki`
- **GitMCP**: Use `https://gitmcp.io/<owner>/<repo>.wiki`
- **Raw Access**: `https://raw.githubusercontent.com/wiki/<owner>/<repo>/<page>.md`

---

*This wiki is automatically synced from the repository. See [Wiki Sync Workflow](../.github/workflows/wiki-sync.yml).*
```

### 2.2 GitHub Repository Settings

**Why Manual**: Repository settings require admin access and cannot be configured via workflow files.

- [ ] **Enable Wiki**: Settings → Features → Wikis (check)
- [ ] **Branch Protection**: Settings → Branches → Add rule for `main`
  - [ ] Require pull request reviews
  - [ ] Require status checks to pass
  - [ ] Require signed commits (optional)
- [ ] **Actions Permissions**: Settings → Actions → General
  - [ ] Allow GitHub Actions to create and approve pull requests
  - [ ] Set workflow permissions to "Read and write permissions"
- [ ] **Merge Queue** (optional, for high PR volume): Settings → General → Pull Requests
  - [ ] Enable "Require branches to be up to date before merging"
  - [ ] Enable "Require merge queue"
  - Benefits: Automatic rebasing, batched CI runs, guaranteed main stability

### 2.3 Secrets Configuration

**Why Manual**: Secrets must be added via GitHub UI for security.

| Secret | Required For | How to Obtain |
|--------|--------------|---------------|
| `CARGO_REGISTRY_TOKEN` | crates.io publishing | [crates.io/settings/tokens](https://crates.io/settings/tokens) |
| `NPM_TOKEN` | npm publishing | [npmjs.com/settings/tokens](https://www.npmjs.com/settings/tokens) |
| `PYPI_API_TOKEN` | PyPI publishing | [pypi.org/manage/account](https://pypi.org/manage/account/) |
| `SLACK_BOT_TOKEN` | Slack notifications | Slack App settings |
| `DISCORD_WEBHOOK` | Discord notifications | Discord server settings |
| `CODECOV_TOKEN` | Coverage reports | [codecov.io](https://codecov.io) |

- [ ] Add required secrets: Settings → Secrets and variables → Actions

### 2.4 GitHub App Installations

**Why Manual**: App installations require OAuth authorization.

- [ ] **pre-commit.ci**: Install from [pre-commit.ci](https://pre-commit.ci)
- [ ] **Codecov**: Install from [GitHub Marketplace](https://github.com/marketplace/codecov)
- [ ] **Dependabot**: Enable via Settings → Code security and analysis

### 2.5 Local Development Setup

**Why Manual**: Local environment varies per developer.

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Install Cocogitto (commit linting)
cargo install cocogitto

# Install commitlint (optional, for detailed validation)
npm install -g @commitlint/cli @commitlint/config-conventional

# Verify setup
pre-commit run --all-files
cog check
```

- [ ] Document local setup in CONTRIBUTING.md

### 2.6 Wiki Initial Pages

After wiki is initialized, create these pages:

| Page | Purpose |
|------|---------|
| `Home.md` | Landing page (created in 2.1) |
| `LLMs.txt` | AI agent context - brief version |
| `LLMs-Full.txt` | AI agent context - comprehensive |
| `ADRs.md` | Index of architecture decisions |
| `Setup-Guide.md` | Getting started guide |
| `_Sidebar.md` | Custom navigation sidebar |

- [ ] Create initial wiki pages using template below

#### _Sidebar.md Template

```markdown
**Navigation**

- [[Home]]
- [[Setup Guide]]
- [[Contributing]]

**For AI Agents**

- [[LLMs.txt]]
- [[LLMs Full]]

**Architecture**

- [[ADRs]]

**References**

- [[Tool Guides]]
- [[API Reference]]
```

---

## 3. Post-Setup Verification

After completing manual setup:

- [ ] Wiki accessible and has Home page
- [ ] Branch protection rules active
- [ ] Required secrets configured
- [ ] pre-commit.ci app installed
- [ ] Local pre-commit hooks working
- [ ] `cog check` passes locally

---

## 4. Automation for Wiki Sync

Once wiki is initialized, this workflow can sync docs automatically:

```yaml
# .github/workflows/wiki-sync.yml
name: Sync Docs to Wiki

on:
  push:
    branches: [main]
    paths:
      - 'docs/**'
      - '.ai/docs/**'
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4
        with:
          path: repo

      - name: Checkout wiki
        uses: actions/checkout@v4
        with:
          repository: ${{ github.repository }}.wiki
          path: wiki

      - name: Sync documentation
        run: |
          # Sync ADRs
          mkdir -p wiki/ADRs
          cp -r repo/.ai/docs/adr/*.md wiki/ADRs/

          # Sync other docs
          cp -r repo/docs/*.md wiki/ 2>/dev/null || true

          # Generate ADR index
          echo "# Architecture Decision Records" > wiki/ADRs.md
          echo "" >> wiki/ADRs.md
          for f in wiki/ADRs/*.md; do
            name=$(basename "$f" .md)
            title=$(grep -m1 "^title:" "$f" | cut -d: -f2- | xargs)
            echo "- [[$name|$title]]" >> wiki/ADRs.md
          done

      - name: Commit and push
        run: |
          cd wiki
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          git diff --quiet && git diff --staged --quiet || git commit -m "docs: sync from main repo"
          git push
```

---

## 5. Review & Validation

- [ ] All manual actions completed
- [ ] Wiki sync workflow added to bundle
- [ ] Documentation updated with manual steps
- [ ] Implementation tracking checklist updated
