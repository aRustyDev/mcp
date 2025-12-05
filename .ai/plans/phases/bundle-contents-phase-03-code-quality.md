---
id: e813a7bc-3a3e-4171-94c8-6bf0b363eb62
title: "Phase 03: Code Quality"
status: pending
depends_on:
  - 173e85b4-ff31-4f5f-bc87-f09a8067a75b  # phase-02
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
references:
  - linting-strategy-adr  # ADR in ../docs/adr/
issues: []
---

# Phase 03: Code Quality

## 1. Current State Assessment

- [ ] Check for existing lint workflows
- [ ] Review language-specific linting tools used
- [ ] Identify SARIF upload capability
- [ ] Check for config files (clippy.toml, ruff.toml, etc.)

### Existing Assets

None - lint workflows not yet created.

### Gaps Identified

#### Language-Specific Linting
- [ ] Container lint (hadolint, dockle)
- [ ] Rust lint (clippy, rustfmt)
- [ ] Python lint (ruff, black, mypy)
- [ ] JavaScript lint (eslint, prettier)
- [ ] TypeScript lint (eslint, prettier, tsc)
- [ ] Go lint (golangci-lint)

#### Configuration/Data File Linting
- [ ] Markdown lint (markdownlint)
- [ ] YAML lint (yamllint)
- [ ] Shell lint (shellcheck, shfmt)
- [ ] TOML lint (taplo)
- [ ] JSON lint (check-json, prettier)
- [ ] EditorConfig check (editorconfig-checker)

#### Quality Assurance
- [ ] Spellcheck (typos-cli or cspell)
- [ ] Actions lint (actionlint)

#### Commit Linting (Hybrid Approach)
- [ ] Cocogitto (cog.toml) - custom types, changelog, versioning
- [ ] commitlint (.commitlintrc.js) - header/body/footer validation
- [ ] lint-commits.yml workflow

#### Pre-commit Integration
- [ ] .pre-commit-config.yaml
- [ ] pre-commit.ci configuration

---

## 2. Contextual Goal

Establish comprehensive code quality checks using a hybrid approach: pre-commit hooks for fast local feedback, pre-commit.ci for PR enforcement with auto-fixes, and individual GitHub workflows for SARIF output and extended analysis. Cover all file types including source code, configuration files, and documentation. Enforce conventional commits and spelling consistency.

### Success Criteria

- [ ] All language-specific lint workflows created (6 languages)
- [ ] All config file lint workflows created (TOML, JSON, YAML, Markdown)
- [ ] Pre-commit.yaml with unified local hooks
- [ ] pre-commit.ci integrated for auto-fixes
- [ ] SARIF output where supported
- [ ] Spellcheck catches typos in docs/comments
- [ ] Commit linting with hybrid Cocogitto + commitlint
- [ ] Custom commit types/scopes configurable
- [ ] Header/body/footer validation rules enforced
- [ ] Actions validated with actionlint

### Out of Scope

- Security-specific analysis (Phase 16 SAST)
- Test execution (Phase 04+)
- Helm chart linting (Phase 27)

---

## 3. Implementation

### 3.0 Linting Strategy (Hybrid Approach)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         LINTING STRATEGY                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 1: LOCAL PRE-COMMIT (Fast Feedback)                              │
│  • Format checks, fast lints, spelling, commit messages                 │
│  • Runs: Every commit locally                                           │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 2: PRE-COMMIT.CI (PR Enforcement)                                │
│  • Same hooks as local, auto-fixes via commit                           │
│  • Runs: Every PR                                                       │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 3: INDIVIDUAL WORKFLOWS (SARIF + Extended Analysis)              │
│  • SARIF → Security tab, type checking, slow/comprehensive checks       │
│  • Runs: Push to main, PR, scheduled                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Pre-commit Configuration

