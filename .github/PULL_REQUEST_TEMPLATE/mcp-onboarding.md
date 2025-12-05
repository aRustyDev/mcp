## Summary

<!-- Brief description of the MCP Server repository being onboarded -->

## Repository Information

| Field | Value |
|-------|-------|
| Repository | `owner/repo-name` |
| MCP Server Type | <!-- e.g., filesystem, database, API integration --> |
| Primary Language | <!-- e.g., TypeScript, Python, Rust --> |
| Transport(s) | <!-- stdio, SSE, HTTP --> |

## Onboarding Method

- [ ] Local setup (`just setup /path/to/repo`)
- [ ] Remote setup (`just setup-remote owner/repo`)
- [ ] Manual application

## Bundle Components Applied

### Root Files
- [ ] `SECURITY.md` - Security policy
- [ ] `CONTRIBUTING.md` - Contribution guidelines

### .github/ Configuration
- [ ] `CODEOWNERS` - Code ownership rules
- [ ] `FUNDING.yml` - Sponsorship configuration
- [ ] `labels.yml` - Label definitions (70+)
- [ ] `pull_request_template.md` - PR template
- [ ] `release-drafter.yml` - Release notes config
- [ ] `dependabot.yml` - Dependency updates

### Issue Templates (.github/ISSUE_TEMPLATE/)
- [ ] `mcp-server-discovery.yml` - Document new MCP servers
- [ ] `comparative-analysis.yml` - Compare similar servers
- [ ] `transport-implementation.yml` - Track transport work
- [ ] `rust-rewrite.yml` - Track Rust implementations
- [ ] `gap-identification.yml` - Document ecosystem gaps

### Workflows (.github/workflows/)
- [ ] `label-sync.yml` - Sync labels from labels.yml
- [ ] `stale.yml` - Mark/close stale issues
- [ ] `hadolint.yml` - Lint Dockerfiles
- [ ] `dependency-review.yml` - Check for vulnerabilities
- [ ] `mdbook-build.yml` - Build/deploy documentation

## Related Issues

<!-- Link to related issues: Fixes #123, Relates to #456 -->

## Post-Setup Checklist

- [ ] Updated `CODEOWNERS` with correct maintainer(s)
- [ ] Updated `FUNDING.yml` with correct sponsorship links
- [ ] Triggered label sync workflow (`gh workflow run label-sync.yml`)
- [ ] Repository added to [project:mcp-server-development](https://github.com/users/aRustyDev/projects/22)
- [ ] Verified all workflows are enabled and passing

## Customizations

<!-- List any customizations made to the default bundle templates -->

| File | Customization |
|------|---------------|
| <!-- e.g., CODEOWNERS --> | <!-- e.g., Added team @org/mcp-team --> |

## Verification

- [ ] All selected bundle files are present in the repository
- [ ] Labels synced successfully
- [ ] Workflows enabled and initial runs successful
- [ ] Issue templates appear in issue creation form
- [ ] PR template appears when creating new PRs

## Additional Context

<!-- Any other information reviewers should know about this onboarding -->
