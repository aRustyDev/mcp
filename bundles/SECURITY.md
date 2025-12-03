# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email security concerns to: [Create a private security advisory](https://github.com/aRustyDev/mcp/security/advisories/new)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution Target**: Within 30 days (complexity dependent)

## Security Considerations for MCP Servers

When working with MCP servers, be aware of:

### Authentication & Authorization

- MCP servers may have access to sensitive resources
- Ensure proper credential management
- Use environment variables for secrets, never hardcode

### Network Security

- HTTP transport should use TLS in production
- Validate all inputs from untrusted sources
- Be cautious with file system access tools

### Container Security

- Run containers with minimal privileges
- Use non-root users in Dockerfiles
- Scan images for vulnerabilities regularly

### Supply Chain

- Pin dependency versions
- Review transitive dependencies
- Use lockfiles (Cargo.lock, package-lock.json)

## Scope

This security policy applies to:

- This repository (aRustyDev/mcp)
- Forked MCP server repositories under aRustyDev
- Rust rewrite repositories (\*-rs)

## Recognition

We appreciate security researchers who help keep this project safe. Contributors who report valid security issues will be acknowledged (with permission) in release notes.