```yaml
# .pre-commit-config.yaml
ci:
  autofix_prs: true
  autofix_commit_msg: 'style: auto-fix by pre-commit.ci'
  autoupdate_schedule: weekly
  skip: [cargo-clippy]  # Too slow for CI, run in workflow

repos:
  # General hooks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-toml
      - id: check-json
      - id: check-yaml
        args: [--unsafe]  # Allow custom tags
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: mixed-line-ending
      - id: check-merge-conflict

  # Spelling
  - repo: https://github.com/crate-ci/typos
    rev: v1.16.0
    hooks:
      - id: typos

  # Commit messages - Hybrid: Cocogitto (types/scopes) + commitlint (validation)
  - repo: local
    hooks:
      - id: cocogitto
        name: cocogitto (conventional commits check)
        entry: cog check --from-latest-tag
        language: system
        stages: [commit-msg]
        pass_filenames: false

      - id: commitlint
        name: commitlint (header/body/footer validation)
        entry: npx --no -- commitlint --edit
        language: system
        stages: [commit-msg]
        pass_filenames: false

  # GitHub Actions
  - repo: https://github.com/rhysd/actionlint
    rev: v1.6.26
    hooks:
      - id: actionlint

  # TOML
  - repo: https://github.com/tamasfe/taplo
    rev: 0.8.1
    hooks:
      - id: taplo

  # Markdown
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.37.0
    hooks:
      - id: markdownlint-fix

  # Shell
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck

  - repo: https://github.com/scop/pre-commit-shfmt
    rev: v3.7.0-4
    hooks:
      - id: shfmt

  # Rust
  - repo: local
    hooks:
      - id: cargo-fmt
        name: cargo fmt
        entry: cargo fmt --all --
        language: system
        types: [rust]
        pass_filenames: false

  # Python
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  # JavaScript/TypeScript
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.54.0
    hooks:
      - id: eslint
        types: [javascript, typescript]
        additional_dependencies:
          - eslint-config-prettier

  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types_or: [javascript, typescript, json, yaml, markdown]

  # EditorConfig
  - repo: https://github.com/editorconfig-checker/editorconfig-checker.python
    rev: 2.7.3
    hooks:
      - id: editorconfig-checker
```

### 3.2 lint-container.yml

Tools:
- **hadolint**: Dockerfile best practices (SARIF output)
- **dockle**: CIS benchmarks for images

### 3.3 lint-rust.yml

Jobs:
- **clippy**: Linting with `-D warnings` (SARIF via clippy-sarif)
- **rustfmt**: Format checking

### 3.4 lint-python.yml

Tools:
- **ruff**: Fast linting + formatting (SARIF output)
- **mypy**: Type checking

### 3.5 lint-javascript.yml

Tools:
- **eslint**: JS linting with security plugins (SARIF output)
- **prettier**: Format checking

### 3.6 lint-typescript.yml

Tools:
- **eslint**: TS linting (SARIF output)
- **prettier**: Format checking
- **tsc**: Type checking (--noEmit)

### 3.7 lint-go.yml

Tools:
- **golangci-lint**: Comprehensive Go linting (SARIF output)
- **gofmt**: Format checking

### 3.8 lint-config.yml (Unified Config Linting)

```yaml
name: Lint Config Files

on:
  push:
    paths:
      - '**/*.toml'
      - '**/*.json'
      - '**/*.yaml'
      - '**/*.yml'
      - '**/*.md'
      - '.github/workflows/**'
  pull_request:
    paths:
      - '**/*.toml'
      - '**/*.json'
      - '**/*.yaml'
      - '**/*.yml'
      - '**/*.md'
      - '.github/workflows/**'

jobs:
  toml:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: tamasfe/taplo-action@v0.3.1
        with:
          arguments: check

  yaml:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: yamllint
        uses: ibiqlik/action-yamllint@v3

  markdown:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DavidAnson/markdownlint-cli2-action@v14

  actionlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: reviewdog/action-actionlint@v1
```

### 3.9 lint-shell.yml

Tools:
- **shellcheck**: Shell script linting (SARIF output)
- **shfmt**: Shell script formatting

### 3.10 lint-spelling.yml

