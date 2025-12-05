---
id: a8f2e4c1-3b9d-4e7f-8a6b-9c0d1e2f3a4b
title: "Bundle Expansion Overview"
status: active
created: 2025-12-05
type: overview
---

# Bundle Expansion Overview

## Purpose

Expand the MCP template bundle to include comprehensive CI/CD workflows, templates, and configurations for multi-language projects with a focus on security, compliance, and automation.

---

## Important Context

> **This plan produces a versioned release artifact (bundle) for onboarding new repositories to "MCP Server Development" standards.**

### Scope Clarification

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PLANNING CONTEXT                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DEFAULT: Template Development                                               │
│  ─────────────────────────────────────────────────────────────────────────  │
│  All phases develop TEMPLATES, CONFIGS, and WORKFLOWS intended for          │
│  packaging into a versioned bundle. These artifacts are NOT directly         │
│  applied to the aRustyDev/mcp repository.                                   │
│                                                                              │
│  Target: Unknown future repositories that will consume this bundle           │
│                                                                              │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                              │
│  EXCEPTION: aRustyDev/mcp Configuration                                      │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Tasks explicitly marked with [MCP-REPO] are intended for direct             │
│  configuration of the aRustyDev/mcp repository itself.                       │
│                                                                              │
│  Example: "## [MCP-REPO] Configure branch protection"                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Bundle Output

When implemented, this plan produces:

| Artifact | Description |
|----------|-------------|
| `mcp-bundle-v{X.Y.Z}.tar.gz` | Versioned release archive |
| `MANIFEST.md` | Bundle contents and installation guide |
| `justfile` | Automated setup commands |
| `AGENT.md` | AI agent instructions for target repo |

### Bundle Consumer Workflow

```
1. Download bundle release
2. Extract to target repository root
3. Run `just setup` for automated configuration
4. Complete Phase 00 manual steps
5. Customize templates as needed
```

### Tagging Convention

- Template tasks: No special tag (default)
- aRustyDev/mcp tasks: `[MCP-REPO]` prefix in section header

---

## Phase Gate: Justfile Review

> **REQUIRED**: Before beginning ANY phase, conduct a justfile review conversation with the user.

### Purpose

This quality gate prevents the justfile from diverging or spiraling out of control during development. Each phase may add, modify, or refine justfile recipes, and regular review ensures coherent evolution.

### Gate Process

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PHASE GATE: JUSTFILE REVIEW                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  BEFORE starting Phase N:                                                    │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 1. JUSTFILE STATE REVIEW                                             │   │
│  │    ├── Present current justfile structure                            │   │
│  │    ├── List all recipes and their purposes                           │   │
│  │    ├── Identify recipes added in previous phases                     │   │
│  │    └── Flag any complexity concerns                                  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 2. WORKFLOW COMPARISON                                               │   │
│  │    ├── Expected workflow (from plan)                                 │   │
│  │    ├── Current workflow (as implemented)                             │   │
│  │    ├── Identify gaps or divergences                                  │   │
│  │    └── Discuss any scope changes                                     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 3. PHASE N PLANNING                                                  │   │
│  │    ├── What justfile changes does Phase N require?                   │   │
│  │    ├── What new recipes will be added?                               │   │
│  │    ├── What existing recipes need modification?                      │   │
│  │    └── How will this integrate with existing workflow?               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 4. USER APPROVAL                                                     │   │
│  │    ├── User confirms understanding of current state                  │   │
│  │    ├── User approves planned justfile changes                        │   │
│  │    └── User provides any additional context or constraints           │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              ↓                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 5. PROCEED WITH PHASE                                                │   │
│  │    └── Begin phase implementation                                    │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Review Conversation Template

When initiating a phase, start with:

