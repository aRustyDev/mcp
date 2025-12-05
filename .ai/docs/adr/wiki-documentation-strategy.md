---
title: Wiki Documentation Strategy
status: approved
date: 2025-12-05
decision-makers: [arustydev]
tags: [documentation, wiki, ai-agents, llms-txt, mcp, context7, gitmcp]
---

# Wiki Documentation Strategy

## Context

This project requires a centralized documentation store that serves multiple audiences:

1. **AI Agents**: Need structured context via LLMs.txt for effective assistance
2. **Developers**: Need setup guides, API docs, and architecture references
3. **MCP Tools**: Need accessible endpoints for context retrieval

Additionally, the documentation must be:
- Programmatically accessible (for AI tools and automation)
- Version controlled (for history and collaboration)
- Discoverable (via standard conventions like LLMs.txt)

## Decision

Use the **GitHub Wiki** as the central documentation hub, accessible via multiple protocols:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    WIKI DOCUMENTATION ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  GITHUB WIKI                                                     │    │
│  │  https://github.com/<owner>/<repo>/wiki                         │    │
│  │                                                                  │    │
│  │  ├── Home.md              # Landing page                        │    │
│  │  ├── LLMs.txt             # AI context (brief)                  │    │
│  │  ├── LLMs-Full.txt        # AI context (comprehensive)          │    │
│  │  ├── ADRs/                # Architecture decisions              │    │
│  │  ├── Guides/              # Setup, tool guides                  │    │
│  │  ├── References/          # API docs, specs                     │    │
│  │  └── _Sidebar.md          # Navigation                          │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                           │
│              ┌───────────────┼───────────────┐                          │
│              ▼               ▼               ▼                          │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               │
│  │   CONTEXT7    │  │    GITMCP     │  │  RAW ACCESS   │               │
│  │               │  │               │  │               │               │
│  │ Point to wiki │  │ gitmcp.io/    │  │ raw.github    │               │
│  │ for LLMs.txt  │  │ owner/repo    │  │ usercontent/  │               │
│  │               │  │ .wiki         │  │ wiki/...      │               │
│  └───────────────┘  └───────────────┘  └───────────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Access Methods

| Method | URL Pattern | Use Case |
|--------|-------------|----------|
| **Web UI** | `github.com/<owner>/<repo>/wiki` | Human browsing |
| **Git Clone** | `github.com/<owner>/<repo>.wiki.git` | Programmatic access, CI/CD |
| **Context7** | Configure to fetch from wiki | AI agent context |
| **GitMCP** | `gitmcp.io/<owner>/<repo>.wiki` | MCP server endpoint |
| **Raw Content** | `raw.githubusercontent.com/wiki/<owner>/<repo>/<page>.md` | Direct file access |

---

## LLMs.txt Standard

