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

    # Summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ Onboarding Complete!"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    echo "║ Fork:  https://github.com/{{ github_org }}/${FORK_NAME}"
    echo "║ Rust:  https://github.com/{{ github_org }}/${RUST_NAME}"
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