```markdown
## Phase N Gate: Justfile Review

### Current Justfile State

**Recipes implemented:**
- `just init <target>` - Main entry point (Phase 01)
- `just configure` - Interactive setup (Phase 01)
- ... [list all recipes]

**Recent changes (Phase N-1):**
- Added: [recipes]
- Modified: [recipes]
- Removed: [recipes]

### Workflow Comparison

**Expected (from plan):**
[Describe what the plan says the workflow should be]

**Current (as implemented):**
[Describe what the justfile actually does]

**Divergences:**
- [List any differences]

### Phase N Impact

**Planned justfile changes:**
- [New recipes to add]
- [Existing recipes to modify]

**Questions for user:**
1. [Any decisions needed]
2. [Any clarifications required]

---

**Ready to proceed?** Please review and confirm.
```

### What to Review

| Aspect | Questions to Address |
|--------|---------------------|
| **Complexity** | Is the justfile growing too complex? Should we split into modules? |
| **Consistency** | Are naming conventions consistent? Are patterns reusable? |
| **Dependencies** | Are external tool dependencies reasonable? |
| **Error Handling** | Do recipes fail gracefully with helpful messages? |
| **Documentation** | Are recipes self-documenting? Is help text adequate? |
| **Testing** | Have new recipes been tested? |
| **Integration** | Do new recipes integrate cleanly with existing ones? |

### Gate Exceptions

The gate may be abbreviated (not skipped) for:

- **Minor phases** with no justfile impact (still mention "no justfile changes expected")
- **Hotfix phases** where urgency is documented
- **Documentation-only phases** (Phase 00)

Even in these cases, briefly confirm: "Phase N has no expected justfile changes. Proceed?"

---

## Phase Summary

| # | Phase | Focus | Status |
|---|-------|-------|--------|
| 00 | Manual Setup | Wiki init, secrets, branch protection, local setup | pending |
| 01 | Foundation | Templates, Labels, Core Configs, AGENT.md | pending |
| 02 | Build Pipelines | Container, Rust, Python, Node builds | pending |
| 03 | Code Quality | Linting workflows for all languages | pending |
| 04 | Testing - Unit | Language-specific unit test workflows | pending |
| 05 | Testing - Property | Property-based testing (proptest, Hypothesis) | pending |
| 06 | Testing - Integration | Cross-component integration tests | pending |
| 07 | Testing - E2E | End-to-end test workflows | pending |
| 08 | Testing - Performance | Benchmark and performance regression | pending |
| 09 | Testing - Coverage | Code coverage collection and reporting | pending |
| 10 | Testing - Quality Gates | Coverage thresholds and gates | pending |
| 11 | Testing - MCP Protocol | MCP-specific protocol conformance | pending |
| 12 | Testing - Mock Harness | Mock infrastructure and fixtures | pending |
| 13 | Testing - Chaos | Resilience and chaos engineering | pending |
| 14 | Security - Dependencies | Dependency scanning (4-layer Rust) | pending |
| 15 | Security - Licenses | License compliance and SBOM | pending |
| 16 | Security - SAST | Static analysis (Semgrep, CodeQL) | pending |
| 17 | Security - Secrets | Secret scanning (Gitleaks, TruffleHog) | pending |
| 18 | Security - Memory | Memory safety (Miri, sanitizers) | pending |
| 19 | Security - Fuzzing | Fuzz testing for all languages | pending |
| 20 | Security - Taint | Data flow and taint analysis | pending |
| 21 | Security - Containers | Container image scanning | pending |
| 22 | Security - Compliance | CIS, PCI-DSS, HIPAA checklists | pending |
| 22a | Policy Library | OPA/Rego policy CI/CD, shared library | pending |
| 23 | Security - Attestation | SLSA, SBOM, cosign signing | pending |
| 24 | Release - Versioning | Semantic release, changelog | pending |
| 25 | Release - Containers | Container publishing (GHCR, Docker Hub) | pending |
| 26 | Release - Packages | Package publishing (crates.io, PyPI, npm) | pending |
| 27 | Release - Helm | Helm chart workflows | pending |
| 28 | Automation - Issues | Issue/PR automation, labeling | pending |
| 29 | Automation - Notifications | Slack, Discord webhooks | pending |
| 30 | Automation - MCP | MCP evaluation and discovery | pending |

