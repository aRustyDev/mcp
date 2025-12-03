# =============================================================================
# MCP Server Management Justfile
# =============================================================================
# Automates forking, templating, and onboarding of MCP servers
#
# Usage:
#   just fork-mcp modelcontextprotocol/servers
#   just list-forks
#   just sync-labels <repo>
# =============================================================================
# Configuration

github_org := "aRustyDev"
rust_template := "aRustyDev/tmpl-rust"
project_number := env("MCP_PROJECT_NUMBER", "")
project_url := "https://github.com/orgs/" + github_org + "/projects/" + project_number

# Default recipe - show help
default:
    @just --list

# =============================================================================
# Main Workflows
# =============================================================================

# Fork an MCP server and create associated Rust rewrite repo
fork-mcp repo:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    OWNER="${REPO%/*}"
    NAME="${REPO#*/}"
    FORK_NAME="${NAME}"
    RUST_NAME="${NAME}-rs"

    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ MCP Server Onboarding: ${REPO}"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Step 1: Fork the original repository
    echo "→ Step 1: Forking ${REPO}..."
    if gh repo view "{{ github_org }}/${FORK_NAME}" &>/dev/null; then
        echo "  ⚠ Fork already exists: {{ github_org }}/${FORK_NAME}"
    else
        gh repo fork "${REPO}" --org "{{ github_org }}" --fork-name "${FORK_NAME}" --clone=false
        echo "  ✓ Forked to {{ github_org }}/${FORK_NAME}"
    fi

    # Step 2: Create Rust rewrite repo from template
    echo ""
    echo "→ Step 2: Creating Rust rewrite repo from template..."
    if gh repo view "{{ github_org }}/${RUST_NAME}" &>/dev/null; then
        echo "  ⚠ Rust repo already exists: {{ github_org }}/${RUST_NAME}"
    else
        gh repo create "{{ github_org }}/${RUST_NAME}" \
            --template "{{ rust_template }}" \
            --public \
            --description "Rust implementation of ${NAME} MCP server"
        echo "  ✓ Created {{ github_org }}/${RUST_NAME}"
    fi

    # Wait for repos to be ready
    echo ""
    echo "→ Waiting for repositories to initialize..."
    sleep 3

    # Step 3: Sync labels to both repos
    echo ""
    echo "→ Step 3: Syncing labels..."
    just sync-labels "{{ github_org }}/${FORK_NAME}" || echo "  ⚠ Label sync failed for fork"
    just sync-labels "{{ github_org }}/${RUST_NAME}" || echo "  ⚠ Label sync failed for rust repo"

    # Step 4: Create project association issues
    echo ""
    echo "→ Step 4: Creating project association issues..."
    just _create-project-issue "{{ github_org }}/${FORK_NAME}" "${REPO}" "fork"
    just _create-project-issue "{{ github_org }}/${RUST_NAME}" "${REPO}" "rust-rewrite"

    # Step 5: Create onboarding issues
    echo ""
    echo "→ Step 5: Creating onboarding issues..."
    just _create-onboarding-issues "{{ github_org }}/${FORK_NAME}" "fork"
    just _create-onboarding-issues "{{ github_org }}/${RUST_NAME}" "rust"

    # Step 6: Auto-complete tasks where possible
    echo ""
    echo "→ Step 6: Auto-completing setup tasks..."
    just _auto-setup "{{ github_org }}/${FORK_NAME}" "fork"
    just _auto-setup "{{ github_org }}/${RUST_NAME}" "rust"

    # Step 7: Deploy templates
    echo ""
    echo "→ Step 7: Deploying templates..."
    just _deploy-templates "{{ github_org }}/${FORK_NAME}" "fork"
    just _deploy-templates "{{ github_org }}/${RUST_NAME}" "rust"

    # Step 8: Create milestones
    echo ""
    echo "→ Step 8: Creating milestones..."
    just _create-milestones "{{ github_org }}/${FORK_NAME}" "fork"
    just _create-milestones "{{ github_org }}/${RUST_NAME}" "rust"

    # Step 9: Link to project
    echo ""
    echo "→ Step 9: Linking to project..."
    just _link-to-project "{{ github_org }}/${FORK_NAME}"
    just _link-to-project "{{ github_org }}/${RUST_NAME}"

    # Step 10: Populate initial data
    echo ""
    echo "→ Step 10: Populating initial data..."
    just _populate-initial-data "{{ github_org }}/${FORK_NAME}" "${REPO}"

    # Summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ Onboarding Complete!"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    echo "║ Fork:  https://github.com/{{ github_org }}/${FORK_NAME}"
    echo "║ Rust:  https://github.com/{{ github_org }}/${RUST_NAME}"
    echo "║ Project: https://github.com/users/{{ github_org }}/projects/{{ project_number }}"
    echo "╚════════════════════════════════════════════════════════════════════╝"

