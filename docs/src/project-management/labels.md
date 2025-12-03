# Label System

Labels follow a hierarchical prefix-based naming convention for easy filtering and organization.

## Label Categories

### Type Labels (`type/`)
Describe the nature of the work.

| Label | Description |
|-------|-------------|
| `type/research` | Research and exploration tasks |
| `type/analysis` | Comparative analysis work |
| `type/implementation` | Code implementation work |
| `type/documentation` | Documentation tasks |
| `type/rewrite` | Rust rewrite tasks |
| `type/docker` | Docker/container work |
| `type/ci-cd` | CI/CD pipeline work |

### Phase Labels (`phase/`)
Track workflow stage.

| Label | Description |
|-------|-------------|
| `phase/discovery` | Identifying and cataloging |
| `phase/planning` | Planning and design |
| `phase/development` | Active development |
| `phase/review` | Code/analysis review |
| `phase/testing` | Testing and validation |
| `phase/blocked` | Blocked by dependency |
| `phase/complete` | Work completed |

### Language Labels (`lang/`)
Indicate implementation language.

| Label | Color | Description |
|-------|-------|-------------|
| `lang/python` | #3572A5 | Python implementation |
| `lang/typescript` | #3178C6 | TypeScript implementation |
| `lang/javascript` | #F7DF1E | JavaScript implementation |
| `lang/go` | #00ADD8 | Go implementation |
| `lang/rust` | #DEA584 | Rust implementation |
| `lang/java` | #B07219 | Java implementation |

### Transport Labels (`transport/`)
Describe MCP transport support.

| Label | Description |
|-------|-------------|
| `transport/stdio` | stdio transport only |
| `transport/http-sse` | Native HTTP/SSE support |
| `transport/http-streamed` | Native Streamable HTTP |
| `transport/http-wrapped` | HTTP via supergateway |
| `transport/needs-wrapper` | Needs HTTP wrapper |
| `transport/websocket` | WebSocket support |

### Category Labels (`category/`)
Classify MCP server functionality.

| Label | Description |
|-------|-------------|
| `category/search` | Search-related servers |
| `category/git` | Git/VCS servers |
| `category/docs` | Documentation servers |
| `category/workflow` | Workflow/automation |
| `category/reasoning` | Chain-of-thought |
| `category/db` | Database servers |
| `category/llm` | LLM-related servers |
| `category/notes` | Note-taking/knowledge |
| `category/docker` | Docker/container servers |

### Docker Phase Labels (`docker/`)
Track container development progress.

| Label | Description |
|-------|-------------|
| `docker/none` | No Docker implementation |
| `docker/dockerfile-draft` | Dockerfile in development |
| `docker/dockerfile-reviewed` | Dockerfile approved |
| `docker/image-published` | Image on registry |
| `docker/hadolint-compliant` | Passes HADOLint |

### Rust Rewrite Labels (`rust/`)
Track Rust implementation progress.

| Label | Description |
|-------|-------------|
| `rust/not-planned` | Not planned |
| `rust/researching` | Researching |
| `rust/planning` | Planning implementation |
| `rust/plan-review` | Plan under review |
| `rust/plan-accepted` | Plan accepted |
| `rust/implementing` | Implementation in progress |
| `rust/testing` | Testing |
| `rust/complete` | Complete |

### Documentation Labels (`docs/`)
Track documentation progress.

| Label | Description |
|-------|-------------|
| `docs/none` | No documentation |
| `docs/comments-partial` | Partial code comments |
| `docs/comments-complete` | Complete code comments |
| `docs/mdbook-draft` | MDBook in draft |
| `docs/mdbook-complete` | MDBook complete |
| `docs/llms-txt-ready` | llms.txt ready |

### CI/CD Labels (`cicd/`)
Track pipeline maturity.

| Label | Description |
|-------|-------------|
| `cicd/none` | No CI/CD |
| `cicd/basic` | Basic (lint, format) |
| `cicd/testing` | Testing configured |
| `cicd/security` | Security scanning |
| `cicd/full-pipeline` | Full pipeline |

### Upstream Activity Labels (`upstream/`)
Track source repository health.

| Label | Description |
|-------|-------------|
| `upstream/active` | Actively developed |
| `upstream/maintained` | Maintained but slow |
| `upstream/stale` | Inactive 6+ months |
| `upstream/archived` | Archived/abandoned |

### Effort Labels (`effort/`)
Estimate work size.

| Label | Description |
|-------|-------------|
| `effort/trivial` | < 1 hour |
| `effort/small` | 1-4 hours |
| `effort/medium` | 1-2 days |
| `effort/large` | 3-5 days |
| `effort/epic` | 1+ weeks |

### Priority Labels (`priority/`)
Set urgency level.

| Label | Description |
|-------|-------------|
| `priority/critical` | Immediate attention |
| `priority/high` | High priority |
| `priority/medium` | Normal priority |
| `priority/low` | Nice to have |

### Status Labels (`status/`)
Track issue state.

| Label | Description |
|-------|-------------|
| `status/needs-triage` | Needs assessment |
| `status/needs-review` | Ready for review |
| `status/upstream` | Depends on upstream |
| `status/stale` | No activity 30+ days |
| `status/wontfix` | Will not address |
| `status/duplicate` | Duplicate issue |

### Gap Labels (`gap/`)
Identify ecosystem gaps.

| Label | Description |
|-------|-------------|
| `gap/feature` | Missing feature |
| `gap/integration` | Integration gap |
| `gap/tooling` | Tooling gap |
| `gap/ecosystem` | MCP ecosystem gap |

## Label Sync

Labels are synchronized using the `EndBug/label-sync` GitHub Action:

```yaml
- uses: EndBug/label-sync@v2
  with:
    config-file: .github/labels.yml
    delete-other-labels: false
```

To manually sync labels:

```bash
just sync-labels aRustyDev/mcp
```