---

## Bundle Structure

```
bundles/
├── .github/
│   ├── ISSUE_TEMPLATE/          # Issue templates (Phase 01)
│   ├── workflows/               # GitHub Actions workflows (Phases 02-30)
│   ├── labels.yml               # Label definitions (Phase 01)
│   ├── labeler.yml              # Path-based labeler (Phase 28)
│   └── dependabot.yml           # Dependency updates (Phase 14)
├── policies/                    # OPA/Rego policy library (Phase 22a)
│   ├── container/               # Container security policies (Phase 21)
│   ├── compliance/              # CIS, PCI-DSS policies (Phase 22)
│   ├── license/                 # License enforcement policies (Phase 15)
│   ├── lib/                     # Shared utility functions
│   ├── data/                    # External data (allowlists, etc.)
│   ├── tests/                   # Policy unit tests
│   └── .manifest                # Bundle version and metadata
├── configs/
│   ├── mcp/                     # MCP client configurations (Phase 01)
│   │   ├── project/             # Project-local configs (enabled by default)
│   │   │   ├── servers.json     # Common dev servers
│   │   │   └── servers-*.json   # Language-specific servers
│   │   └── global/              # Global config templates (manual install)
│   │       ├── common-servers.json
│   │       └── install.sh
│   ├── .releaserc.json          # Semantic release (Phase 24)
│   ├── codecov.yml              # Coverage config (Phase 09)
│   ├── .gitleaks.toml           # Secret scanning (Phase 17)
│   └── ...                      # Tool configurations
├── docs/
│   └── ...                      # Documentation
├── justfile                     # Setup automation
├── MANIFEST.md                  # Bundle contents
└── AGENT.md                     # AI agent instructions (Phase 01)
```

---

## Related Documents

### Checklists
- [Gap Analysis](checklists/gap-analysis.md) - Capability gaps and action items
- [Implementation Tracking](checklists/implementation-tracking.md) - Task completion status
- [Testing Validation](checklists/testing-validation.md) - Final validation checklist

### References
- [MCP Testing Taxonomy](references/mcp-testing-taxonomy.md) - Comprehensive MCP test specifications
- [Quick Start Guide](references/quick-start.md) - Developer onboarding

### ADRs
- [Frontmatter Standard](../docs/adr/frontmatter-standard.md) - YAML frontmatter specification for plan documents
- [Dependency Scanning Strategy](../docs/adr/dependency-scanning-strategy.md) - 4-layer Rust defense model

### Strategies
- [AI Context Strategy](../docs/strategies/ai-context.md) - AGENT.md and AI agent behavioral guidance
- [Policy-as-Code Strategy](../docs/strategies/policy-as-code.md) - OPA/Rego unified policy library
- [Tagging and Versioning Strategy](../docs/strategies/tagging-and-versioning.md) - Version source of truth and release coordination

---

## Success Criteria

- [ ] All workflows pass `actionlint` validation
- [ ] Bundle extracts correctly to target repo
- [ ] `just setup` works on empty repo
- [ ] Each workflow runs without errors
- [ ] SARIF uploads to GitHub Security tab
- [ ] Selective installation supported
- [ ] Documentation complete and accurate

---

## File Estimates by Phase Category

| Category | Phases | Est. Files |
|----------|--------|------------|
| Foundation | 01 | ~48 |
| Build & Quality | 02-03 | ~13 |
| Testing | 04-13 | ~50 |
| Security | 14-22, 22a, 23 | ~65 |
| Release | 24-27 | ~20 |
| Automation | 28-30 | ~11 |

**Total Estimated: ~207 workflow/config/policy files**

*Notes:*
- *Foundation includes +9 MCP client config files (5 project-local, 4 global)*
- *Security includes +15 OPA/Rego policy files from Phase 22a policy library*