# =============================================================================
# Label Management
# =============================================================================

# Sync labels from .github/labels.yml to a repository
sync-labels repo:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    LABELS_FILE="$(dirname "$0")/.github/labels.yml"

    if [[ ! -f "$LABELS_FILE" ]]; then
        echo "Error: labels.yml not found at $LABELS_FILE"
        exit 1
    fi

    echo "  Syncing labels to ${REPO}..."

    # Parse YAML and create labels
    # Using yq if available, otherwise basic parsing
    if command -v yq &>/dev/null; then
        yq -r '.[] | "\(.name)|\(.color)|\(.description)"' "$LABELS_FILE" | while IFS='|' read -r name color desc; do
            gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force 2>/dev/null || true
        done
    else
        # Fallback: basic grep/sed parsing
        grep -E "^- name:" "$LABELS_FILE" | sed 's/- name: "//;s/"$//' | while read -r name; do
            color=$(grep -A1 "name: \"$name\"" "$LABELS_FILE" | grep "color:" | sed 's/.*color: "//;s/"$//')
            desc=$(grep -A2 "name: \"$name\"" "$LABELS_FILE" | grep "description:" | sed 's/.*description: "//;s/"$//')
            gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force 2>/dev/null || true
        done
    fi

    echo "  ✓ Labels synced"

# List all MCP-related forks
list-forks:
    @gh repo list "{{ github_org }}" --fork --json name,description --jq '.[] | "• \(.name): \(.description // "No description")"'

# List all Rust rewrite repos
list-rust-repos:
    @gh repo list "{{ github_org }}" --json name,description --jq '.[] | select(.name | endswith("-rs")) | "• \(.name): \(.description // "No description")"'

# =============================================================================
# Issue Management
# =============================================================================