Follow the [LLMs.txt specification](https://llmstxt.org/) for AI agent discoverability:

### LLMs.txt (Brief Version)

```markdown
# Project Name

> Brief project description for AI agents

## Quick Context

- **Purpose**: What this project does
- **Tech Stack**: Languages, frameworks, key dependencies
- **Architecture**: High-level structure

## Key Files

- `/src/main.rs` - Entry point
- `/src/lib.rs` - Core library
- `/docs/` - Documentation

## Conventions

- Conventional commits required
- Pre-commit hooks enforced
- Tests required for all features

## Getting Help

- [Full Documentation](LLMs-Full)
- [API Reference](API-Reference)
- [ADRs](ADRs)
```

### LLMs-Full.txt (Comprehensive Version)

```markdown
# Project Name - Full Context

> Comprehensive context for AI agents requiring deep understanding

## Architecture

[Detailed architecture description]

## Code Structure

[Directory layout with explanations]

## Development Workflow

[How to contribute, test, deploy]

## API Reference

[Key APIs and their usage]

## Common Tasks

### Adding a new feature
[Step-by-step guide]

### Fixing a bug
[Debugging workflow]

### Running tests
[Test commands and conventions]

## Troubleshooting

[Common issues and solutions]
```

---

## Wiki Structure

### Required Pages

| Page | Purpose | Audience |
|------|---------|----------|
| `Home.md` | Landing page, navigation | All |
| `LLMs.txt` | AI context (brief) | AI Agents |
| `LLMs-Full.txt` | AI context (comprehensive) | AI Agents |
| `_Sidebar.md` | Navigation sidebar | All |
| `ADRs.md` | ADR index | Developers |
| `Setup-Guide.md` | Getting started | Developers |

### Recommended Pages

| Page | Purpose |
|------|---------|
| `Contributing.md` | Contribution guidelines |
| `API-Reference.md` | API documentation |
| `Tool-Guides.md` | Tool usage guides |
| `Troubleshooting.md` | Common issues |
| `Changelog.md` | Release history |

### Directory Structure

```
wiki/
├── Home.md                    # Landing page
├── LLMs.txt                   # AI context (brief)
├── LLMs-Full.txt              # AI context (full)
├── _Sidebar.md                # Navigation
├── _Footer.md                 # Optional footer
│
├── ADRs/                      # Architecture decisions
│   ├── linting-strategy.md
│   ├── dependency-scanning.md
│   └── wiki-documentation.md
│
├── Guides/                    # How-to guides
│   ├── Setup-Guide.md
│   ├── Contributing.md
│   └── Tool-Guides.md
│
└── References/                # Reference docs
    ├── API-Reference.md
    ├── Configuration.md
    └── Troubleshooting.md
```

---

## Integration with AI Tools

### Context7 Configuration

```json
{
  "sources": [
    {
      "type": "github-wiki",
      "url": "https://github.com/<owner>/<repo>/wiki",
      "files": ["LLMs.txt", "LLMs-Full.txt"]
    }
  ]
}
```

### GitMCP Configuration

Point GitMCP server to wiki repository:

```
https://gitmcp.io/<owner>/<repo>.wiki
```

This exposes the wiki as an MCP server, allowing AI agents to:
- Browse wiki pages as resources
- Search documentation
- Access LLMs.txt for context

### Claude Code / Cursor Configuration

```json
{
  "mcpServers": {
    "project-docs": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-git", "--repository", "https://github.com/<owner>/<repo>.wiki.git"]
    }
  }
}
```

---

## Synchronization Strategy

### Source of Truth

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SYNC DIRECTION                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Main Repository                    Wiki Repository                    │
│   ┌─────────────────┐               ┌─────────────────┐                │
│   │ .ai/docs/adr/   │ ───────────▶  │ ADRs/           │                │
│   │ docs/           │ ───────────▶  │ Guides/         │                │
│   │ CHANGELOG.md    │ ───────────▶  │ Changelog.md    │                │
│   └─────────────────┘               └─────────────────┘                │
│                                                                          │
│   Sync triggers:                                                         │
│   • Push to main branch                                                  │
│   • Changes in docs/ or .ai/docs/                                       │
│   • Manual workflow dispatch                                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Wiki Sync Workflow

```yaml
name: Sync Docs to Wiki

on:
  push:
    branches: [main]
    paths:
      - 'docs/**'
      - '.ai/docs/**'
      - 'CHANGELOG.md'
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

      - name: Sync ADRs
        run: |
          mkdir -p wiki/ADRs
          cp -r repo/.ai/docs/adr/*.md wiki/ADRs/

      - name: Sync docs
        run: |
          cp -r repo/docs/*.md wiki/Guides/ 2>/dev/null || true
          cp repo/CHANGELOG.md wiki/Changelog.md 2>/dev/null || true

      - name: Generate LLMs.txt
        run: |
          # Generate from template or existing file
          if [ -f repo/docs/llms.txt ]; then
            cp repo/docs/llms.txt wiki/LLMs.txt
          fi

      - name: Update ADR index
        run: |
          echo "# Architecture Decision Records" > wiki/ADRs.md
          echo "" >> wiki/ADRs.md
          echo "| ADR | Status | Date |" >> wiki/ADRs.md
          echo "|-----|--------|------|" >> wiki/ADRs.md
          for f in wiki/ADRs/*.md; do
            name=$(basename "$f" .md)
            title=$(grep -m1 "^title:" "$f" | cut -d: -f2- | xargs)
            status=$(grep -m1 "^status:" "$f" | cut -d: -f2- | xargs)
            date=$(grep -m1 "^date:" "$f" | cut -d: -f2- | xargs)
            echo "| [[$name\|$title]] | $status | $date |" >> wiki/ADRs.md
          done

      - name: Commit and push
        run: |
          cd wiki
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          if ! git diff --quiet --staged; then
            git commit -m "docs: sync from main repo"
            git push
          fi
```

---

## Manual Setup Required

Due to GitHub limitations, the wiki must be manually initialized:

1. Navigate to repository → Wiki tab
2. Create first page (`Home.md`)
3. Create `LLMs.txt` page
4. Configure MCP tools to point to wiki

See **Phase 00: Manual Setup** for complete checklist.

---

## Consequences

### Positive

- **Centralized documentation**: Single source for all docs
- **AI-accessible**: LLMs.txt standard + MCP integration
- **Version controlled**: Wiki is a Git repository
- **Discoverable**: Standard URLs and conventions
- **Automatic sync**: CI/CD keeps wiki in sync with repo
- **Multiple access methods**: Web, Git, raw, MCP

### Negative

- **Manual initialization**: First page must be created via UI
- **Separate repository**: Wiki is a different Git repo
- **No API access**: Cannot create/read via GitHub REST API
- **Sync complexity**: Requires workflow to keep in sync

### Mitigations

- Document manual steps in Phase 00
- Wiki sync workflow automates ongoing updates
- Multiple access methods reduce single point of failure
- LLMs.txt provides standardized AI context format

---

## References

- [LLMs.txt Specification](https://llmstxt.org/)
- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [GitMCP](https://gitmcp.io/)
- [Context7 MCP Server](https://github.com/upstash/context7)
- [Gollum Wiki](https://github.com/gollum/gollum) - GitHub's wiki engine
- [Stack Overflow: Clone GitHub Wiki](https://stackoverflow.com/questions/15080848/how-do-i-clone-a-github-wiki)