```yaml
name: Spellcheck

on:
  push:
    paths:
      - '**/*.md'
      - '**/*.rs'
      - '**/*.py'
      - '**/*.ts'
      - '**/*.js'
  pull_request:

jobs:
  typos:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: crate-ci/typos@master
        with:
          config: .typos.toml
```

### 3.11 Commit Linting (Hybrid Strategy)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    COMMIT LINTING STRATEGY                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  COCOGITTO (Rust)                                                │    │
│  │  Purpose: Custom types, scopes, changelog, versioning            │    │
│  │  Config: cog.toml                                                │    │
│  │  Commands: cog commit, cog check, cog bump, cog changelog        │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              +                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  COMMITLINT (JavaScript)                                         │    │
│  │  Purpose: Header/body/footer validation, length limits           │    │
│  │  Config: .commitlintrc.js                                        │    │
│  │  Hooks: commit-msg via pre-commit                                │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Why both?                                                               │
│  • Cocogitto: Best for custom types + automatic changelog/versioning   │
│  • commitlint: Best for detailed message validation rules               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 3.11.1 cog.toml (Cocogitto Configuration)

```toml
# cog.toml - Cocogitto configuration for conventional commits

# ─────────────────────────────────────────────────────────────────────────────
# CUSTOM COMMIT TYPES
# ─────────────────────────────────────────────────────────────────────────────
# Standard types + custom additions for MCP development

[commit_types]
# Standard conventional commits
feat = { changelog_title = "✨ Features", order = 1, bump_minor = true }
fix = { changelog_title = "🐛 Bug Fixes", order = 2, bump_patch = true }
docs = { changelog_title = "📚 Documentation", order = 6 }
style = { changelog_title = "💄 Styling", order = 8 }
refactor = { changelog_title = "♻️ Refactoring", order = 7 }
perf = { changelog_title = "⚡ Performance", order = 3, bump_patch = true }
test = { changelog_title = "🧪 Tests", order = 9 }
build = { changelog_title = "📦 Build", order = 10 }
ci = { changelog_title = "👷 CI/CD", order = 11 }
chore = { changelog_title = "🔧 Chores", omit_from_changelog = true }
revert = { changelog_title = "⏪ Reverts", order = 5, bump_patch = true }

# Custom types for this project
hotfix = { changelog_title = "🚑 Hotfixes", order = 0, bump_patch = true }
security = { changelog_title = "🔒 Security", order = 0, bump_patch = true }
deps = { changelog_title = "📦 Dependencies", order = 4, bump_patch = true }
wip = { omit_from_changelog = true }
release = { changelog_title = "🚀 Releases", omit_from_changelog = true }

# ─────────────────────────────────────────────────────────────────────────────
# SCOPES (Optional - for validation and autocomplete)
# ─────────────────────────────────────────────────────────────────────────────
# Define allowed scopes for your project

[scopes]
# Core components
core = "Core functionality"
api = "API layer"
cli = "Command-line interface"
config = "Configuration"

# MCP-specific scopes
mcp = "MCP protocol"
transport = "Transport layer (stdio, sse, http)"
tools = "MCP tools"
resources = "MCP resources"
prompts = "MCP prompts"

# Infrastructure
ci = "CI/CD pipelines"
docker = "Container configuration"
deps = "Dependencies"
docs = "Documentation"

# ─────────────────────────────────────────────────────────────────────────────
# CHANGELOG CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

[changelog]
path = "CHANGELOG.md"
template = "remote"
remote = "github.com"
owner = "your-org"
repository = "your-repo"

# Author mappings (git email → display name)
authors = [
    { username = "your-username", signature = "Your Name" },
]

# ─────────────────────────────────────────────────────────────────────────────
# VERSION BUMPING HOOKS
# ─────────────────────────────────────────────────────────────────────────────

pre_bump_hooks = [
    "cargo fmt --check",
    "cargo clippy -- -D warnings",
    "cargo test --all-features",
]

post_bump_hooks = [
    "cargo build --release",
    "git push",
    "git push origin {{version}}",
]

# ─────────────────────────────────────────────────────────────────────────────
# MONOREPO SUPPORT (Optional)
# ─────────────────────────────────────────────────────────────────────────────

# [packages.my-crate]
# path = "crates/my-crate"
# changelog_path = "crates/my-crate/CHANGELOG.md"
# include = ["crates/my-crate/**"]
# ignore = ["crates/my-crate/tests/**"]
```

