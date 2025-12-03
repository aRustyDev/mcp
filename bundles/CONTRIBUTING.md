# Contributing to MCP Server Development

Thank you for your interest in contributing to the MCP Server ecosystem!

## Getting Started

1. **Fork the repository** you want to contribute to
2. **Clone your fork** locally
3. **Create a branch** for your changes: `git checkout -b feature/your-feature`
4. **Make your changes** following our guidelines
5. **Submit a Pull Request**

## Development Setup

### Prerequisites

- Git
- Docker (for containerized servers)
- Rust toolchain (for Rust implementations)
- Node.js (for JavaScript/TypeScript servers)
- [just](https://github.com/casey/just) command runner

### Quick Start

```bash
# Clone the repository
git clone https://github.com/{{.repo}}.git
cd mcp

# Sync labels (if you have write access)
just sync-labels

# Fork an MCP server for development
just fork-mcp modelcontextprotocol/servers/fetch
```

## Contribution Types

### 1. MCP Server Discovery

Help document new MCP servers by creating discovery issues:

- Use the "MCP Server Discovery" issue template
- Include transport status, tools, and resources

### 2. Comparative Analysis

Compare similar MCP servers:

- Use the "Comparative Analysis" issue template
- Document strengths, weaknesses, and recommendations

### 3. Rust Rewrites

Contribute to Rust implementations:

- Follow the Rust style guide
- Ensure feature parity with original
- Target streamable HTTP transport

### 4. Docker Containers

Improve containerization:

- Follow Dockerfile best practices
- Pass HADOLint checks
- Keep images minimal

### 5. Documentation

Improve project documentation:

- Fix typos and clarify explanations
- Add examples and tutorials
- Update API documentation

## Code Style

### Rust

- Run `cargo fmt` before committing
- Run `cargo clippy` and address warnings
- Write tests for new functionality

### TypeScript/JavaScript

- Use ESLint and Prettier
- Follow existing code patterns

### Docker

- Use multi-stage builds
- Run as non-root user
- Pass HADOLint checks

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:

```
feat(fetch): add streaming response support
fix(docker): resolve permission issue in container
docs(readme): add installation instructions
```

## Pull Request Process

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Ensure CI passes** (lint, test, build)
4. **Request review** from maintainers
5. **Address feedback** promptly

### PR Title Format

Use the same format as commit messages:

```
feat(fetch): implement caching layer
```

## Issue Guidelines

### Before Creating an Issue

- Search existing issues for duplicates
- Check if it's a known limitation

### Issue Templates

Use the appropriate template:

- **MCP Server Discovery**: Document a new server
- **Comparative Analysis**: Compare servers
- **Transport Implementation**: Track transport work
- **Rust Rewrite**: Track Rust implementation
- **Gap Identification**: Document missing functionality

## Labels

We use a hierarchical label system. See [Labels Documentation](docs/src/project-management/labels.md).

Key prefixes:

- `type/` - Issue type (research, implementation, bug)
- `phase/` - Development phase
- `lang/` - Programming language
- `transport/` - Transport method
- `priority/` - Issue priority

## Project Board

Issues are tracked on the [MCP Server Development](https://github.com/users/aRustyDev/projects/22) project.

## Questions?

- Open a [Discussion](https://github.com/{{.repo}}/discussions)
- Check existing documentation
- Review closed issues

## License

By contributing, you agree that your contributions will be licensed under the project's license.
