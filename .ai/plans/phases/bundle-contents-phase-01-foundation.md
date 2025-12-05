---
id: 367b75a1-dd7d-4d34-9bf9-6aaab692c2ee
title: "Phase 01: Foundation"
status: pending
depends_on:
  - 6daf1a38-745e-41f8-abf4-90757b4b1a8a  # phase-00 (manual setup)
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
gate:
  required: true
  justfile_changes: major  # none | minor | major
  review_focus:
    - Initial justfile structure and core recipes
    - Configuration options (language, clone method, AI agent)
    - 1Password integration approach
    - Expected init workflow
---

# Phase 01: Foundation

> **⚠️ GATE REQUIRED**: Before starting this phase, complete the [Justfile Review Gate](../bundle-contents.md#phase-gate-justfile-review) conversation with user.

## 0. Phase Gate: Justfile Review

### Pre-Phase Checklist

- [ ] Reviewed current justfile state with user
- [ ] Compared expected vs current workflow
- [ ] Discussed Phase 01 justfile changes
- [ ] User approved planned changes
- [ ] Gate conversation documented

### Phase 01 Justfile Impact

This phase establishes the **foundational justfile structure**. Major changes:

| Recipe | Status | Purpose |
|--------|--------|---------|
| `init <target>` | **New** | Main entry point for project setup |
| `test-readiness <target>` | **New** | Verify setup is complete |
| `configure` | **New** | Interactive configuration wizard |
| `_preflight` | **New** | Validate prerequisites |
| `_setup-repos` | **New** | Fork and create from template |
| `_clone-repos` | **New** | Clone repositories locally |
| `_setup-1password` | **New** | Create vault and store credentials |
| `_create-issues` | **New** | Create setup milestone and issues |
| `_apply-bundle` | **New** | Copy bundle files to repo |
| `_apply-mcp-config` | **New** | Configure MCP client servers |
| `_finalize` | **New** | Install hooks, display summary |
| `show-config` | **New** | Display current configuration |
| `check` | **New** | Validate prerequisites |
| `list-templates` | **New** | Show available language templates |
| `list-agents` | **New** | Show supported AI agents |
| `help` | **New** | Display usage help |

### Questions for Gate Review

1. Is the `~/mcp-workspace/<repo>/` directory structure acceptable?
2. Should 1Password vault naming use a different convention?
3. Are the language template repos (`aRustyDev/tmpl-*`) correct?
4. Any additional AI agents to support?

---

## 1. Current State Assessment

- [ ] Review existing issue templates in bundle
- [ ] Check for existing labels.yml
- [ ] Verify PR template exists
- [ ] Check for AGENT.md
- [ ] Review dependabot.yml if present

### Existing Assets

- Rust transport templates (6 files) - completed
- MCP testing templates (4 files) - completed
- MCP implementation templates (3 files) - completed
- Container/library templates (2 files) - completed

### Gaps Identified

- [ ] General issue templates (bug, feature, security, docs, question)
- [ ] Issue template config.yml
- [ ] Extended labels.yml
- [ ] Comprehensive PR template
- [ ] AGENT.md with git workflow
- [ ] SECURITY.md

---

## 2. Contextual Goal

Establish the foundational templates and configurations that all other phases build upon. This includes standardized issue templates for bug reports, feature requests, security vulnerabilities, and documentation; a comprehensive PR template with testing checklists; extended label definitions covering all workflow categories; and AGENT.md providing AI agent instructions for consistent development practices.

### Success Criteria

- [ ] All 5 general issue templates created
- [ ] Issue template config.yml configured
- [ ] PR template with comprehensive sections
- [ ] labels.yml with 100+ labels across all categories
- [ ] AGENT.md with git workflow documentation
- [ ] dependabot.yml for multi-ecosystem support

### Out of Scope

- Workflow files (Phase 02+)
- Security scanning configurations (Phase 14+)
- Release configurations (Phase 24+)

---

## 3. Implementation

### 3.1 Issue Templates

Create `.github/ISSUE_TEMPLATE/` directory with:

| File | Purpose |
|------|---------|
| `bug-report.yml` | Standard bug reporting with severity, reproduction steps |
| `feature-request.yml` | Feature proposals with problem statement |
| `security-vulnerability.yml` | Private security reports with CVSS |
| `documentation.yml` | Docs improvements and corrections |
| `question.yml` | General usage questions |
| `config.yml` | Template chooser with contact links |

### 3.2 PR Template

Create `.github/pull_request_template.md` with sections:
- Summary
- Related Issues
- Changes
- Type of Change (checkboxes)
- Testing (checkboxes)
- Screenshots
- Checklist

### 3.3 Labels

Extend `.github/labels.yml` with categories:
- Type labels (bug, feature, docs, question, security)
- Priority labels (P0-P4)
- Status labels (triage, blocked, in-progress, review-needed)
- Size labels (XS, S, M, L, XL)
- Language labels (rust, python, javascript, typescript, go)
- Workflow labels (ci, cd, security, compliance)

### 3.4 AGENT.md

Create `AGENT.md` with:
- Git workflow (hierarchical branch strategy)
- Conventional commits specification
- Signed-off-by requirements
- Coding standards per language

#### Git Workflow - Branch Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BRANCH HIERARCHY                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  main ─────────────────────────────────────────────────────────────────────  │
│    │                                                                         │
│    ├── feature/<issue>-<description>    # Human-created feature branches    │
│    │                                                                         │
│    ├── fix/<issue>-<description>        # Human-created bug fix branches    │
│    │                                                                         │
│    ├── refactor/<issue>-<description>   # Human-created refactor branches   │
│    │                                                                         │
│    ├── docs/<issue>-<description>       # Human-created documentation       │
│    │                                                                         │
│    ├── pr/<pr-number>                   # CI-created PR validation branches │
│    │                                                                         │
│    └── deps/<dependency>/<version>      # CI-created dependency updates     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

Branch Prefix Legend:
  feature/* | fix/* | refactor/* | docs/*  →  Human-created (developer workflow)
  pr/*                                      →  CI-created (PR validation only)
  deps/*                                    →  CI-created (Dependabot/Renovate)
```

#### Branch Creation Rules

| Prefix | Creator | Purpose | Merge Target |
|--------|---------|---------|--------------|
| `feature/` | Human | New functionality | `main` |
| `fix/` | Human | Bug fixes | `main` |
| `refactor/` | Human | Code improvements | `main` |
| `docs/` | Human | Documentation | `main` |
| `pr/` | CI only | PR validation/testing | Never merged directly |
| `deps/` | CI only | Dependency updates | `main` (auto-merge eligible) |

#### deps/* Branch Specification

**Format**: `deps/<dependency-name>/<new-version>`

**Examples**:
- `deps/tokio/1.35.0`
- `deps/serde/1.0.195`
- `deps/actions-checkout/v4`

**Creation**: Only by authorized CI processes:
- Dependabot
- Renovate Bot
- Custom dependency update workflows

**Behavior**:
- Treated equivalently to `pr/*` for CI validation
- Eligible for auto-merge based on update type (see Phase 28)
- Protected from human direct push
- Auto-deleted after merge

**Branch Protection Rules**:
```yaml
# Example branch protection for deps/*
deps/**:
  required_status_checks:
    strict: true
    contexts:
      - "CI / build"
      - "CI / test"
      - "Security / audit"
  restrictions:
    apps:
      - dependabot
      - renovate
```

#### Commit Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           COMMIT STRATEGY                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHILOSOPHY: Atomic, Traceable, Reversible                                  │
│                                                                              │
│  Each commit should:                                                         │
│  • Represent ONE logical change (atomic)                                    │
│  • Be linked to an issue or PR (traceable)                                  │
│  • Be independently revertable (reversible)                                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Conventional Commits Format**:
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types** (in order of precedence for changelogs):
| Type | Description | Changelog Section |
|------|-------------|-------------------|
| `feat` | New feature | Features |
| `fix` | Bug fix | Bug Fixes |
| `perf` | Performance improvement | Performance |
| `refactor` | Code change that neither fixes nor adds | (hidden) |
| `docs` | Documentation only | Documentation |
| `style` | Formatting, whitespace | (hidden) |
| `test` | Adding/updating tests | (hidden) |
| `build` | Build system changes | (hidden) |
| `ci` | CI configuration | (hidden) |
| `chore` | Maintenance tasks | (hidden) |

**Scope Guidelines**:
- Use the affected module, component, or area
- Examples: `auth`, `api`, `cli`, `transport`, `mcp-protocol`
- For cross-cutting changes: `core`, `all`, or omit scope

**Breaking Changes**:
```
feat(api)!: change response format for tools endpoint

BREAKING CHANGE: The tools endpoint now returns an array instead of an object.
Migration: Update client code to iterate over array response.
```

**Issue Linking**:
```
fix(transport): handle connection timeout gracefully

Properly catch and retry on ETIMEDOUT errors during
WebSocket handshake. Adds exponential backoff with
configurable max retries.

Fixes #123
```

**When to Commit**:
| Scenario | Commit Strategy |
|----------|-----------------|
| TDD Red phase | Commit failing test: `test(scope): add failing test for X` |
| TDD Green phase | Commit with test: `feat/fix(scope): implement X` |
| TDD Refactor phase | Commit refactor: `refactor(scope): extract/simplify X` |
| Pre-commit hook fails | Fix issues, then commit (don't skip hooks) |
| Large feature | Break into multiple atomic commits |

**Commit Message Body**:
- **What**: What changed (the diff shows this, be concise)
- **Why**: Why this change was necessary (context)
- **Side effects**: Any behavioral changes to note

**Trailers**:
```
Signed-off-by: Name <email>           # Required (DCO)
Co-authored-by: Name <email>          # For pair programming
Reviewed-by: Name <email>             # Post-review attribution
Fixes: #123                           # Issue auto-close
Refs: #456, #789                      # Related issues (no auto-close)
```

#### PR Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PR LIFECYCLE                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  Draft   │ -> │  Ready   │ -> │  Review  │ -> │  Merge   │              │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘              │
│       │              │               │               │                      │
│       │              │               │               │                      │
│  Work in        Request         Address          Squash &                   │
│  progress       review          feedback         merge                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**PR States**:
| State | Label | Description |
|-------|-------|-------------|
| Draft | `status:draft` | Work in progress, CI runs but no review |
| Ready | `status:ready-for-review` | Complete, requesting review |
| Changes Requested | `status:changes-requested` | Reviewer requested changes |
| Approved | `status:approved` | Ready for merge |
| Blocked | `status:blocked` | Cannot proceed (dependency, discussion) |

**Merge Strategy**:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MERGE STRATEGY                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DEFAULT: Squash and Merge                                                  │
│  ────────────────────────────────────────────────────────────────────────── │
│  • Combines all PR commits into single commit on main                       │
│  • PR title becomes commit message                                          │
│  • Keeps main branch history clean                                          │
│  • Individual commits preserved in PR for archaeology                       │
│                                                                              │
│  EXCEPTION: Rebase and Merge                                                │
│  ────────────────────────────────────────────────────────────────────────── │
│  Use when each commit is meaningful and atomic:                             │
│  • Multi-part features with distinct commits                                │
│  • Commits from different authors (preserve attribution)                    │
│  • When explicitly requested in PR description                              │
│                                                                              │
│  NEVER: Merge Commit                                                        │
│  ────────────────────────────────────────────────────────────────────────── │
│  Creates noise in history. Disabled at repository level.                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Review Requirements**:
- Minimum 1 approving review for standard changes
- Minimum 2 approving reviews for:
  - Security-related changes
  - Breaking changes
  - Changes to CI/CD pipelines
  - Changes to authentication/authorization
- CODEOWNERS automatically requested based on paths

**CI Gates Before Merge**:
| Gate | Required | Description |
|------|----------|-------------|
| Build | Yes | Must compile/build successfully |
| Unit Tests | Yes | All tests must pass |
| Lint | Yes | No lint errors (warnings allowed) |
| Security Scan | Yes | No high/critical vulnerabilities |
| Coverage | No | Informational, not blocking |
| Integration Tests | Depends | Required for API changes |

#### Planning Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PLANNING METHODOLOGY                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  APPROACH: Iterative Decomposition                                          │
│                                                                              │
│  1. Understand → 2. Decompose → 3. Sequence → 4. Execute → 5. Validate     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Phase 1: Understand**
- Read the issue/requirement completely
- Identify acceptance criteria
- Ask clarifying questions BEFORE starting
- State your understanding back to confirm

**Phase 2: Decompose**
```
Feature Request
    │
    ├── What existing code is affected?
    │   └── Read and understand existing patterns
    │
    ├── What new code is needed?
    │   └── List new files/functions/modules
    │
    ├── What tests are needed?
    │   └── Unit, integration, edge cases
    │
    └── What documentation updates?
        └── README, API docs, comments
```

**Phase 3: Sequence**
Order tasks by:
1. **Dependencies**: What must exist first?
2. **Risk**: What has highest uncertainty? (do early)
3. **Value**: What delivers most value? (prioritize)

**Task Size Guidelines**:
| Size | Description | Commits |
|------|-------------|---------|
| XS | Single function change | 1 |
| S | Single file, multiple functions | 1-2 |
| M | Multiple files, one module | 2-5 |
| L | Multiple modules | 5-10 |
| XL | Should be broken down | Split into multiple PRs |

**Risk Identification**:
Before starting, identify:
- **Technical risks**: Unknown APIs, complex algorithms
- **Integration risks**: Breaking changes, dependencies
- **Security risks**: Auth, input validation, secrets
- **Performance risks**: Large data, N+1 queries

**When to Stop and Ask**:
- Ambiguous requirements
- Multiple valid approaches (need decision)
- Scope creep detected
- Blocked by external dependency
- Estimated effort exceeds original scope

#### Debugging Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEBUGGING METHODOLOGY                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  APPROACH: Scientific Method                                                │
│                                                                              │
│  1. Reproduce → 2. Isolate → 3. Hypothesize → 4. Test → 5. Fix → 6. Verify │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Phase 1: Reproduce**
- Get exact steps to reproduce
- Identify environment (OS, versions, config)
- Create minimal reproduction case
- Document reproduction steps in issue

**Phase 2: Isolate**
```
Is the bug in...?
    │
    ├── This repository's code?
    │   └── git bisect to find introducing commit
    │
    ├── A dependency?
    │   └── Check dependency changelogs, update/pin
    │
    ├── Configuration?
    │   └── Compare working vs broken configs
    │
    └── Environment?
        └── Test in clean environment
```

**Phase 3: Hypothesize**
Before changing code:
1. State your hypothesis: "I believe X causes Y because Z"
2. Predict what fixing X will change
3. Identify how to verify the fix

**Phase 4: Test Hypothesis**
```
# Good: Targeted test
Add a failing test that demonstrates the bug
Run test → Confirm it fails for the right reason

# Bad: Shotgun debugging
Change random things hoping it works
```

**Phase 5: Fix**
- Fix the root cause, not symptoms
- Keep the fix minimal and focused
- Don't refactor unrelated code in bug fix

**Phase 6: Verify**
- [ ] Failing test now passes
- [ ] All other tests still pass
- [ ] Manual verification in original context
- [ ] No regression in related functionality

**Git Bisect Workflow**:
```bash
# Start bisect
git bisect start

# Mark current (broken) as bad
git bisect bad

# Mark known good commit
git bisect good v1.2.0

# Git checks out middle commit - test it
# If broken:
git bisect bad
# If working:
git bisect good

# Repeat until found
# Git outputs: "<sha> is the first bad commit"

# Clean up
git bisect reset
```

**Log Analysis**:
| Log Level | When to Use |
|-----------|-------------|
| ERROR | Start here - what failed? |
| WARN | Look for preceding warnings |
| INFO | Trace the request flow |
| DEBUG | Enable for detailed state |
| TRACE | Last resort, very verbose |

**Common Debugging Patterns**:

| Pattern | Approach |
|---------|----------|
| Works locally, fails in CI | Environment diff, check secrets/config |
| Intermittent failure | Race condition, timing, resource exhaustion |
| Works in test, fails in prod | Config, scale, data differences |
| Regression after update | git bisect, check changelogs |
| Performance degradation | Profile, check N+1, memory leaks |

**Documentation Requirements for Bug Fixes**:
Every bug fix commit/PR should include:
- Root cause analysis
- How it was found
- Why the fix works
- How to prevent similar bugs

### 3.5 Core Configs

- Update `SECURITY.md` with vulnerability reporting process
- Create `dependabot.yml` for cargo, npm, pip, actions

### 3.6 justfile - Bundle Orchestration

The justfile is the primary entry point for the bundle. It orchestrates the complete setup workflow from initial fork through configured repository.

#### 3.6.1 Configuration Variables

```just
# justfile - MCP Bundle Orchestration
# ====================================

# Configuration (can be overridden via environment or .env file)
set dotenv-load := true

# ─────────────────────────────────────────────────────────────────
# REQUIRED CONFIGURATION
# ─────────────────────────────────────────────────────────────────

# Git username (auto-detected if not set)
git_username := `git config user.name 2>/dev/null || echo ""`

# GitHub username (auto-detected if not set)
github_username := `gh api user -q .login 2>/dev/null || echo ""`

# ─────────────────────────────────────────────────────────────────
# OPTIONAL CONFIGURATION (with defaults)
# ─────────────────────────────────────────────────────────────────

# Language preference: rust | golang | typescript | python
language := env_var_or_default("MCP_LANGUAGE", "rust")

# Clone method: ssh | https
clone_method := env_var_or_default("MCP_CLONE_METHOD", "https")

# AI Agent preference: zed | claude | copilot | codex | gemini | cursor | windsurf | vscode
ai_agent := env_var_or_default("MCP_AI_AGENT", "claude")

# 1Password vault name prefix
op_vault_prefix := env_var_or_default("MCP_OP_VAULT_PREFIX", "mcp")

# Template repositories by language
tmpl_rust := "aRustyDev/tmpl-rust"
tmpl_golang := "aRustyDev/tmpl-golang"
tmpl_typescript := "aRustyDev/tmpl-typescript"
tmpl_python := "aRustyDev/tmpl-python"

# ─────────────────────────────────────────────────────────────────
# DERIVED VALUES
# ─────────────────────────────────────────────────────────────────

# Select template based on language
template := if language == "rust" { tmpl_rust } else {
    if language == "golang" { tmpl_golang } else {
        if language == "typescript" { tmpl_typescript } else {
            if language == "python" { tmpl_python } else { tmpl_rust }
        }
    }
}
```

#### 3.6.2 Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BUNDLE INIT WORKFLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  User runs: just init <target-owner>/<target-repo>                          │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 1. PREFLIGHT CHECKS                                                  │   │
│  │    ├── Verify gh CLI authenticated                                   │   │
│  │    ├── Verify op CLI authenticated                                   │   │
│  │    ├── Check if fork already exists                                  │   │
│  │    ├── Check if repo already exists for language                     │   │
│  │    └── Validate configuration                                        │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 2. REPOSITORY SETUP                                                  │   │
│  │    ├── Fork target → <github_username>/fork-<target-repo>           │   │
│  │    ├── Create from template → <github_username>/<target-repo>       │   │
│  │    └── Configure repository settings                                 │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 3. LOCAL CLONE                                                       │   │
│  │    ├── Clone fork (ssh or https based on config)                    │   │
│  │    ├── Clone new repo (ssh or https based on config)                │   │
│  │    └── Set up remotes                                                │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 4. 1PASSWORD SETUP                                                   │   │
│  │    ├── Create vault: <op_vault_prefix>-<target-repo>                │   │
│  │    ├── Store GitHub token                                            │   │
│  │    ├── Store SSH keys (if applicable)                                │   │
│  │    └── Store any required API keys                                   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 5. ISSUE CREATION                                                    │   │
│  │    ├── Create setup milestone                                        │   │
│  │    ├── Create issues for each bundle phase                           │   │
│  │    └── Link issues to milestone                                      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 6. BUNDLE APPLICATION                                                │   │
│  │    ├── Copy bundle files to new repo                                 │   │
│  │    ├── Configure based on language/agent preferences                 │   │
│  │    ├── Create surgical commits per phase                             │   │
│  │    └── Update issues as progress occurs                              │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 7. FINALIZATION                                                      │   │
│  │    ├── Configure AI agent files (.cursor/, .zed/, etc.)             │   │
│  │    ├── Run pre-commit install                                        │   │
│  │    ├── Close setup issues/milestone                                  │   │
│  │    └── Display summary and next steps                                │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 3.6.3 Core Recipes

```just
# ─────────────────────────────────────────────────────────────────
# MAIN ENTRY POINT
# ─────────────────────────────────────────────────────────────────

# Initialize a new MCP server project
# Usage: just init <target-owner>/<target-repo>
init target:
    @echo "🚀 Initializing MCP project from {{target}}"
    @just _preflight "{{target}}"
    @just _setup-repos "{{target}}"
    @just _clone-repos "{{target}}"
    @just _setup-1password "{{target}}"
    @just _create-issues "{{target}}"
    @just _apply-bundle "{{target}}"
    @just _finalize "{{target}}"
    @echo "✅ Project initialized successfully!"
    @just _show-summary "{{target}}"

# Interactive configuration wizard
configure:
    @echo "🔧 MCP Bundle Configuration Wizard"
    @echo ""
    @echo "Current settings:"
    @echo "  Language:     {{language}}"
    @echo "  Clone method: {{clone_method}}"
    @echo "  AI Agent:     {{ai_agent}}"
    @echo ""
    @just _select-language
    @just _select-clone-method
    @just _select-ai-agent
    @echo ""
    @echo "Configuration saved to .env"

# ─────────────────────────────────────────────────────────────────
# CONFIGURATION SELECTION
# ─────────────────────────────────────────────────────────────────

# Select language preference
_select-language:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Select language:"
    echo "  1) rust (default)"
    echo "  2) golang"
    echo "  3) typescript"
    echo "  4) python"
    read -p "Choice [1-4]: " choice
    case "$choice" in
        1|"") lang="rust" ;;
        2) lang="golang" ;;
        3) lang="typescript" ;;
        4) lang="python" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
    echo "MCP_LANGUAGE=$lang" >> .env
    echo "Selected: $lang"

# Select clone method
_select-clone-method:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Select clone method:"
    echo "  1) https (default)"
    echo "  2) ssh"
    read -p "Choice [1-2]: " choice
    case "$choice" in
        1|"") method="https" ;;
        2) method="ssh" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
    echo "MCP_CLONE_METHOD=$method" >> .env
    echo "Selected: $method"

# Select AI agent preference
_select-ai-agent:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Select AI agent preference:"
    echo "  1) claude (default)"
    echo "  2) cursor"
    echo "  3) copilot"
    echo "  4) zed"
    echo "  5) windsurf"
    echo "  6) vscode"
    echo "  7) codex"
    echo "  8) gemini"
    read -p "Choice [1-8]: " choice
    case "$choice" in
        1|"") agent="claude" ;;
        2) agent="cursor" ;;
        3) agent="copilot" ;;
        4) agent="zed" ;;
        5) agent="windsurf" ;;
        6) agent="vscode" ;;
        7) agent="codex" ;;
        8) agent="gemini" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
    echo "MCP_AI_AGENT=$agent" >> .env
    echo "Selected: $agent"

# ─────────────────────────────────────────────────────────────────
# PREFLIGHT CHECKS
# ─────────────────────────────────────────────────────────────────

_preflight target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📋 Running preflight checks..."

    # Parse target
    target_owner=$(echo "{{target}}" | cut -d'/' -f1)
    target_repo=$(echo "{{target}}" | cut -d'/' -f2)

    # Check gh CLI
    if ! command -v gh &> /dev/null; then
        echo "❌ gh CLI not found. Install: https://cli.github.com/"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        echo "❌ gh CLI not authenticated. Run: gh auth login"
        exit 1
    fi
    echo "✓ gh CLI authenticated"

    # Check op CLI
    if ! command -v op &> /dev/null; then
        echo "❌ 1Password CLI not found. Install: https://1password.com/downloads/command-line/"
        exit 1
    fi

    if ! op account list &> /dev/null; then
        echo "❌ 1Password CLI not authenticated. Run: eval $(op signin)"
        exit 1
    fi
    echo "✓ 1Password CLI authenticated"

    # Check if fork already exists
    fork_name="fork-${target_repo}"
    if gh repo view "{{github_username}}/${fork_name}" &> /dev/null; then
        echo "⚠️  Fork already exists: {{github_username}}/${fork_name}"
        read -p "Continue anyway? [y/N]: " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    else
        echo "✓ Fork does not exist yet"
    fi

    # Check if repo already exists for this language
    if gh repo view "{{github_username}}/${target_repo}" &> /dev/null; then
        echo "⚠️  Repository already exists: {{github_username}}/${target_repo}"
        read -p "Continue anyway? [y/N]: " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    else
        echo "✓ Target repository does not exist yet"
    fi

    echo "✅ Preflight checks passed"

# ─────────────────────────────────────────────────────────────────
# REPOSITORY SETUP
# ─────────────────────────────────────────────────────────────────

_setup-repos target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔧 Setting up repositories..."

    target_owner=$(echo "{{target}}" | cut -d'/' -f1)
    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    fork_name="fork-${target_repo}"

    # Fork target repository
    echo "Forking {{target}} → {{github_username}}/${fork_name}..."
    gh repo fork "{{target}}" --clone=false --fork-name="${fork_name}" || {
        echo "Fork may already exist, continuing..."
    }

    # Create from template
    echo "Creating {{github_username}}/${target_repo} from {{template}}..."
    gh repo create "{{github_username}}/${target_repo}" \
        --template="{{template}}" \
        --private \
        --description="MCP Server: ${target_repo}" || {
        echo "Repository may already exist, continuing..."
    }

    # Configure repository settings
    echo "Configuring repository settings..."
    gh repo edit "{{github_username}}/${target_repo}" \
        --enable-issues \
        --enable-wiki \
        --enable-projects \
        --delete-branch-on-merge \
        --enable-auto-merge || true

    echo "✅ Repositories configured"

# ─────────────────────────────────────────────────────────────────
# LOCAL CLONE
# ─────────────────────────────────────────────────────────────────

_clone-repos target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📥 Cloning repositories locally..."

    target_owner=$(echo "{{target}}" | cut -d'/' -f1)
    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    fork_name="fork-${target_repo}"

    # Determine clone URL format
    if [[ "{{clone_method}}" == "ssh" ]]; then
        fork_url="git@github.com:{{github_username}}/${fork_name}.git"
        repo_url="git@github.com:{{github_username}}/${target_repo}.git"
        upstream_url="git@github.com:${target_owner}/${target_repo}.git"
    else
        fork_url="https://github.com/{{github_username}}/${fork_name}.git"
        repo_url="https://github.com/{{github_username}}/${target_repo}.git"
        upstream_url="https://github.com/${target_owner}/${target_repo}.git"
    fi

    # Create workspace directory
    workspace="${HOME}/mcp-workspace/${target_repo}"
    mkdir -p "${workspace}"
    cd "${workspace}"

    # Clone fork
    if [[ ! -d "${fork_name}" ]]; then
        echo "Cloning fork..."
        git clone "${fork_url}" "${fork_name}"
        cd "${fork_name}"
        git remote add upstream "${upstream_url}"
        cd ..
    else
        echo "Fork already cloned"
    fi

    # Clone new repo
    if [[ ! -d "${target_repo}" ]]; then
        echo "Cloning new repository..."
        git clone "${repo_url}" "${target_repo}"
    else
        echo "Repository already cloned"
    fi

    echo "✅ Repositories cloned to ${workspace}"

# ─────────────────────────────────────────────────────────────────
# 1PASSWORD SETUP
# ─────────────────────────────────────────────────────────────────

_setup-1password target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔐 Setting up 1Password vault..."

    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    vault_name="{{op_vault_prefix}}-${target_repo}"

    # Create vault if it doesn't exist
    if ! op vault get "${vault_name}" &> /dev/null; then
        echo "Creating vault: ${vault_name}"
        op vault create "${vault_name}" --description "MCP Server: ${target_repo}"
    else
        echo "Vault already exists: ${vault_name}"
    fi

    # Store GitHub token (if not already stored)
    if ! op item get "github-token" --vault="${vault_name}" &> /dev/null; then
        echo "Storing GitHub token..."
        gh_token=$(gh auth token)
        op item create \
            --category=api_credential \
            --title="github-token" \
            --vault="${vault_name}" \
            "credential=${gh_token}" \
            "hostname=github.com" \
            "type=pat"
    fi

    # Store repository URLs
    op item create \
        --category=secure_note \
        --title="repository-info" \
        --vault="${vault_name}" \
        "fork_repo={{github_username}}/fork-${target_repo}" \
        "main_repo={{github_username}}/${target_repo}" \
        "upstream={{target}}" \
        "language={{language}}" \
        "ai_agent={{ai_agent}}" 2>/dev/null || true

    echo "✅ 1Password vault configured: ${vault_name}"

# ─────────────────────────────────────────────────────────────────
# ISSUE CREATION
# ─────────────────────────────────────────────────────────────────

_create-issues target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📝 Creating setup issues..."

    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    repo="{{github_username}}/${target_repo}"

    # Create milestone
    milestone_url=$(gh api repos/${repo}/milestones \
        -f title="Initial Setup" \
        -f description="Bundle configuration and repository setup" \
        -f state="open" \
        --jq '.number' 2>/dev/null) || milestone_url=""

    # Create issues for each phase
    phases=(
        "Phase 00: Manual Setup|Complete manual configuration steps (wiki, secrets, branch protection)"
        "Phase 01: Foundation|Add issue templates, PR template, labels, AGENT.md"
        "Phase 02: Build Pipelines|Configure build workflows for {{language}}"
        "Phase 03: Code Quality|Set up linting and formatting"
        "Phase 14: Security - Dependencies|Configure dependency scanning"
        "Phase 24: Release - Versioning|Set up semantic release"
    )

    for phase in "${phases[@]}"; do
        title=$(echo "$phase" | cut -d'|' -f1)
        body=$(echo "$phase" | cut -d'|' -f2)

        gh issue create \
            --repo="${repo}" \
            --title="${title}" \
            --body="${body}

---
*Created by MCP Bundle init*" \
            --label="setup" \
            ${milestone_url:+--milestone="${milestone_url}"} || true
    done

    echo "✅ Setup issues created"

# ─────────────────────────────────────────────────────────────────
# BUNDLE APPLICATION
# ─────────────────────────────────────────────────────────────────

_apply-bundle target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Applying bundle to repository..."

    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    workspace="${HOME}/mcp-workspace/${target_repo}/${target_repo}"
    bundle_dir="$(pwd)"

    cd "${workspace}"

    # Copy and configure based on language
    echo "Copying bundle files..."

    # Phase 01: Foundation files
    mkdir -p .github/ISSUE_TEMPLATE
    cp -r "${bundle_dir}/.github/ISSUE_TEMPLATE/"* .github/ISSUE_TEMPLATE/ 2>/dev/null || true
    cp "${bundle_dir}/.github/pull_request_template.md" .github/ 2>/dev/null || true
    cp "${bundle_dir}/.github/labels.yml" .github/ 2>/dev/null || true
    cp "${bundle_dir}/AGENT.md" . 2>/dev/null || true

    git add .
    git commit -m "chore(setup): add Phase 01 foundation files

- Issue templates
- PR template
- Labels configuration
- AGENT.md

Part of: Phase 01: Foundation" || true

    # Language-specific configuration
    case "{{language}}" in
        rust)
            just _apply-rust-config
            ;;
        golang)
            just _apply-golang-config
            ;;
        typescript)
            just _apply-typescript-config
            ;;
        python)
            just _apply-python-config
            ;;
    esac

    # AI Agent configuration
    just _apply-agent-config

    # Push changes
    git push origin main

    echo "✅ Bundle applied"

# Language-specific configurations
_apply-rust-config:
    #!/usr/bin/env bash
    echo "Applying Rust-specific configuration..."
    # Copy Rust-specific workflows
    # cargo deny, cargo audit, etc.

_apply-golang-config:
    #!/usr/bin/env bash
    echo "Applying Go-specific configuration..."
    # Copy Go-specific workflows

_apply-typescript-config:
    #!/usr/bin/env bash
    echo "Applying TypeScript-specific configuration..."
    # Copy TypeScript/Node-specific workflows

_apply-python-config:
    #!/usr/bin/env bash
    echo "Applying Python-specific configuration..."
    # Copy Python-specific workflows

# ─────────────────────────────────────────────────────────────────
# AI AGENT CONFIGURATION
# ─────────────────────────────────────────────────────────────────

_apply-agent-config:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Configuring AI agent: {{ai_agent}}..."

    case "{{ai_agent}}" in
        claude)
            mkdir -p .claude
            # Copy Claude Code configuration
            ;;
        cursor)
            mkdir -p .cursor
            # Copy Cursor configuration
            ;;
        copilot)
            mkdir -p .github
            # Copy GitHub Copilot configuration
            ;;
        zed)
            mkdir -p .zed
            # Copy Zed configuration
            ;;
        windsurf)
            mkdir -p .windsurf
            # Copy Windsurf configuration
            ;;
        vscode)
            mkdir -p .vscode
            # Copy VS Code configuration
            ;;
        codex)
            # Copy Codex configuration
            ;;
        gemini)
            # Copy Gemini configuration
            ;;
    esac

    git add . 2>/dev/null || true
    git commit -m "chore(setup): configure {{ai_agent}} AI agent" 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────
# FINALIZATION
# ─────────────────────────────────────────────────────────────────

_finalize target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🏁 Finalizing setup..."

    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    workspace="${HOME}/mcp-workspace/${target_repo}/${target_repo}"

    cd "${workspace}"

    # Install pre-commit hooks
    if command -v pre-commit &> /dev/null; then
        pre-commit install
        pre-commit install --hook-type commit-msg
    fi

    # Install cocogitto (if Rust toolchain available)
    if command -v cargo &> /dev/null; then
        cargo install cocogitto 2>/dev/null || true
    fi

    echo "✅ Setup finalized"

_show-summary target:
    #!/usr/bin/env bash
    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    workspace="${HOME}/mcp-workspace/${target_repo}"

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    MCP PROJECT INITIALIZED"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "📁 Workspace:     ${workspace}"
    echo "🔀 Fork:          {{github_username}}/fork-${target_repo}"
    echo "📦 Repository:    {{github_username}}/${target_repo}"
    echo "🔐 1Password:     {{op_vault_prefix}}-${target_repo}"
    echo ""
    echo "Configuration:"
    echo "  Language:       {{language}}"
    echo "  Clone method:   {{clone_method}}"
    echo "  AI Agent:       {{ai_agent}}"
    echo ""
    echo "Next steps:"
    echo "  1. cd ${workspace}/${target_repo}"
    echo "  2. Review created issues: gh issue list"
    echo "  3. Complete Phase 00 manual steps"
    echo "  4. Start development!"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────────────
# VERIFICATION RECIPES
# ─────────────────────────────────────────────────────────────────

# Test repository readiness - verify setup is complete
# Usage: just test-readiness <owner>/<repo>
test-readiness target:
    #!/usr/bin/env bash
    set -euo pipefail

    target_owner=$(echo "{{target}}" | cut -d'/' -f1)
    target_repo=$(echo "{{target}}" | cut -d'/' -f2)
    fork_name="fork-${target_repo}"
    repo="{{github_username}}/${target_repo}"
    vault_name="{{op_vault_prefix}}-${target_repo}"
    workspace="${HOME}/mcp-workspace/${target_repo}/${target_repo}"

    echo "═══════════════════════════════════════════════════════════════"
    echo "            MCP PROJECT READINESS CHECK"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    passed=0
    failed=0
    warnings=0

    # Helper functions
    check_pass() { echo "  ✅ $1"; ((passed++)); }
    check_fail() { echo "  ❌ $1"; ((failed++)); }
    check_warn() { echo "  ⚠️  $1"; ((warnings++)); }
    section() { echo ""; echo "▶ $1"; echo "  ────────────────────────────────────────"; }

    # ─────────────────────────────────────────────────────────────
    section "Remote Repositories"
    # ─────────────────────────────────────────────────────────────

    # Check main repo exists
    if gh repo view "${repo}" &> /dev/null; then
        check_pass "Repository exists: ${repo}"
    else
        check_fail "Repository not found: ${repo}"
    fi

    # Check fork exists
    if gh repo view "{{github_username}}/${fork_name}" &> /dev/null; then
        check_pass "Fork exists: {{github_username}}/${fork_name}"
    else
        check_fail "Fork not found: {{github_username}}/${fork_name}"
    fi

    # Check upstream accessible
    if gh repo view "{{target}}" &> /dev/null; then
        check_pass "Upstream accessible: {{target}}"
    else
        check_warn "Upstream not accessible: {{target}}"
    fi

    # ─────────────────────────────────────────────────────────────
    section "Repository Settings"
    # ─────────────────────────────────────────────────────────────

    # Check wiki enabled
    wiki_enabled=$(gh repo view "${repo}" --json hasWikiEnabled -q '.hasWikiEnabled' 2>/dev/null || echo "false")
    if [[ "$wiki_enabled" == "true" ]]; then
        check_pass "Wiki enabled"
        # Check if wiki has content (Home page exists)
        if curl -sf "https://github.com/${repo}/wiki" | grep -q "Home" 2>/dev/null; then
            check_pass "Wiki initialized (Home page exists)"
        else
            check_warn "Wiki enabled but may not be initialized (Phase 00 manual step)"
        fi
    else
        check_fail "Wiki not enabled"
    fi

    # Check issues enabled
    issues_enabled=$(gh repo view "${repo}" --json hasIssuesEnabled -q '.hasIssuesEnabled' 2>/dev/null || echo "false")
    if [[ "$issues_enabled" == "true" ]]; then
        check_pass "Issues enabled"
    else
        check_fail "Issues not enabled"
    fi

    # Check branch protection (requires admin access)
    if gh api "repos/${repo}/branches/main/protection" &> /dev/null; then
        check_pass "Branch protection configured on main"
    else
        check_warn "Branch protection not configured (Phase 00 manual step)"
    fi

    # ─────────────────────────────────────────────────────────────
    section "Required Files (Remote)"
    # ─────────────────────────────────────────────────────────────

    # Check AGENT.md
    if gh api "repos/${repo}/contents/AGENT.md" &> /dev/null; then
        check_pass "AGENT.md present"
    else
        check_fail "AGENT.md missing"
    fi

    # Check PR template
    if gh api "repos/${repo}/contents/.github/pull_request_template.md" &> /dev/null; then
        check_pass "PR template present"
    else
        check_fail "PR template missing"
    fi

    # Check issue templates directory
    if gh api "repos/${repo}/contents/.github/ISSUE_TEMPLATE" &> /dev/null; then
        template_count=$(gh api "repos/${repo}/contents/.github/ISSUE_TEMPLATE" --jq 'length' 2>/dev/null || echo "0")
        if [[ "$template_count" -ge 5 ]]; then
            check_pass "Issue templates present (${template_count} files)"
        else
            check_warn "Issue templates incomplete (${template_count}/5+ expected)"
        fi
    else
        check_fail "Issue templates directory missing"
    fi

    # Check labels.yml
    if gh api "repos/${repo}/contents/.github/labels.yml" &> /dev/null; then
        check_pass "labels.yml present"
    else
        check_warn "labels.yml missing (labels may be applied directly)"
    fi

    # Check MCP configs
    if gh api "repos/${repo}/contents/.mcp/servers.json" &> /dev/null; then
        check_pass "MCP project config present (.mcp/servers.json)"
    else
        check_fail "MCP project config missing"
    fi

    # ─────────────────────────────────────────────────────────────
    section "Local Workspace"
    # ─────────────────────────────────────────────────────────────

    if [[ -d "${workspace}" ]]; then
        check_pass "Local workspace exists: ${workspace}"

        # Check git repo
        if [[ -d "${workspace}/.git" ]]; then
            check_pass "Git repository initialized"

            # Check remotes
            cd "${workspace}"
            if git remote get-url origin &> /dev/null; then
                check_pass "Git remote 'origin' configured"
            else
                check_fail "Git remote 'origin' not configured"
            fi

            # Check pre-commit hooks
            if [[ -f ".git/hooks/pre-commit" ]]; then
                check_pass "pre-commit hook installed"
            else
                check_warn "pre-commit hook not installed"
            fi

            if [[ -f ".git/hooks/commit-msg" ]]; then
                check_pass "commit-msg hook installed"
            else
                check_warn "commit-msg hook not installed"
            fi
        else
            check_fail "Not a git repository"
        fi

        # Check local files
        if [[ -f "${workspace}/AGENT.md" ]]; then
            check_pass "AGENT.md present locally"
        else
            check_fail "AGENT.md missing locally"
        fi

        if [[ -f "${workspace}/.mcp/servers.json" ]]; then
            check_pass "MCP config present locally"
        else
            check_fail "MCP config missing locally"
        fi

    else
        check_fail "Local workspace not found: ${workspace}"
    fi

    # ─────────────────────────────────────────────────────────────
    section "1Password Vault"
    # ─────────────────────────────────────────────────────────────

    if command -v op &> /dev/null; then
        if op vault get "${vault_name}" &> /dev/null; then
            check_pass "1Password vault exists: ${vault_name}"

            # Check for github token
            if op item get "github-token" --vault="${vault_name}" &> /dev/null; then
                check_pass "GitHub token stored in vault"
            else
                check_warn "GitHub token not found in vault"
            fi

            # Check for repo info
            if op item get "repository-info" --vault="${vault_name}" &> /dev/null; then
                check_pass "Repository info stored in vault"
            else
                check_warn "Repository info not found in vault"
            fi
        else
            check_fail "1Password vault not found: ${vault_name}"
        fi
    else
        check_warn "1Password CLI not installed - skipping vault checks"
    fi

    # ─────────────────────────────────────────────────────────────
    section "Local Development Tools"
    # ─────────────────────────────────────────────────────────────

    # Check pre-commit
    if command -v pre-commit &> /dev/null; then
        check_pass "pre-commit installed"
    else
        check_warn "pre-commit not installed"
    fi

    # Check cocogitto
    if command -v cog &> /dev/null; then
        check_pass "cocogitto (cog) installed"
    else
        check_warn "cocogitto not installed"
    fi

    # Check gh CLI
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            check_pass "gh CLI installed and authenticated"
        else
            check_warn "gh CLI installed but not authenticated"
        fi
    else
        check_fail "gh CLI not installed"
    fi

    # Check jq (for MCP config merging)
    if command -v jq &> /dev/null; then
        check_pass "jq installed"
    else
        check_warn "jq not installed (MCP config merging may be limited)"
    fi

    # ─────────────────────────────────────────────────────────────
    section "GitHub Labels"
    # ─────────────────────────────────────────────────────────────

    label_count=$(gh label list --repo "${repo}" --json name --jq 'length' 2>/dev/null || echo "0")
    if [[ "$label_count" -ge 50 ]]; then
        check_pass "Labels configured (${label_count} labels)"
    elif [[ "$label_count" -ge 10 ]]; then
        check_warn "Some labels configured (${label_count} labels, expected 50+)"
    else
        check_fail "Labels not configured (${label_count} labels)"
    fi

    # ─────────────────────────────────────────────────────────────
    section "Setup Issues"
    # ─────────────────────────────────────────────────────────────

    setup_issues=$(gh issue list --repo "${repo}" --label "setup" --json number --jq 'length' 2>/dev/null || echo "0")
    if [[ "$setup_issues" -gt 0 ]]; then
        check_pass "Setup issues created (${setup_issues} issues)"
    else
        check_warn "No setup issues found"
    fi

    # ─────────────────────────────────────────────────────────────
    # Summary
    # ─────────────────────────────────────────────────────────────
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                        SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  ✅ Passed:   ${passed}"
    echo "  ❌ Failed:   ${failed}"
    echo "  ⚠️  Warnings: ${warnings}"
    echo ""

    if [[ "$failed" -eq 0 ]]; then
        if [[ "$warnings" -eq 0 ]]; then
            echo "  🎉 Repository is FULLY READY for development!"
        else
            echo "  ✓ Repository is READY (review warnings for optional improvements)"
        fi
        exit 0
    else
        echo "  ⛔ Repository has FAILED checks - review above for details"
        echo ""
        echo "  Common fixes:"
        echo "    - Complete Phase 00 manual steps (wiki, branch protection, secrets)"
        echo "    - Re-run: just init {{target}}"
        echo "    - Check: just show-config"
        exit 1
    fi

# ─────────────────────────────────────────────────────────────────
# UTILITY RECIPES
# ─────────────────────────────────────────────────────────────────

# Show current configuration
show-config:
    @echo "Current MCP Bundle Configuration:"
    @echo "  Language:       {{language}}"
    @echo "  Clone method:   {{clone_method}}"
    @echo "  AI Agent:       {{ai_agent}}"
    @echo "  Template:       {{template}}"
    @echo "  GitHub user:    {{github_username}}"

# Validate prerequisites
check:
    @just _preflight "test/test"

# Clean up .env file
clean-config:
    @rm -f .env
    @echo "Configuration cleared"

# List available templates
list-templates:
    @echo "Available templates by language:"
    @echo "  rust:       {{tmpl_rust}}"
    @echo "  golang:     {{tmpl_golang}}"
    @echo "  typescript: {{tmpl_typescript}}"
    @echo "  python:     {{tmpl_python}}"

# List supported AI agents
list-agents:
    @echo "Supported AI agents:"
    @echo "  - claude    (Claude Code / Anthropic)"
    @echo "  - cursor    (Cursor IDE)"
    @echo "  - copilot   (GitHub Copilot)"
    @echo "  - zed       (Zed Editor)"
    @echo "  - windsurf  (Windsurf)"
    @echo "  - vscode    (VS Code)"
    @echo "  - codex     (OpenAI Codex)"
    @echo "  - gemini    (Google Gemini)"

# Help
help:
    @echo "MCP Bundle - Project Initialization Tool"
    @echo ""
    @echo "Usage:"
    @echo "  just init <owner>/<repo>          Initialize new MCP project"
    @echo "  just test-readiness <owner>/<repo> Verify setup is complete"
    @echo "  just configure                    Interactive configuration wizard"
    @echo "  just show-config                  Show current configuration"
    @echo "  just check                        Validate prerequisites"
    @echo ""
    @echo "Configuration:"
    @echo "  Set via environment variables or .env file:"
    @echo "    MCP_LANGUAGE=rust|golang|typescript|python"
    @echo "    MCP_CLONE_METHOD=https|ssh"
    @echo "    MCP_AI_AGENT=claude|cursor|copilot|zed|windsurf|vscode|codex|gemini"
    @echo ""
    @echo "Example:"
    @echo "  just configure"
    @echo "  just init modelcontextprotocol/servers"
    @echo "  just test-readiness modelcontextprotocol/servers"
```

#### 3.6.4 AI Agent Configuration Files

Each AI agent requires specific configuration files:

| Agent | Config Directory | Key Files |
|-------|-----------------|-----------|
| Claude | `.claude/` | `settings.json`, `CLAUDE.md` |
| Cursor | `.cursor/` | `settings.json`, `rules/` |
| Copilot | `.github/` | `copilot-instructions.md` |
| Zed | `.zed/` | `settings.json` |
| Windsurf | `.windsurf/` | `rules.md` |
| VS Code | `.vscode/` | `settings.json`, `extensions.json` |
| Codex | `.codex/` | `config.json` |
| Gemini | `.gemini/` | `context.md` |

#### 3.6.5 1Password Integration

The justfile leverages 1Password CLI for secure credential management:

```bash
# Vault structure
mcp-<repo-name>/
├── github-token          # GitHub PAT
├── repository-info       # Repo metadata (secure note)
├── npm-token             # If TypeScript (optional)
├── cargo-token           # If Rust (optional)
├── pypi-token            # If Python (optional)
└── secrets/              # Project-specific secrets
```

### 3.7 MCP Client Configurations

The bundle includes MCP client configurations (mcp.json) for AI-assisted MCP server development. Both **global** (system-wide) and **project-local** (repository-specific) configurations are provided.

#### 3.7.1 Configuration Strategy

| Type | Location | Enabled by Default | Purpose |
|------|----------|-------------------|---------|
| Project-local | `.mcp/servers.json` | **Yes** | Development servers for this repo |
| Global template | `configs/mcp/global/` | No | System-wide server configs (copy to system location) |

> **Default Behavior**: Only project-local configs are active after bundle application. Global configs are provided as templates that users can manually install to their system config location.

#### 3.7.2 Project-Local Configuration

**File**: `.mcp/servers.json`

```json
{
  "$schema": "https://modelcontextprotocol.io/schemas/mcp-servers.json",
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."],
      "description": "Read-only access to project files"
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "."],
      "description": "Git operations for development workflow"
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "description": "HTTP requests for API testing"
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "description": "Step-by-step reasoning for complex debugging"
    }
  }
}
```

#### 3.7.3 Global Configuration Templates

**Directory**: `configs/mcp/global/`

Provided as templates - users copy to their system config location:

| Platform | Config Location |
|----------|-----------------|
| macOS (Claude Desktop) | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Linux (Claude Desktop) | `~/.config/claude/claude_desktop_config.json` |
| Windows (Claude Desktop) | `%APPDATA%\Claude\claude_desktop_config.json` |

**File**: `configs/mcp/global/common-servers.json`

```json
{
  "$schema": "https://modelcontextprotocol.io/schemas/mcp-servers.json",
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "description": "Documentation lookup for libraries and frameworks",
      "disabled": false
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-token>"
      },
      "description": "GitHub API operations",
      "disabled": true
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "description": "Persistent memory across sessions",
      "disabled": true
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "<your-key>"
      },
      "description": "Web search via Brave",
      "disabled": true
    },
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-puppeteer"],
      "description": "Browser automation for testing",
      "disabled": true
    }
  }
}
```

#### 3.7.4 Language-Specific Development Servers

Additional servers based on language selection:

**Rust** (`.mcp/servers-rust.json`):
```json
{
  "mcpServers": {
    "rust-analyzer": {
      "command": "mcp-server-rust-analyzer",
      "description": "Rust language server integration",
      "disabled": true
    }
  }
}
```

**TypeScript** (`.mcp/servers-typescript.json`):
```json
{
  "mcpServers": {
    "typescript": {
      "command": "npx",
      "args": ["-y", "mcp-server-typescript"],
      "description": "TypeScript language features",
      "disabled": true
    }
  }
}
```

**Python** (`.mcp/servers-python.json`):
```json
{
  "mcpServers": {
    "python": {
      "command": "uvx",
      "args": ["mcp-server-python"],
      "description": "Python language features",
      "disabled": true
    }
  }
}
```

#### 3.7.5 Integration with justfile

The `_apply-agent-config` recipe merges MCP configs based on language and agent:

```just
# Apply MCP client configurations
_apply-mcp-config:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Configuring MCP client servers..."

    # Copy project-local config (always enabled)
    mkdir -p .mcp
    cp "${bundle_dir}/configs/mcp/project/servers.json" .mcp/

    # Merge language-specific servers if available
    lang_config="${bundle_dir}/configs/mcp/project/servers-{{language}}.json"
    if [[ -f "$lang_config" ]]; then
        # Merge using jq (if available) or simple concatenation
        if command -v jq &> /dev/null; then
            jq -s '.[0] * .[1]' .mcp/servers.json "$lang_config" > .mcp/servers.tmp
            mv .mcp/servers.tmp .mcp/servers.json
        fi
    fi

    # Inform user about global configs
    echo ""
    echo "📋 Global MCP server templates available in: configs/mcp/global/"
    echo "   Copy to your system config location to enable globally."
```

#### 3.7.6 Bundle Structure (MCP Configs)

```
configs/
└── mcp/
    ├── project/                    # Project-local configs (enabled by default)
    │   ├── servers.json            # Common development servers
    │   ├── servers-rust.json       # Rust-specific servers
    │   ├── servers-typescript.json # TypeScript-specific servers
    │   ├── servers-python.json     # Python-specific servers
    │   └── servers-golang.json     # Go-specific servers
    └── global/                     # Global config templates (manual install)
        ├── common-servers.json     # Commonly useful servers
        ├── README.md               # Installation instructions
        └── install.sh              # Optional install helper script
```

---

## 4. Review & Validation

- [ ] All templates pass YAML validation
- [ ] Labels are unique (no duplicates)
- [ ] PR template renders correctly on GitHub
- [ ] AGENT.md is comprehensive and clear
- [ ] justfile recipes work end-to-end
- [ ] justfile supports all language options
- [ ] justfile supports all AI agent options
- [ ] 1Password vault creation works
- [ ] Issue creation works correctly
- [ ] MCP project-local configs valid JSON
- [ ] MCP global config templates valid JSON
- [ ] MCP config merge works with jq
- [ ] Language-specific MCP servers disabled by default
- [ ] test-readiness recipe runs without errors
- [ ] test-readiness detects missing Phase 00 items as warnings
- [ ] test-readiness exits non-zero on critical failures
- [ ] No scope creep into workflow files
- [ ] Implementation tracking checklist updated
