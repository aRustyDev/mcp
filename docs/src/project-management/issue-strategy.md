# Issue Management Strategy

This document describes the strategy for creating, managing, and closing issues across MCP-related repositories.

## Issue Types

### Discovery Issues

Created when identifying a new MCP server.

**Template**: `mcp-server-discovery.yml`

**Content**:
- Server name and repository URL
- Category and transport status
- Tools provided
- Docker status
- Initial notes

**Labels**: `type/research`, `phase/discovery`, `status/needs-triage`

**Lifecycle**:
1. Create when server is identified
2. Triage to assess priority and transport needs
3. Create follow-up issues for transport, Docker, etc.
4. Close when fully documented

### Comparative Analysis Issues

Created when comparing similar MCP servers.

**Template**: `comparative-analysis.yml`

**Content**:
- Servers being compared (with links)
- Comparison criteria
- Findings
- Recommendation

**Labels**: `type/analysis`, `phase/planning`

**Lifecycle**:
1. Create before choosing between similar servers
2. Document findings as analysis progresses
3. Add recommendation
4. Close and link to chosen implementation

### Transport Implementation Issues

Created when implementing HTTP transport for a server.

**Template**: `transport-implementation.yml`

**Content**:
- MCP server name
- Current and target transport
- Implementation approach (checklist)
- Blockers/concerns

**Labels**: `type/implementation`, `type/docker`, `transport/*`

**Lifecycle**:
1. Create after deciding to add HTTP support
2. Check off implementation steps
3. Link to PRs
4. Close when transport is working

### Rust Rewrite Issues

Created when planning a Rust implementation.

**Template**: `rust-rewrite.yml`

**Content**:
- Original server reference
- Current phase
- Rationale
- Scope (tools, transport)
- Design notes

**Labels**: `type/rewrite`, `rust/*`, `lang/rust`

**Lifecycle**:
1. Create during research phase
2. Update phase as work progresses
3. Create sub-issues for specific tasks
4. Close when rewrite is complete

### Gap Identification Issues

Created when identifying ecosystem gaps.

**Template**: `gap-identification.yml`

**Content**:
- Gap title and type
- Description
- Existing alternatives
- Proposed solution

**Labels**: `type/research`, `gap/*`

**Lifecycle**:
1. Create when gap is identified
2. Research alternatives
3. Propose solution
4. Close when addressed or marked wontfix

## Cross-Repository Strategy

### Main Tracking Repository (`aRustyDev/mcp`)

- All discovery issues
- Comparative analysis issues
- Infrastructure issues
- Gap identification issues
- Project-wide documentation

### Forked Repositories

- Contribution-related issues
- Bug fixes to upstream
- Feature requests to upstream
- Sync/maintenance issues

### Rust Rewrite Repositories (`*-rs`)

- Rust implementation issues
- Tool parity tracking
- Performance issues
- Release management

## Issue Linking

### Parent-Child Relationships

Use sub-issues for breaking down large work:

```
[Discovery] mcp/fetch
  └── [Transport] Add HTTP wrapper
  └── [Docker] Optimize container
  └── [Rust] Plan rewrite
```

### Cross-Repository Links

Reference related issues across repos:

```markdown
Related to aRustyDev/mcp#123
Implements feature from aRustyDev/fetch-rs#45
```

## Issue Lifecycle

### States

1. **Open** - Active work needed
2. **In Progress** - Currently being worked on
3. **Blocked** - Waiting on dependency
4. **In Review** - Ready for review
5. **Closed** - Complete or won't fix

### Closure Criteria

Close issues when:
- ✅ Work is complete and merged
- ✅ Analysis is documented and decision made
- ✅ Marked as duplicate (link to original)
- ✅ Marked as wontfix (document reason)

Don't close issues when:
- ❌ Work is partially complete
- ❌ Waiting for review
- ❌ Dependent work is pending

## Automation

### On Issue Open

- Add `status/needs-triage` if no type label
- Add to project board

### On Issue Close

- Update project field to "Done"
- Verify linked PRs are merged

### Stale Issues

- Mark `status/stale` after 30 days inactive
- Close after 14 more days without activity
- Exempt: `priority/critical`, `priority/high`, `phase/blocked`
