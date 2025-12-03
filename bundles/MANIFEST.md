# MCP Template Bundle

GitHub configuration templates for MCP server repositories.

## Quick Start

```bash
# Download latest release
gh release download --repo aRustyDev/mcp --pattern 'mcp-templates-*.tar.gz'
tar -xzf mcp-templates-*.tar.gz
cd mcp-templates-*

# Apply to local repo
just setup /path/to/your/repo

# Or apply to remote repo via GitHub API
just setup-remote owner/repo-name
```

## Contents

### Root Files

| File              | Description              |
| ----------------- | ------------------------ |
| `SECURITY.md`     | Security policy template |
| `CONTRIBUTING.md` | Contribution guidelines  |
| `justfile`        | Setup automation recipes |
| `MANIFEST.md`     | This file                |
| `VERSION`         | Bundle version info      |

### .github/

| File                       | Description               |
| -------------------------- | ------------------------- |
| `CODEOWNERS`               | Code ownership rules      |
| `FUNDING.yml`              | Sponsorship configuration |
| `labels.yml`               | 70+ label definitions     |
| `pull_request_template.md` | PR template               |
| `release-drafter.yml`      | Release notes config      |

### .github/ISSUE_TEMPLATE/

| Template                       | Use Case                   |
| ------------------------------ | -------------------------- |
| `mcp-server-discovery.yml`     | Document new MCP servers   |
| `comparative-analysis.yml`     | Compare similar servers    |
| `transport-implementation.yml` | Track transport work       |
| `rust-rewrite.yml`             | Track Rust implementations |
| `gap-identification.yml`       | Document ecosystem gaps    |

### .github/workflows/

| Workflow                | Description                 |
| ----------------------- | --------------------------- |
| `label-sync.yml`        | Sync labels from labels.yml |
| `stale.yml`             | Mark/close stale issues     |
| `hadolint.yml`          | Lint Dockerfiles            |
| `dependency-review.yml` | Check for vulnerabilities   |
| `mdbook-build.yml`      | Build/deploy documentation  |

## Usage Options

### Option 1: Local Setup (Recommended)

```bash
# Extract and setup
tar -xzf mcp-templates-*.tar.gz
cd mcp-templates-*
just setup /path/to/cloned/repo

# Force overwrite existing files
just setup-force /path/to/repo
```

### Option 2: Remote Setup

```bash
# Apply directly to GitHub repo (no clone needed)
just setup-remote owner/repo-name
```

### Option 3: Direct Extraction

```bash
# Extract directly into repo root
tar -xzf mcp-templates-*.tar.gz --strip-components=1 -C /path/to/repo
```

### Option 4: Sync Labels Only

```bash
just sync-labels owner/repo-name
```

## Post-Setup

After applying templates:

1. **Customize CODEOWNERS**

   ```
   # Replace @aRustyDev with your username
   * @your-username
   ```

2. **Update FUNDING.yml**

   ```yaml
   github: your-username
   ```

3. **Trigger label sync**

   ```bash
   gh workflow run label-sync.yml -R owner/repo
   ```

4. **Commit changes**
   ```bash
   git add .
   git commit -m "chore: add MCP templates"
   git push
   ```

## Project

- **Tracking**: https://github.com/users/aRustyDev/projects/22
- **Source**: https://github.com/aRustyDev/mcp