#### 3.11.2 .commitlintrc.js (commitlint Configuration)

```javascript
// .commitlintrc.js - Detailed commit message validation

module.exports = {
  extends: ['@commitlint/config-conventional'],

  // ─────────────────────────────────────────────────────────────────────────
  // CUSTOM RULES
  // ─────────────────────────────────────────────────────────────────────────
  // Rule format: [level, applicable, value]
  // Level: 0 = disable, 1 = warning, 2 = error
  // Applicable: 'always' | 'never'

  rules: {
    // ─────────────────────────────────────────────────────────────────────
    // TYPE RULES (must match cog.toml types)
    // ─────────────────────────────────────────────────────────────────────
    'type-enum': [2, 'always', [
      // Standard types
      'feat', 'fix', 'docs', 'style', 'refactor',
      'perf', 'test', 'build', 'ci', 'chore', 'revert',
      // Custom types (must match cog.toml)
      'hotfix', 'security', 'deps', 'wip', 'release',
    ]],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],

    // ─────────────────────────────────────────────────────────────────────
    // SCOPE RULES (must match cog.toml scopes)
    // ─────────────────────────────────────────────────────────────────────
    'scope-enum': [2, 'always', [
      // Core
      'core', 'api', 'cli', 'config',
      // MCP-specific
      'mcp', 'transport', 'tools', 'resources', 'prompts',
      // Infrastructure
      'ci', 'docker', 'deps', 'docs',
    ]],
    'scope-case': [2, 'always', 'lower-case'],
    'scope-empty': [1, 'never'],  // Warning if no scope (not error)

    // ─────────────────────────────────────────────────────────────────────
    // HEADER RULES (type(scope): subject)
    // ─────────────────────────────────────────────────────────────────────
    'header-max-length': [2, 'always', 72],
    'header-min-length': [2, 'always', 10],
    'header-full-stop': [2, 'never', '.'],
    'header-trim': [2, 'always'],

    // ─────────────────────────────────────────────────────────────────────
    // SUBJECT RULES
    // ─────────────────────────────────────────────────────────────────────
    'subject-case': [2, 'never', [
      'sentence-case',
      'start-case',
      'pascal-case',
      'upper-case',
    ]],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],

    // ─────────────────────────────────────────────────────────────────────
    // BODY RULES
    // ─────────────────────────────────────────────────────────────────────
    'body-leading-blank': [2, 'always'],
    'body-max-line-length': [2, 'always', 100],
    'body-min-length': [0, 'always', 0],  // Optional body

    // ─────────────────────────────────────────────────────────────────────
    // FOOTER RULES
    // ─────────────────────────────────────────────────────────────────────
    'footer-leading-blank': [2, 'always'],
    'footer-max-line-length': [2, 'always', 100],

    // ─────────────────────────────────────────────────────────────────────
    // SPECIAL RULES
    // ─────────────────────────────────────────────────────────────────────
    // Signed-off-by trailer (optional, set to 2 to require)
    'signed-off-by': [0, 'always', 'Signed-off-by:'],

    // References (issue/PR links) - warning if missing
    'references-empty': [1, 'never'],

    // Breaking changes must have both ! and BREAKING CHANGE footer
    // (or neither - XNOR behavior)
    // 'breaking-change-exclamation-mark': [2, 'always'],
  },

  // ─────────────────────────────────────────────────────────────────────────
  // HELP URL
  // ─────────────────────────────────────────────────────────────────────────
  helpUrl: 'https://www.conventionalcommits.org/en/v1.0.0/',
};
```