# Create project association issue (internal)
_create-project-issue repo upstream type:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    UPSTREAM="{{ upstream }}"
    TYPE="{{ type }}"

    if [[ "$TYPE" == "fork" ]]; then
        TITLE="[Project] Fork of ${UPSTREAM}"
        LABELS="type/documentation,phase/discovery"
        BODY=$(cat <<'ISSUE_BODY'
    ## Project Association

    This repository is a fork of the upstream MCP server for tracking and contribution purposes.

    ### Upstream Repository
    - **Source**: https://github.com/UPSTREAM_PLACEHOLDER
    - **Type**: Fork (for contributions and customization)

    ### Related Repositories
    - **Rust Rewrite**: Will be linked when created

    ### Project Tracking
    - [ ] Add to MCP Server Tracking project
    - [ ] Link related issues
    - [ ] Document transport status
    - [ ] Document Docker status
    ISSUE_BODY
    )
        BODY="${BODY//UPSTREAM_PLACEHOLDER/$UPSTREAM}"
    else
        TITLE="[Project] Rust rewrite of ${UPSTREAM}"
        LABELS="type/rewrite,phase/planning"
        BODY=$(cat <<'ISSUE_BODY'
    ## Project Association

    This repository is a Rust implementation of an MCP server.

    ### Original Server
    - **Source**: https://github.com/UPSTREAM_PLACEHOLDER
    - **Language**: (to be documented)

    ### Rewrite Status
    - **Phase**: Planning
    - **Transport Target**: Native Streamable HTTP

    ### Project Tracking
    - [ ] Add to MCP Server Tracking project
    - [ ] Link to fork repository
    - [ ] Document tool parity status
    - [ ] Create implementation plan
    ISSUE_BODY
    )
        BODY="${BODY//UPSTREAM_PLACEHOLDER/$UPSTREAM}"
    fi

    # Create the issue
    ISSUE_URL=$(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY" --label "$LABELS" 2>/dev/null || echo "")

    if [[ -n "$ISSUE_URL" ]]; then
        echo "  ✓ Created project issue: $ISSUE_URL"

        # Add to project if configured
        if [[ -n "{{ project_number }}" ]]; then
            ISSUE_NUM="${ISSUE_URL##*/}"
            gh project item-add "{{ project_number }}" --owner "{{ github_org }}" --url "$ISSUE_URL" 2>/dev/null || true
        fi
    else
        echo "  ⚠ Could not create project issue (may already exist)"
    fi

# Create onboarding issues (internal)
_create-onboarding-issues repo type:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    TYPE="{{ type }}"

    # Common onboarding tasks
    declare -a ISSUES

    if [[ "$TYPE" == "fork" ]]; then
        ISSUES=(
            "[Onboard] Configure branch protection|type/ci-cd,priority/high|Configure branch protection rules for main branch\n\n- [ ] Require PR reviews\n- [ ] Require status checks\n- [ ] Prevent force pushes"
            "[Onboard] Set up CI/CD workflows|type/ci-cd,priority/high|Set up GitHub Actions for the fork\n\n- [ ] Add test workflow\n- [ ] Add lint workflow\n- [ ] Add build workflow\n- [ ] Add release workflow (if applicable)"
            "[Onboard] Document transport status|type/documentation,transport/stdio|Analyze and document the current transport implementation\n\n- [ ] Identify current transport (stdio/http/sse)\n- [ ] Document if HTTP wrapper is needed\n- [ ] Create transport implementation issue if needed"
            "[Onboard] Document Docker status|type/docker,priority/medium|Analyze Docker container availability\n\n- [ ] Check for official Docker image\n- [ ] Check for community Docker image\n- [ ] Document Dockerfile if exists\n- [ ] Plan container strategy"
            "[Onboard] Analyze tools and capabilities|type/research,phase/discovery|Document all MCP tools provided by this server\n\n- [ ] List all tools with descriptions\n- [ ] Document parameters for each tool\n- [ ] Identify any gaps or limitations"
        )
    else
        ISSUES=(
            "[Onboard] Replace template placeholders|type/documentation,priority/critical|Update all template placeholders with actual values\n\n- [ ] Update Cargo.toml (name, description, authors)\n- [ ] Update README.md\n- [ ] Update LICENSE if needed\n- [ ] Remove template-specific files"
            "[Onboard] Configure CI/CD workflows|type/ci-cd,priority/high|Customize GitHub Actions for Rust MCP server\n\n- [ ] Update test workflow\n- [ ] Add clippy linting\n- [ ] Configure release workflow\n- [ ] Add cross-compilation if needed"
            "[Onboard] Set up branch protection|type/ci-cd,priority/high|Configure branch protection rules\n\n- [ ] Require PR reviews\n- [ ] Require CI checks to pass\n- [ ] Prevent force pushes to main"
            "[Onboard] Design tool implementations|type/rewrite,phase/planning|Plan the Rust implementation of MCP tools\n\n- [ ] List tools from original server\n- [ ] Design Rust structs/traits\n- [ ] Plan error handling\n- [ ] Design async architecture"
            "[Onboard] Implement transport layer|type/implementation,transport/http-streamed|Implement native Streamable HTTP transport\n\n- [ ] Choose HTTP framework (axum/actix/etc)\n- [ ] Implement MCP protocol\n- [ ] Add health endpoints\n- [ ] Test with MCP clients"
            "[Onboard] Create Dockerfile|type/docker,priority/medium|Create optimized Dockerfile for the Rust server\n\n- [ ] Multi-stage build\n- [ ] Minimal base image\n- [ ] HADOLint compliant\n- [ ] Health check configured"
        )
    fi

    for issue_data in "${ISSUES[@]}"; do
        IFS='|' read -r title labels body <<< "$issue_data"
        ISSUE_URL=$(gh issue create --repo "$REPO" --title "$title" --body "$(echo -e "$body")" --label "$labels" 2>/dev/null || echo "")
        if [[ -n "$ISSUE_URL" ]]; then
            echo "  ✓ Created: $title"
        fi
    done

# =============================================================================
# Auto-Setup Tasks
# =============================================================================

# Auto-complete setup tasks where possible (internal)
_auto-setup repo type:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    TYPE="{{ type }}"

    echo "  Running auto-setup for ${REPO}..."

    # Enable GitHub features
    gh repo edit "$REPO" --enable-issues --enable-wiki=false 2>/dev/null || true

    # Set topics
    if [[ "$TYPE" == "fork" ]]; then
        gh repo edit "$REPO" --add-topic "mcp,mcp-server,model-context-protocol" 2>/dev/null || true
    else
        gh repo edit "$REPO" --add-topic "mcp,mcp-server,model-context-protocol,rust" 2>/dev/null || true
    fi

    # Configure default branch protection (requires admin)
    # Note: This may fail if user doesn't have admin rights
    # gh api repos/{{ github_org }}/${REPO#*/}/branches/main/protection \
    #     -X PUT \
    #     -f required_status_checks='{"strict":true,"contexts":[]}' \
    #     -f enforce_admins=false \
    #     -f required_pull_request_reviews='{"required_approving_review_count":1}' \
    #     2>/dev/null || true

    echo "  ✓ Auto-setup complete"

# =============================================================================
# Template Management
# =============================================================================

# Copy templates to a repository (CODEOWNERS, SECURITY, CONTRIBUTING, FUNDING)
_deploy-templates repo type:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    TYPE="{{ type }}"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

    echo "  Deploying templates to ${REPO}..."

    # Create temp directory for template files
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    if [[ "$TYPE" == "rust" ]]; then
        # For Rust repos, templates should already be included from tmpl-rust
        echo "  ℹ Rust repos use templates from tmpl-rust"
    else
        # For fork repos, push template files
        # CODEOWNERS
        cat > "$TEMP_DIR/CODEOWNERS" << 'CODEOWNERS_CONTENT'
# MCP Server Fork - Code Owners
# TEMPLATE: Replace @aRustyDev with your GitHub username

* @aRustyDev
CODEOWNERS_CONTENT

        # SECURITY.md
        cat > "$TEMP_DIR/SECURITY.md" << 'SECURITY_CONTENT'
# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities via [GitHub's private vulnerability reporting](../../security/advisories/new).

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

For detailed security guidelines, see the [main MCP repository](https://github.com/aRustyDev/mcp/blob/main/SECURITY.md).
SECURITY_CONTENT

        # CONTRIBUTING.md
        cat > "$TEMP_DIR/CONTRIBUTING.md" << 'CONTRIBUTING_CONTENT'
# Contributing

Thank you for your interest in contributing!

## Quick Start

1. Fork and clone the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Guidelines

- Follow existing code style
- Write tests for new functionality
- Update documentation as needed

For detailed contribution guidelines, see the [main MCP repository](https://github.com/aRustyDev/mcp/blob/main/CONTRIBUTING.md).
CONTRIBUTING_CONTENT

        # Push files via GitHub API
        for file in CODEOWNERS SECURITY.md CONTRIBUTING.md; do
            if [[ -f "$TEMP_DIR/$file" ]]; then
                CONTENT=$(base64 < "$TEMP_DIR/$file")
                DEST_PATH=".github/$file"
                [[ "$file" != "CODEOWNERS" ]] && DEST_PATH="$file"

                gh api "repos/$REPO/contents/$DEST_PATH" \
                    -X PUT \
                    -f message="chore: add $file template" \
                    -f content="$CONTENT" \
                    2>/dev/null || echo "    ⚠ Could not create $file (may exist)"
            fi
        done
    fi

    echo "  ✓ Templates deployed"

# =============================================================================
# Milestone Management
# =============================================================================

# Create standard milestones for a repository
_create-milestones repo type:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    TYPE="{{ type }}"

    echo "  Creating milestones for ${REPO}..."

    if [[ "$TYPE" == "rust" ]]; then
        # Rust-specific milestones
        declare -a MILESTONES=(
            "v0.1.0 - Core Implementation|Basic MCP server with essential tools|open"
            "v0.2.0 - HTTP Transport|Native Streamable HTTP transport support|open"
            "v0.3.0 - Docker Ready|Production-ready Docker image|open"
            "v1.0.0 - Parity Release|Feature parity with original server|open"
        )
    else
        # Fork milestones
        declare -a MILESTONES=(
            "Analysis Complete|Upstream analysis and documentation done|open"
            "Transport Implementation|HTTP transport wrapper or native support|open"
            "Docker Image|Container build and publication|open"
        )
    fi

    for milestone_data in "${MILESTONES[@]}"; do
        IFS='|' read -r title desc state <<< "$milestone_data"
        gh api "repos/$REPO/milestones" \
            -X POST \
            -f title="$title" \
            -f description="$desc" \
            -f state="$state" \
            2>/dev/null || echo "    ⚠ Milestone '$title' may exist"
    done

    echo "  ✓ Milestones created"

# =============================================================================
# Project Linking
# =============================================================================

# Link repository to the main MCP project
_link-to-project repo:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"

    if [[ -z "{{ project_number }}" ]]; then
        echo "  ⚠ MCP_PROJECT_NUMBER not set, skipping project link"
        return 0
    fi

    echo "  Linking ${REPO} to project {{ project_number }}..."

    # Get project ID
    PROJECT_ID=$(gh api graphql -f query='
        query($login: String!, $number: Int!) {
            user(login: $login) {
                projectV2(number: $number) {
                    id
                }
            }
        }' -f login="{{ github_org }}" -F number="{{ project_number }}" \
        --jq '.data.user.projectV2.id' 2>/dev/null)

    # Get repository ID
    REPO_ID=$(gh api "repos/$REPO" --jq '.node_id' 2>/dev/null)

    if [[ -n "$PROJECT_ID" && -n "$REPO_ID" ]]; then
        # Link repository to project
        gh api graphql -f query='
            mutation($projectId: ID!, $repositoryId: ID!) {
                linkProjectV2ToRepository(input: {projectId: $projectId, repositoryId: $repositoryId}) {
                    repository { nameWithOwner }
                }
            }' -f projectId="$PROJECT_ID" -f repositoryId="$REPO_ID" \
            2>/dev/null && echo "  ✓ Repository linked to project" || echo "  ⚠ Could not link (may already be linked)"
    else
        echo "  ⚠ Could not get project or repository ID"
    fi

# =============================================================================
# Initial Data Population
# =============================================================================

# Populate initial project data for a server
_populate-initial-data repo upstream:
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    UPSTREAM="{{ upstream }}"

    echo "  Populating initial data for ${REPO}..."

    # Get upstream info
    UPSTREAM_INFO=$(gh api "repos/$UPSTREAM" --jq '{
        description: .description,
        language: .language,
        stars: .stargazers_count,
        topics: .topics
    }' 2>/dev/null || echo "{}")

    if [[ -n "$UPSTREAM_INFO" && "$UPSTREAM_INFO" != "{}" ]]; then
        # Create discovery issue with populated data
        LANG=$(echo "$UPSTREAM_INFO" | jq -r '.language // "Unknown"')
        DESC=$(echo "$UPSTREAM_INFO" | jq -r '.description // "No description"')
        STARS=$(echo "$UPSTREAM_INFO" | jq -r '.stars // 0')
        TOPICS=$(echo "$UPSTREAM_INFO" | jq -r '.topics | join(", ") // "none"')

        BODY=$(cat <<EOF
## MCP Server Profile

### Basic Information
- **Original Repository**: https://github.com/$UPSTREAM
- **Language**: $LANG
- **Stars**: $STARS
- **Topics**: $TOPICS
- **Description**: $DESC

### Transport Status
- [ ] Analyze current transport (stdio/http)
- [ ] Document HTTP wrapper status
- [ ] Identify streamable HTTP potential

### Docker Status
- [ ] Check for official Docker image
- [ ] Check Docker Hub for community images
- [ ] Document containerization status

### Tools & Capabilities
- [ ] Document all MCP tools
- [ ] List resources provided
- [ ] Note any prompts

### Notes
_Add analysis notes here_
EOF
        )

        ISSUE_URL=$(gh issue create --repo "$REPO" \
            --title "[Discovery] Server Profile: ${UPSTREAM##*/}" \
            --body "$BODY" \
            --label "type/research,phase/discovery,lang/${LANG,,}" \
            2>/dev/null || echo "")

        if [[ -n "$ISSUE_URL" ]]; then
            echo "  ✓ Created discovery issue: $ISSUE_URL"

            # Add to project if configured
            if [[ -n "{{ project_number }}" ]]; then
                gh project item-add "{{ project_number }}" --owner "{{ github_org }}" --url "$ISSUE_URL" 2>/dev/null || true
            fi
        fi
    fi

    echo "  ✓ Initial data populated"

# =============================================================================
# Template Bundle Management
# =============================================================================

# Apply templates to a remote repository (downloads release or uses local bundles/)
apply-templates repo version="latest":
    #!/usr/bin/env bash
    set -euo pipefail

    REPO="{{ repo }}"
    VERSION="{{ version }}"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ Applying MCP Templates to ${REPO}"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Try to download release, fallback to local bundles/
    cd "$TEMP_DIR"

    if [[ "$VERSION" == "local" ]]; then
        echo "→ Using local bundles/ directory..."
        BUNDLE_DIR="$SCRIPT_DIR/bundles"
    else
        echo "→ Downloading template bundle (${VERSION})..."
        if gh release download ${VERSION:+$VERSION} --repo "{{ github_org }}/mcp" --pattern 'mcp-templates-*.tar.gz' 2>/dev/null; then
            tar -xzf mcp-templates-*.tar.gz
            BUNDLE_DIR=$(find . -maxdepth 1 -type d -name 'mcp-templates-*' | head -1)
        else
            echo "  ⚠ No release found, using local bundles/..."
            BUNDLE_DIR="$SCRIPT_DIR/bundles"
        fi
    fi

    if [[ -z "$BUNDLE_DIR" || ! -d "$BUNDLE_DIR" ]]; then
        echo "Error: Could not find bundle directory"
        exit 1
    fi

    # Use the bundles/justfile to apply
    cd "$BUNDLE_DIR"
    just setup-remote "$REPO"

# Apply templates from local bundles/ to a remote repository
apply-templates-local repo:
    just apply-templates "{{ repo }}" "local"

# Download template bundle to current directory
download-templates version="latest":
    #!/usr/bin/env bash
    set -euo pipefail

    VERSION="{{ version }}"

    echo "Downloading MCP template bundle..."

    if [[ "$VERSION" == "latest" ]]; then
        gh release download --repo "{{ github_org }}/mcp" --pattern 'mcp-templates-*.tar.gz'
    else
        gh release download "$VERSION" --repo "{{ github_org }}/mcp" --pattern 'mcp-templates-*.tar.gz'
    fi

    echo ""
    echo "✓ Downloaded. To apply:"
    echo "  tar -xzf mcp-templates-*.tar.gz"
    echo "  cd mcp-templates-*"
    echo "  just setup /path/to/repo      # local repo"
    echo "  just setup-remote owner/repo  # remote repo"

# List available template bundle versions
list-bundle-versions:
    @gh release list --repo "{{ github_org }}/mcp" --limit 10

# Build a local bundle tarball (for testing)
build-bundle:
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    VERSION="local-$(date +%Y%m%d-%H%M%S)"

    echo "Building bundle from bundles/..."

    # Create versioned copy
    cp -r "$SCRIPT_DIR/bundles" "mcp-templates-$VERSION"

    # Add VERSION file
    cat > "mcp-templates-$VERSION/VERSION" << EOF
    Version: $VERSION
    Built: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
    Source: local build
    EOF

    # Create tarball
    tar -czvf "mcp-templates-$VERSION.tar.gz" "mcp-templates-$VERSION/"
    rm -rf "mcp-templates-$VERSION"

    echo ""
    echo "✓ Created: mcp-templates-$VERSION.tar.gz"

# =============================================================================
# Utility Recipes
# =============================================================================

# Check prerequisites
check-prereqs:
    #!/usr/bin/env bash
    echo "Checking prerequisites..."

    # Check gh CLI
    if ! command -v gh &>/dev/null; then
        echo "✗ GitHub CLI (gh) not installed"
        exit 1
    else
        echo "✓ GitHub CLI installed: $(gh --version | head -1)"
    fi

    # Check gh auth
    if ! gh auth status &>/dev/null; then
        echo "✗ Not authenticated with GitHub CLI"
        echo "  Run: gh auth login"
        exit 1
    else
        echo "✓ GitHub CLI authenticated"
    fi

    # Check yq (optional)
    if command -v yq &>/dev/null; then
        echo "✓ yq installed (recommended for label sync)"
    else
        echo "⚠ yq not installed (label sync will use fallback parser)"
    fi

    # Check project number
    if [[ -z "{{ project_number }}" ]]; then
        echo "⚠ MCP_PROJECT_NUMBER not set (issues won't be added to project)"
        echo "  Set with: export MCP_PROJECT_NUMBER=<number>"
    else
        echo "✓ Project number configured: {{ project_number }}"
    fi

    echo ""
    echo "All critical prerequisites met!"

# Show current configuration
show-config:
    @echo "GitHub Organization: {{ github_org }}"
    @echo "Rust Template:       {{ rust_template }}"
    @echo "Project Number:      {{ project_number }}"
    @echo "Project URL:         {{ project_url }}"

# Clone a forked MCP server locally
clone-fork name:
    gh repo clone "{{ github_org }}/{{ name }}"

# Clone a Rust rewrite repo locally
clone-rust name:
    gh repo clone "{{ github_org }}/{{ name }}-rs"

# Update fork from upstream
sync-fork repo:
    gh repo sync "{{ repo }}" --force

# Open repository in browser
browse repo:
    gh repo view "{{ repo }}" --web

# View all open issues across MCP repos
issues:
    @echo "=== Fork Issues ==="
    @gh search issues --owner "{{ github_org }}" --state open --json repository,title,labels --jq '.[] | select(.repository.name | test("-rs$") | not) | "[\(.repository.name)] \(.title)"' 2>/dev/null | head -20 || echo "No issues found"
    @echo ""
    @echo "=== Rust Rewrite Issues ==="
    @gh search issues --owner "{{ github_org }}" --state open --json repository,title,labels --jq '.[] | select(.repository.name | endswith("-rs")) | "[\(.repository.name)] \(.title)"' 2>/dev/null | head -20 || echo "No issues found"
