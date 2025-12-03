# Project Fields

The GitHub Project uses custom fields to track development progress beyond what labels provide.

## Field Reference

### Standard Fields

| Field | Type | Purpose |
|-------|------|---------|
| Status | Single Select | Workflow status (Backlog, In Progress, Done) |
| Assignees | People | Who is working on this |
| Labels | Labels | Issue labels |
| Repository | Repository | Source repository |

### Custom Fields

#### Server Identification

| Field | Type | Values |
|-------|------|--------|
| **Server Name** | Text | MCP server identifier (e.g., "mcp/fetch") |
| **Category** | Single Select | search, git, docs, workflow, reasoning, db, llm, notes, docker |
| **Language** | Single Select | python, typescript, go, rust, java, other |

#### Transport Tracking

| Field | Type | Values |
|-------|------|--------|
| **Source Transport** | Single Select | stdio, http-sse, http-streamable, websocket, multiple |
| **Transport Status** | Single Select | stdio-only, http-native, http-wrapped, planned |

#### Development Phases

| Field | Type | Values |
|-------|------|--------|
| **Docker Phase** | Single Select | none, dockerfile-draft, dockerfile-reviewed, image-published, hadolint-compliant |
| **Rust Phase** | Single Select | not-planned, researching, planning, plan-review, plan-accepted, implementing, testing, complete |
| **Docs Phase** | Single Select | none, comments-partial, comments-complete, mdbook-draft, mdbook-complete, llms-txt-ready |
| **CI-CD Phase** | Single Select | none, basic, testing, security, full-pipeline |

#### Metadata

| Field | Type | Purpose |
|-------|------|---------|
| **Priority** | Single Select | critical, high, medium, low |
| **Effort Estimate** | Single Select | trivial, small, medium, large, epic |
| **Upstream Activity** | Single Select | active, maintained, stale, archived |
| **Quality Score** | Number | 0-100 composite score |
| **Last Reviewed** | Date | When the server was last evaluated |

## Fields vs Labels

Both fields and labels can track similar information. Here's when to use each:

| Use Case | Use Labels | Use Fields |
|----------|------------|------------|
| Quick filtering in repo | ✓ | |
| Cross-repo visibility | ✓ | |
| Project board grouping | | ✓ |
| Timeline/roadmap | | ✓ |
| Numeric values | | ✓ |
| Date tracking | | ✓ |
| Complex workflows | | ✓ |

**Best Practice**: Use labels for categorization and quick identification. Use fields for tracking progress through defined phases.

## Field Workflows

### Docker Development

```
none → dockerfile-draft → dockerfile-reviewed → image-published → hadolint-compliant
```

### Rust Rewrite

```
not-planned → researching → planning → plan-review → plan-accepted → implementing → testing → complete
```

### Documentation

```
none → comments-partial → comments-complete → mdbook-draft → mdbook-complete → llms-txt-ready
```

### CI/CD

```
none → basic → testing → security → full-pipeline
```