#### 3.11.3 lint-commits.yml (Commit Validation Workflow)

```yaml
name: Lint Commits

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  # ─────────────────────────────────────────────────────────────────────────
  # COCOGITTO: Validate commit types and generate changelog preview
  # ─────────────────────────────────────────────────────────────────────────
  cocogitto:
    name: Cocogitto Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for commit range

      - name: Install Cocogitto
        run: |
          curl -sSL https://github.com/cocogitto/cocogitto/releases/latest/download/cocogitto-x86_64-unknown-linux-gnu.tar.gz | tar xz
          sudo mv cog /usr/local/bin/

      - name: Validate commits
        run: |
          # Check all commits in PR against conventional commits spec
          cog check --from-latest-tag || cog check

      - name: Preview changelog
        if: success()
        run: |
          echo "## Changelog Preview" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
          cog changelog --at HEAD >> $GITHUB_STEP_SUMMARY || echo "No changelog entries" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY

  # ─────────────────────────────────────────────────────────────────────────
  # COMMITLINT: Detailed message validation
  # ─────────────────────────────────────────────────────────────────────────
  commitlint:
    name: Commitlint Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install commitlint
        run: |
          npm install --save-dev @commitlint/cli @commitlint/config-conventional

      - name: Validate commit messages
        run: |
          npx commitlint --from ${{ github.event.pull_request.base.sha }} --to ${{ github.event.pull_request.head.sha }} --verbose

  # ─────────────────────────────────────────────────────────────────────────
  # PR TITLE CHECK (for squash merges)
  # ─────────────────────────────────────────────────────────────────────────
  pr-title:
    name: PR Title Check
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            style
            refactor
            perf
            test
            build
            ci
            chore
            revert
            hotfix
            security
            deps
            wip
            release
          scopes: |
            core
            api
            cli
            config
            mcp
            transport
            tools
            resources
            prompts
            ci
            docker
            deps
            docs
          requireScope: false
          subjectPattern: ^[a-z].+$
          subjectPatternError: |
            Subject must start with lowercase letter.
            Example: "feat(mcp): add new transport layer"
```

### 3.12 Configuration Files

| File | Purpose |
|------|---------|
| `.pre-commit-config.yaml` | Pre-commit hook definitions |
| `.typos.toml` | Spelling exceptions |
| `.markdownlint.json` | Markdown rules |
| `.yamllint.yml` | YAML rules |
| `.shellcheckrc` | Shellcheck rules |
| `.editorconfig` | Editor settings |
| `taplo.toml` | TOML formatting |
| `cog.toml` | Cocogitto - custom types, changelog, versioning |
| `.commitlintrc.js` | commitlint - header/body/footer validation |
| `clippy.toml` | Clippy configuration |
| `rustfmt.toml` | Rust formatting |
| `ruff.toml` | Python linting/formatting |
| `.eslintrc.js` | JS/TS linting |
| `.prettierrc` | JS/TS/JSON/YAML formatting |
| `.golangci.yml` | Go linting |

---

## 4. Review & Validation

- [ ] Pre-commit hooks run locally without errors
- [ ] pre-commit.ci auto-fixes PRs correctly
- [ ] All workflows pass `actionlint`
- [ ] SARIF uploads to Security tab
- [ ] Path filters work correctly
- [ ] Spelling catches real typos, no false positives
- [ ] Config files are sensible defaults
- [ ] Implementation tracking checklist updated

### Commit Linting Validation

- [ ] Cocogitto installed and `cog check` works locally
- [ ] commitlint installed and validates commits
- [ ] Custom types accepted (hotfix, security, deps, wip, release)
- [ ] Custom scopes accepted (mcp, transport, tools, resources, prompts)
- [ ] Header length enforced (max 72 chars)
- [ ] Body/footer rules validated (blank lines, line length)
- [ ] PR title validation catches malformed titles
- [ ] Changelog preview generated in PR summary
- [ ] Types/scopes synchronized between cog.toml, .commitlintrc.js, and lint-commits.yml
