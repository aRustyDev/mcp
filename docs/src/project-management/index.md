# Project Management

This section documents the issue tracking, labeling, and project management strategy for MCP server development.

## Overview

All MCP-related development is tracked through:
- **GitHub Project**: [MCP Server Development](https://github.com/users/aRustyDev/projects/22)
- **Issue Labels**: Hierarchical labeling system for categorization
- **Issue Templates**: Standardized templates for common issue types
- **Project Fields**: Custom fields for tracking development phases

## Key Concepts

### Repositories

| Repository | Purpose |
|------------|---------|
| [aRustyDev/mcp](https://github.com/aRustyDev/mcp) | Main tracking repo, Docker configs, infrastructure |
| [aRustyDev/tmpl-rust](https://github.com/aRustyDev/tmpl-rust) | Template for new Rust MCP server implementations |
| Server forks | Forked MCP servers for contributions |
| `*-rs` repos | Rust reimplementations of MCP servers |

### Issue Types

1. **Discovery** - Identifying and cataloging new MCP servers
2. **Analysis** - Comparative analysis of similar servers
3. **Transport** - HTTP/SSE transport implementation work
4. **Docker** - Container development and optimization
5. **Rust Rewrite** - Planning and implementing Rust versions
6. **Gap** - Identifying missing features in the ecosystem
