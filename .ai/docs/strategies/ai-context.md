---
id: c7e8f9a0-1b2c-3d4e-5f6a-7b8c9d0e1f2a
title: "AI Context Strategy"
status: active
created: 2025-12-05
type: strategy
related:
  - ../adr/frontmatter-standard.md
  - tagging-and-versioning.md
---

# AI Context Strategy

## Overview

This document defines how the MCP bundle provides context and behavioral guidance to AI coding assistants. The goal is to ensure AI agents working with bundle-initialized repositories follow consistent development practices.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AI CONTEXT ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      AGENT.md (Root)                                 │   │
│  │  ────────────────────────────────────────────────────────────────── │   │
│  │  Universal behavioral guidance for all AI agents                    │   │
│  │  • Git workflow (branches, commits, PRs)                            │   │
│  │  • Planning methodology                                             │   │
│  │  • Debugging approach                                               │   │
│  │  • Coding standards per language                                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              Agent-Specific Configuration                            │   │
│  │  ────────────────────────────────────────────────────────────────── │   │
│  │                                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │   │
│  │  │ .claude/ │  │ .cursor/ │  │ .github/ │  │  .zed/   │           │   │
│  │  │ CLAUDE.md│  │ rules/   │  │ copilot/ │  │settings  │           │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │   │
│  │                                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                          │   │
│  │  │.windsurf/│  │ .vscode/ │  │ .codex/  │                          │   │
│  │  │ rules/   │  │settings  │  │ config   │                          │   │
│  │  └──────────┘  └──────────┘  └──────────┘                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    MCP Server Configuration                          │   │
│  │  ────────────────────────────────────────────────────────────────── │   │
│  │  Tool availability and capabilities                                  │   │
│  │                                                                      │   │
│  │  .mcp/                                                               │   │
│  │  ├── servers.json           # Common servers (context7, github)     │   │
│  │  ├── servers-rust.json      # Rust: cargo, rustfmt                  │   │
│  │  ├── servers-python.json    # Python: ruff, uv                      │   │
│  │  └── servers-typescript.json# TypeScript: eslint, prettier          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Context Layers

### Layer 1: AGENT.md (Universal)

The root `AGENT.md` file provides behavioral guidance applicable to **all** AI agents regardless of platform. This is the **single source of truth** for development practices.

**Location**: Repository root (`/AGENT.md`)

**Contents**:

| Section | Purpose | Key Elements |
|---------|---------|--------------|
| **Branch Strategy** | Git workflow | Naming conventions, merge targets, protection rules |
| **Commit Strategy** | Version control | Conventional commits, atomic commits, trailers |
| **PR Workflow** | Code review | Lifecycle, merge strategy, CI gates |
| **Planning Strategy** | Task approach | Decomposition, sequencing, risk identification |
| **Debugging Strategy** | Problem solving | Scientific method, bisect, log analysis |
| **Coding Standards** | Language-specific | Style, patterns, documentation |

**Why AGENT.md?**
- Platform-agnostic (works with any AI agent)
- Human-readable (developers can reference too)
- Version-controlled (changes tracked)
- Single source of truth (no duplication)

### Layer 2: Agent-Specific Configuration

Each AI agent may have its own configuration directory that **extends** (not replaces) AGENT.md.

| Agent | Directory | Config Files | Purpose |
|-------|-----------|--------------|---------|
| Claude Code | `.claude/` | `CLAUDE.md`, `settings.json` | Claude-specific instructions |
| Cursor | `.cursor/` | `rules/` directory | Cursor rules and prompts |
| GitHub Copilot | `.github/copilot/` | `instructions.md` | Copilot context |
| Zed | `.zed/` | `settings.json` | Zed AI configuration |
| Windsurf | `.windsurf/` | `rules/` directory | Windsurf prompts |
| VS Code | `.vscode/` | `settings.json` | Generic VS Code AI |
| Codex | `.codex/` | `config.yaml` | OpenAI Codex config |
| Gemini | `.gemini/` | `config.yaml` | Google Gemini config |

**Layering Principle**:
```
AGENT.md (base)
    │
    └── Agent-specific config (extends)
         │
         └── User preferences (personal overrides)
```

### Layer 3: MCP Server Configuration

MCP servers provide **tool capabilities** to AI agents. This layer defines what tools are available, not how to use them (that's in AGENT.md).

**Location**: `.mcp/` directory

**Files**:

```
.mcp/
├── servers.json              # Always loaded (common tools)
├── servers-rust.json         # Rust language tools
├── servers-python.json       # Python language tools
├── servers-typescript.json   # TypeScript/Node tools
└── servers-golang.json       # Go language tools
```

**Common Servers** (always available):
- `context7` - Documentation lookup
- `github` - Repository operations
- `fetch` - Web fetching
- `sequential-thinking` - Complex reasoning

**Language Servers** (loaded based on project):
- Rust: `cargo`, `rustfmt`, `clippy`
- Python: `ruff`, `uv`, `pytest`
- TypeScript: `eslint`, `prettier`, `vitest`
- Go: `golangci-lint`, `go-test`

---

## Strategy Definitions

### Commit Strategy

**Goal**: Ensure every commit is atomic, traceable, and reversible.

**Key Principles**:

1. **Atomic**: One logical change per commit
2. **Traceable**: Linked to issue/PR via conventional commit
3. **Reversible**: Can be reverted independently

**Commit Flow**:
```
┌──────────────────────────────────────────────────────────────────────────┐
│                          COMMIT DECISION TREE                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Is this change logically independent?                                    │
│      │                                                                    │
│      ├── YES → Can it be reverted without breaking other changes?        │
│      │           │                                                        │
│      │           ├── YES → Commit separately                             │
│      │           │                                                        │
│      │           └── NO → Combine with dependent change                  │
│      │                                                                    │
│      └── NO → Combine into single commit                                 │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

**Conventional Commit Types**:
- `feat` - New feature (MINOR version bump)
- `fix` - Bug fix (PATCH version bump)
- `feat!` / `fix!` - Breaking change (MAJOR version bump)
- `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore` - No version bump

### Git Workflow Strategy

**Goal**: Maintain clean history and enable efficient collaboration.

**Branch Hierarchy**:
```
main (protected, production-ready)
├── feature/* (human-created features)
├── fix/* (human-created bug fixes)
├── refactor/* (human-created improvements)
├── docs/* (human-created documentation)
├── pr/* (CI-created for PR validation)
└── deps/* (CI-created for dependency updates)
```

**Merge Strategy Decision**:
```
┌──────────────────────────────────────────────────────────────────────────┐
│                        MERGE STRATEGY SELECTION                           │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  How many meaningful commits in PR?                                       │
│      │                                                                    │
│      ├── 1 commit → Squash and Merge (default)                           │
│      │                                                                    │
│      ├── Multiple, same author, logical sequence                         │
│      │      → Squash and Merge (combine into one)                        │
│      │                                                                    │
│      └── Multiple, different authors OR distinct features                │
│             → Rebase and Merge (preserve individual commits)             │
│                                                                           │
│  NEVER use Merge Commit (creates noise, disabled at repo level)          │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### Planning Strategy

**Goal**: Approach tasks systematically to minimize rework and maximize clarity.

**Planning Process**:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PLANNING WORKFLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. UNDERSTAND                                                              │
│     ├── Read issue/requirement completely                                   │
│     ├── Identify acceptance criteria                                        │
│     ├── Ask clarifying questions BEFORE coding                             │
│     └── State understanding back (confirm alignment)                        │
│                                                                              │
│  2. DECOMPOSE                                                               │
│     ├── What existing code is affected?                                     │
│     ├── What new code is needed?                                            │
│     ├── What tests are required?                                            │
│     └── What documentation needs updating?                                  │
│                                                                              │
│  3. SEQUENCE                                                                │
│     ├── Order by dependencies (what must exist first?)                      │
│     ├── Prioritize by risk (tackle uncertainty early)                       │
│     └── Consider value delivery (incremental progress)                      │
│                                                                              │
│  4. EXECUTE                                                                 │
│     └── Work through tasks using TDD cycle                                  │
│                                                                              │
│  5. VALIDATE                                                                │
│     ├── All acceptance criteria met?                                        │
│     ├── Tests pass?                                                         │
│     └── Documentation updated?                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**When AI Should Stop and Ask**:
- Requirements are ambiguous
- Multiple valid approaches exist
- Scope appears to be expanding
- External dependency blocks progress
- Estimated effort significantly exceeds expectations

### Debugging Strategy

**Goal**: Find root causes efficiently using scientific method.

**Debugging Process**:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       DEBUGGING WORKFLOW                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. REPRODUCE                                                               │
│     ├── Get exact reproduction steps                                        │
│     ├── Note environment details                                            │
│     ├── Create minimal test case                                            │
│     └── Document in issue                                                   │
│                                                                              │
│  2. ISOLATE                                                                 │
│     ├── Is it this code? → git bisect                                       │
│     ├── Is it a dependency? → Check changelogs                              │
│     ├── Is it configuration? → Diff configs                                 │
│     └── Is it environment? → Test clean env                                 │
│                                                                              │
│  3. HYPOTHESIZE                                                             │
│     ├── State: "I believe X causes Y because Z"                             │
│     ├── Predict: "Fixing X will change behavior to W"                       │
│     └── Plan: "I'll verify by checking V"                                   │
│                                                                              │
│  4. TEST                                                                    │
│     ├── Write failing test demonstrating bug                                │
│     └── Confirm it fails for the right reason                               │
│                                                                              │
│  5. FIX                                                                     │
│     ├── Address root cause (not symptoms)                                   │
│     ├── Keep fix minimal and focused                                        │
│     └── Don't refactor unrelated code                                       │
│                                                                              │
│  6. VERIFY                                                                  │
│     ├── Test passes                                                         │
│     ├── No regressions                                                      │
│     └── Works in original context                                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Agent Configuration Details

### Claude Code

**Directory**: `.claude/`

**Files**:
- `CLAUDE.md` - Project-specific instructions
- `settings.json` - Claude Code settings

**CLAUDE.md Template**:
```markdown
# Project: {project-name}

## Quick Reference
- Language: {language}
- Build: `just build`
- Test: `just test`
- Lint: `just lint`

## Key Patterns
- {Pattern 1 description}
- {Pattern 2 description}

## Files to Know
- `src/main.rs` - Entry point
- `src/lib.rs` - Library root
- `tests/` - Integration tests

## Common Tasks
- Run tests: `cargo test`
- Check types: `cargo check`
- Format: `cargo fmt`
```

### Cursor

**Directory**: `.cursor/`

**Files**:
- `rules/` - Directory of rule files
- `.cursorrules` - (deprecated, use rules/)

**Rule File Template** (`.cursor/rules/development.md`):
```markdown
# Development Rules

## Code Style
- Follow existing patterns in codebase
- Use conventional commits for all changes

## Before Making Changes
1. Read the affected files first
2. Understand existing patterns
3. Write tests before implementation
```

### GitHub Copilot

**Directory**: `.github/copilot/`

**Files**:
- `instructions.md` - Copilot context

**Template**:
```markdown
# Copilot Instructions

This is an MCP server project using {language}.

## Conventions
- Use conventional commits
- Follow TDD (test-driven development)
- Keep functions small and focused

## Key Commands
- Build: `just build`
- Test: `just test`
- Lint: `just lint`
```

---

## MCP Server Configuration

### Common Servers (`.mcp/servers.json`)

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"],
      "description": "Documentation and code examples"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "description": "GitHub repository operations"
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-fetch"],
      "description": "Web content fetching"
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-sequential-thinking"],
      "description": "Complex multi-step reasoning"
    }
  }
}
```

### Language-Specific Servers

**Rust** (`.mcp/servers-rust.json`):
```json
{
  "mcpServers": {
    "cargo": {
      "command": "cargo",
      "description": "Rust package manager"
    }
  }
}
```

**Python** (`.mcp/servers-python.json`):
```json
{
  "mcpServers": {
    "ruff": {
      "command": "ruff",
      "description": "Python linter and formatter"
    },
    "uv": {
      "command": "uv",
      "description": "Python package manager"
    }
  }
}
```

---

## Best Practices

### For AI Agents

1. **Read AGENT.md first** - Before any task, understand project conventions
2. **Follow commit strategy** - Atomic commits with conventional format
3. **Use planning methodology** - Decompose before coding
4. **Apply debugging process** - Don't guess, investigate systematically
5. **Ask when uncertain** - Better to clarify than assume

### For Bundle Maintainers

1. **Keep AGENT.md as source of truth** - Don't duplicate in agent-specific configs
2. **Agent configs extend, not override** - Specific details only
3. **Test with multiple agents** - Ensure guidance works across platforms
4. **Version control everything** - Including MCP server configs
5. **Document exceptions** - When deviating from standard practices

### For Developers

1. **Review AGENT.md when onboarding** - Same guidance as AI uses
2. **Update AGENT.md for new patterns** - Keep AI context current
3. **Use conventional commits** - Enables automated versioning
4. **Follow PR workflow** - Draft → Ready → Review → Merge

---

## Metrics and Validation

### How to Validate AI Context Effectiveness

| Metric | Good Signal | Bad Signal |
|--------|-------------|------------|
| Commit messages | Follow conventional format | Random/inconsistent |
| Branch names | Match pattern (`feature/*`, etc.) | Ad-hoc naming |
| PR descriptions | Complete, linked to issues | Empty/minimal |
| Code style | Matches existing patterns | Inconsistent |
| Test coverage | Tests written with features | Tests as afterthought |

### Continuous Improvement

1. **Track AI-generated commits** - Look for pattern violations
2. **Review PR quality** - Are descriptions complete?
3. **Monitor CI failures** - Are they preventable with better guidance?
4. **Collect feedback** - What do developers wish AI knew?
5. **Update AGENT.md** - Incorporate learnings

---

## Related Documents

- [Tagging and Versioning Strategy](tagging-and-versioning.md) - Version management
- [Frontmatter Standard](../adr/frontmatter-standard.md) - Document metadata
- [Phase 01: Foundation](../../plans/phases/bundle-contents-phase-01-foundation.md) - AGENT.md implementation
