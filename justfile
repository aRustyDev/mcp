# =============================================================================
# MCP Server Management Justfile
# =============================================================================
# Automates forking, templating, and onboarding of MCP servers
#
# First-time setup:
#   just init
#
# Usage:
#   just fork-mcp modelcontextprotocol/servers
#   just list-forks
#   just sync-labels
#   just protect-repo
# =============================================================================
# Configuration

github_org := "aRustyDev"
rust_template := "aRustyDev/tmpl-rust"
project_number := env("MCP_PROJECT_NUMBER", "")
project_url := "https://github.com/orgs/" + github_org + "/projects/" + project_number

# Target repository - set via 'just init' or override per-command
target_repo := "aRustyDev/mcp"

# Paths
justfile_dir := justfile_directory()
labels_file := justfile_dir / ".github/labels.yml"
rulesets_dir := justfile_dir / ".github/rulesets"
bundles_dir := justfile_dir / "bundles"

# Default recipe - show help
default:
    @just --list

# =============================================================================
# Initialization
# =============================================================================

# Initialize justfile with target repository (interactive on first run)
init:
    #!/usr/bin/env bash
    set -euo pipefail
    CURRENT_TARGET="{{ target_repo }}"
    if [[ -n "$CURRENT_TARGET" ]]; then
        echo "Already initialized with target_repo: $CURRENT_TARGET"
        echo "To change, manually edit the justfile or run:"
        echo "  just set-target <owner/repo>"
        exit 0
    fi
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ MCP Server Justfile Initialization"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    read -rp "Enter target repository (owner/repo): " REPO
    if [[ -z "$REPO" || ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
        echo "Error: Invalid repository format. Expected: owner/repo"
        exit 1
    fi
    if ! gh repo view "$REPO" &>/dev/null; then
        echo "Warning: Repository '$REPO' not found or not accessible"
        read -rp "Continue anyway? [y/N]: " CONFIRM
        [[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 1
    fi
    sed -i '' "s|^target_repo := \".*\"|target_repo := \"$REPO\"|" "{{ justfile() }}"
    echo "✓ Set target_repo to: $REPO"
    echo "You can now run recipes without specifying the repo parameter."

# Set target repository (non-interactive)
set-target repo:
    #!/usr/bin/env bash
    set -euo pipefail
    sed -i '' "s|^target_repo := \".*\"|target_repo := \"{{ repo }}\"|" "{{ justfile() }}"
    echo "✓ Set target_repo to: {{ repo }}"

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
    echo "║ MCP Server Onboarding: {{ repo }}"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo "→ Step 1: Forking {{ repo }}..."
    if gh repo view "{{ github_org }}/${FORK_NAME}" &>/dev/null; then
        echo "  ⚠ Fork already exists: {{ github_org }}/${FORK_NAME}"
    else
        gh repo fork "{{ repo }}" --org "{{ github_org }}" --fork-name "${FORK_NAME}" --clone=false
        echo "  ✓ Forked to {{ github_org }}/${FORK_NAME}"
    fi
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
    echo "→ Waiting for repositories to initialize..."
    sleep 3
    echo "→ Step 3: Syncing labels..."
    just sync-labels "{{ github_org }}/${FORK_NAME}" || echo "  ⚠ Label sync failed for fork"
    just sync-labels "{{ github_org }}/${RUST_NAME}" || echo "  ⚠ Label sync failed for rust repo"
    echo "→ Step 4: Creating project association issues..."
    just _create-project-issue "{{ github_org }}/${FORK_NAME}" "{{ repo }}" "fork"
    just _create-project-issue "{{ github_org }}/${RUST_NAME}" "{{ repo }}" "rust-rewrite"
    echo "→ Step 5: Creating onboarding issues..."
    just _create-onboarding-issues "{{ github_org }}/${FORK_NAME}" "fork"
    just _create-onboarding-issues "{{ github_org }}/${RUST_NAME}" "rust"
    echo "→ Step 6: Auto-completing setup tasks..."
    just _auto-setup "{{ github_org }}/${FORK_NAME}" "fork"
    just _auto-setup "{{ github_org }}/${RUST_NAME}" "rust"
    echo "→ Step 7: Deploying templates..."
    just _deploy-templates "{{ github_org }}/${FORK_NAME}" "fork"
    just _deploy-templates "{{ github_org }}/${RUST_NAME}" "rust"
    echo "→ Step 8: Creating milestones..."
    just _create-milestones "{{ github_org }}/${FORK_NAME}" "fork"
    just _create-milestones "{{ github_org }}/${RUST_NAME}" "rust"
    echo "→ Step 9: Linking to project..."
    just _link-to-project "{{ github_org }}/${FORK_NAME}"
    just _link-to-project "{{ github_org }}/${RUST_NAME}"
    echo "→ Step 10: Populating initial data..."
    just _populate-initial-data "{{ github_org }}/${FORK_NAME}" "{{ repo }}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ Onboarding Complete!"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    echo "║ Fork:  https://github.com/{{ github_org }}/${FORK_NAME}"
    echo "║ Rust:  https://github.com/{{ github_org }}/${RUST_NAME}"
    echo "║ Project: {{ project_url }}"
    echo "╚════════════════════════════════════════════════════════════════════╝"

# =============================================================================
# Label Management
# =============================================================================

# Sync labels from .github/labels.yml to a repository
sync-labels repo=target_repo: (_require-repo repo) (_require-file labels_file)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Syncing labels to {{ repo }}..."
    if command -v yq &>/dev/null; then
        yq -r '.[] | "\(.name)|\(.color)|\(.description)"' "{{ labels_file }}" | while IFS='|' read -r name color desc; do
            gh label create "$name" --repo "{{ repo }}" --color "$color" --description "$desc" --force 2>/dev/null || true
        done
    else
        grep -E "^- name:" "{{ labels_file }}" | sed 's/- name: "//;s/"$//' | while read -r name; do
            color=$(grep -A1 "name: \"$name\"" "{{ labels_file }}" | grep "color:" | sed 's/.*color: "//;s/"$//')
            desc=$(grep -A2 "name: \"$name\"" "{{ labels_file }}" | grep "description:" | sed 's/.*description: "//;s/"$//')
            gh label create "$name" --repo "{{ repo }}" --color "$color" --description "$desc" --force 2>/dev/null || true
        done
    fi
    echo "✓ Labels synced"

# List all MCP-related forks
list-forks:
    @gh repo list "{{ github_org }}" --fork --json name,description --jq '.[] | "• \(.name): \(.description // "No description")"'

# List all Rust rewrite repos
list-rust-repos:
    @gh repo list "{{ github_org }}" --json name,description --jq '.[] | select(.name | endswith("-rs")) | "• \(.name): \(.description // "No description")"'

# =============================================================================
# Issue Management (Internal)
# =============================================================================

# Create project association issue
[private]
_create-project-issue repo upstream type:
    #!/usr/bin/env bash
    set -euo pipefail
    UPSTREAM="{{ upstream }}"
    if [[ "{{ type }}" == "fork" ]]; then
        TITLE="[Project] Fork of $UPSTREAM"
        LABELS="type/documentation,phase/discovery"
        BODY="## Project Association\n\nThis repository is a fork of the upstream MCP server for tracking and contribution purposes.\n\n### Upstream Repository\n- **Source**: https://github.com/$UPSTREAM\n- **Type**: Fork (for contributions and customization)\n\n### Related Repositories\n- **Rust Rewrite**: Will be linked when created\n\n### Project Tracking\n- [ ] Add to MCP Server Tracking project\n- [ ] Link related issues\n- [ ] Document transport status\n- [ ] Document Docker status"
    else
        TITLE="[Project] Rust rewrite of $UPSTREAM"
        LABELS="type/rewrite,phase/planning"
        BODY="## Project Association\n\nThis repository is a Rust implementation of an MCP server.\n\n### Original Server\n- **Source**: https://github.com/$UPSTREAM\n- **Language**: (to be documented)\n\n### Rewrite Status\n- **Phase**: Planning\n- **Transport Target**: Native Streamable HTTP\n\n### Project Tracking\n- [ ] Add to MCP Server Tracking project\n- [ ] Link to fork repository\n- [ ] Document tool parity status\n- [ ] Create implementation plan"
    fi
    ISSUE_URL=$(gh issue create --repo "{{ repo }}" --title "$TITLE" --body "$(echo -e "$BODY")" --label "$LABELS" 2>/dev/null || echo "")
    if [[ -n "$ISSUE_URL" ]]; then
        echo "  ✓ Created project issue: $ISSUE_URL"
        if [[ -n "{{ project_number }}" ]]; then
            gh project item-add "{{ project_number }}" --owner "{{ github_org }}" --url "$ISSUE_URL" 2>/dev/null || true
        fi
    else
        echo "  ⚠ Could not create project issue (may already exist)"
    fi

# Create onboarding issues
[private]
_create-onboarding-issues repo type:
    #!/usr/bin/env bash
    set -euo pipefail
    declare -a ISSUES
    if [[ "{{ type }}" == "fork" ]]; then
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
        ISSUE_URL=$(gh issue create --repo "{{ repo }}" --title "$title" --body "$(echo -e "$body")" --label "$labels" 2>/dev/null || echo "")
        if [[ -n "$ISSUE_URL" ]]; then
            echo "  ✓ Created: $title"
        fi
    done

# =============================================================================
# Auto-Setup Tasks (Internal)
# =============================================================================

# Auto-complete setup tasks where possible
[private]
_auto-setup repo type:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "  Running auto-setup for {{ repo }}..."
    gh repo edit "{{ repo }}" --enable-issues --enable-wiki=false 2>/dev/null || true
    if [[ "{{ type }}" == "fork" ]]; then
        gh repo edit "{{ repo }}" --add-topic "mcp,mcp-server,model-context-protocol" 2>/dev/null || true
    else
        gh repo edit "{{ repo }}" --add-topic "mcp,mcp-server,model-context-protocol,rust" 2>/dev/null || true
    fi
    echo "  ✓ Auto-setup complete"

# =============================================================================
# Template Management (Internal)
# =============================================================================

# Copy templates to a repository
[private]
_deploy-templates repo type:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{ type }}" == "rust" ]]; then
        echo "  ℹ Rust repos use templates from tmpl-rust"
    fi
    echo "  ✓ Templates deployed"

# =============================================================================
# Milestone Management (Internal)
# =============================================================================

# Create standard milestones for a repository
[private]
_create-milestones repo type:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "  Creating milestones for {{ repo }}..."
    if [[ "{{ type }}" == "rust" ]]; then
        declare -a MILESTONES=(
            "v0.1.0 - Core Implementation|Basic MCP server with essential tools|open"
            "v0.2.0 - HTTP Transport|Native Streamable HTTP transport support|open"
            "v0.3.0 - Docker Ready|Production-ready Docker image|open"
            "v1.0.0 - Parity Release|Feature parity with original server|open"
        )
    else
        declare -a MILESTONES=(
            "Analysis Complete|Upstream analysis and documentation done|open"
            "Transport Implementation|HTTP transport wrapper or native support|open"
            "Docker Image|Container build and publication|open"
        )
    fi
    for milestone_data in "${MILESTONES[@]}"; do
        IFS='|' read -r title desc state <<< "$milestone_data"
        gh api "repos/{{ repo }}/milestones" -X POST -f title="$title" -f description="$desc" -f state="$state" 2>/dev/null || echo "    ⚠ Milestone '$title' may exist"
    done
    echo "  ✓ Milestones created"

# =============================================================================
# Project Linking (Internal)
# =============================================================================

# Link repository to the main MCP project
[private]
_link-to-project repo:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "{{ project_number }}" ]]; then
        echo "  ⚠ MCP_PROJECT_NUMBER not set, skipping project link"
        exit 0
    fi
    echo "  Linking {{ repo }} to project {{ project_number }}..."
    PROJECT_ID=$(gh api graphql -f query='
        query($login: String!, $number: Int!) {
            user(login: $login) {
                projectV2(number: $number) { id }
            }
        }' -f login="{{ github_org }}" -F number="{{ project_number }}" --jq '.data.user.projectV2.id' 2>/dev/null)
    REPO_ID=$(gh api "repos/{{ repo }}" --jq '.node_id' 2>/dev/null)
    if [[ -n "$PROJECT_ID" && -n "$REPO_ID" ]]; then
        gh api graphql -f query='
            mutation($projectId: ID!, $repositoryId: ID!) {
                linkProjectV2ToRepository(input: {projectId: $projectId, repositoryId: $repositoryId}) {
                    repository { nameWithOwner }
                }
            }' -f projectId="$PROJECT_ID" -f repositoryId="$REPO_ID" 2>/dev/null \
            && echo "  ✓ Repository linked to project" \
            || echo "  ⚠ Could not link (may already be linked)"
    else
        echo "  ⚠ Could not get project or repository ID"
    fi

# =============================================================================
# Initial Data Population (Internal)
# =============================================================================

# Populate initial project data for a server
[private]
_populate-initial-data repo upstream:
    #!/usr/bin/env bash
    set -euo pipefail
    UPSTREAM="{{ upstream }}"
    echo "  Populating initial data for {{ repo }}..."
    UPSTREAM_INFO=$(gh api "repos/$UPSTREAM" --jq '{description: .description, language: .language, stars: .stargazers_count, topics: .topics}' 2>/dev/null || echo "{}")
    if [[ -n "$UPSTREAM_INFO" && "$UPSTREAM_INFO" != "{}" ]]; then
        LANG=$(echo "$UPSTREAM_INFO" | jq -r '.language // "Unknown"')
        DESC=$(echo "$UPSTREAM_INFO" | jq -r '.description // "No description"')
        STARS=$(echo "$UPSTREAM_INFO" | jq -r '.stars // 0')
        TOPICS=$(echo "$UPSTREAM_INFO" | jq -r '.topics | join(", ") // "none"')
        BODY="## MCP Server Profile\n\n### Basic Information\n- **Original Repository**: https://github.com/$UPSTREAM\n- **Language**: $LANG\n- **Stars**: $STARS\n- **Topics**: $TOPICS\n- **Description**: $DESC\n\n### Transport Status\n- [ ] Analyze current transport (stdio/http)\n- [ ] Document HTTP wrapper status\n- [ ] Identify streamable HTTP potential\n\n### Docker Status\n- [ ] Check for official Docker image\n- [ ] Check Docker Hub for community images\n- [ ] Document containerization status\n\n### Tools & Capabilities\n- [ ] Document all MCP tools\n- [ ] List resources provided\n- [ ] Note any prompts\n\n### Notes\n_Add analysis notes here_"
        ISSUE_URL=$(gh issue create --repo "{{ repo }}" --title "[Discovery] Server Profile: ${UPSTREAM##*/}" --body "$(echo -e "$BODY")" --label "type/research,phase/discovery,lang/${LANG,,}" 2>/dev/null || echo "")
        if [[ -n "$ISSUE_URL" ]]; then
            echo "  ✓ Created discovery issue: $ISSUE_URL"
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
apply-templates repo=target_repo version="latest": (_require-repo repo)
    #!/usr/bin/env bash
    set -euo pipefail
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ Applying MCP Templates to {{ repo }}"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    cd "$TEMP_DIR"
    if [[ "{{ version }}" == "local" ]]; then
        echo "→ Using local bundles/ directory..."
        BUNDLE_DIR="{{ bundles_dir }}"
    else
        echo "→ Downloading template bundle ({{ version }})..."
        if gh release download {{ if version == "latest" { "" } else { version } }} --repo "{{ github_org }}/mcp" --pattern 'mcp-templates-*.tar.gz' 2>/dev/null; then
            tar -xzf mcp-templates-*.tar.gz
            BUNDLE_DIR=$(find . -maxdepth 1 -type d -name 'mcp-templates-*' | head -1)
        else
            echo "  ⚠ No release found, using local bundles/..."
            BUNDLE_DIR="{{ bundles_dir }}"
        fi
    fi
    if [[ -z "$BUNDLE_DIR" || ! -d "$BUNDLE_DIR" ]]; then
        echo "Error: Could not find bundle directory"
        exit 1
    fi
    cd "$BUNDLE_DIR"
    just setup-remote "{{ repo }}"

# Apply templates from local bundles/ to a remote repository
apply-templates-local repo=target_repo: (_require-repo repo)
    just apply-templates "{{ repo }}" "local"

# Download template bundle to current directory
download-templates version="latest":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Downloading MCP template bundle..."
    if [[ "{{ version }}" == "latest" ]]; then
        gh release download --repo "{{ github_org }}/mcp" --pattern 'mcp-templates-*.tar.gz'
    else
        gh release download "{{ version }}" --repo "{{ github_org }}/mcp" --pattern 'mcp-templates-*.tar.gz'
    fi
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
    VERSION="local-$(date +%Y%m%d-%H%M%S)"
    echo "Building bundle from bundles/..."
    cp -r "{{ bundles_dir }}" "mcp-templates-$VERSION"
    echo "Version: $VERSION" > "mcp-templates-$VERSION/VERSION"
    echo "Built: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "mcp-templates-$VERSION/VERSION"
    echo "Source: local build" >> "mcp-templates-$VERSION/VERSION"
    tar -czvf "mcp-templates-$VERSION.tar.gz" "mcp-templates-$VERSION/"
    rm -rf "mcp-templates-$VERSION"
    echo "✓ Created: mcp-templates-$VERSION.tar.gz"

# =============================================================================
# Utility Recipes
# =============================================================================

# Check prerequisites
check-prereqs:
    #!/usr/bin/env bash
    echo "Checking prerequisites..."
    if ! command -v gh &>/dev/null; then
        echo "✗ GitHub CLI (gh) not installed"
        exit 1
    else
        echo "✓ GitHub CLI installed: $(gh --version | head -1)"
    fi
    if ! gh auth status &>/dev/null; then
        echo "✗ Not authenticated with GitHub CLI"
        echo "  Run: gh auth login"
        exit 1
    else
        echo "✓ GitHub CLI authenticated"
    fi
    if command -v yq &>/dev/null; then
        echo "✓ yq installed (recommended for label sync)"
    else
        echo "⚠ yq not installed (label sync will use fallback parser)"
    fi
    if command -v jq &>/dev/null; then
        echo "✓ jq installed"
    else
        echo "✗ jq not installed (required for many recipes)"
        exit 1
    fi
    if [[ -z "{{ project_number }}" ]]; then
        echo "⚠ MCP_PROJECT_NUMBER not set (issues won't be added to project)"
        echo "  Set with: export MCP_PROJECT_NUMBER=<number>"
    else
        echo "✓ Project number configured: {{ project_number }}"
    fi
    if [[ -z "{{ target_repo }}" ]]; then
        echo "⚠ target_repo not set (run 'just init' to configure)"
    else
        echo "✓ Target repo configured: {{ target_repo }}"
    fi
    echo "All critical prerequisites met!"

# Show current configuration
show-config:
    @echo "GitHub Organization: {{ github_org }}"
    @echo "Rust Template:       {{ rust_template }}"
    @echo "Project Number:      {{ project_number }}"
    @echo "Project URL:         {{ project_url }}"
    @echo "Target Repository:   {{ if target_repo == "" { "(not set - run 'just init')" } else { target_repo } }}"
    @echo "Justfile Directory:  {{ justfile_dir }}"

# Clone a forked MCP server locally
clone-fork name:
    gh repo clone "{{ github_org }}/{{ name }}"

# Clone a Rust rewrite repo locally
clone-rust name:
    gh repo clone "{{ github_org }}/{{ name }}-rs"

# Update fork from upstream
sync-fork repo=target_repo: (_require-repo repo)
    gh repo sync "{{ repo }}" --force

# Open repository in browser
browse repo=target_repo: (_require-repo repo)
    gh repo view "{{ repo }}" --web

# View all open issues across MCP repos
issues:
    @echo "=== Fork Issues ==="
    @gh search issues --owner "{{ github_org }}" --state open --json repository,title,labels --jq '.[] | select(.repository.name | test("-rs$") | not) | "[\(.repository.name)] \(.title)"' 2>/dev/null | head -20 || echo "No issues found"
    @echo "=== Rust Rewrite Issues ==="
    @gh search issues --owner "{{ github_org }}" --state open --json repository,title,labels --jq '.[] | select(.repository.name | endswith("-rs")) | "[\(.repository.name)] \(.title)"' 2>/dev/null | head -20 || echo "No issues found"

# =============================================================================
# Repository Protection
# =============================================================================
# Recipes for protecting GitHub repository branches using rulesets.
#
# Overview:
#   These recipes use GitHub's Repository Rulesets API to protect branches
#   from direct pushes, force pushes, and deletion. They enforce a PR-based
#   workflow for code changes.
#
# Available Recipes:
#   protect-repo [repo]              - Apply all branch protection rulesets
#   apply-ruleset [repo] <file>      - Apply a single ruleset from JSON file
#   unprotect-repo [repo]            - Remove all rulesets from a repository
#   list-rulesets [repo]             - List all rulesets for a repository
#
# Ruleset Files:
#   .github/rulesets/main-branch-protection.json
#   .github/rulesets/integration-branch-protection.json
#
# Branch Protection Strategy:
#   - 'main' branch: Protected from pushes, force pushes, deletion.
#                    Requires PRs (typically from 'integration').
#   - 'integration' branch: Protected from pushes, force pushes, deletion.
#                           Requires PRs for changes.
#
# Usage Examples:
#   just protect-repo
#   just apply-ruleset .github/rulesets/main-branch-protection.json
#   just list-rulesets
#   just unprotect-repo
#
# Prerequisites:
#   - GitHub CLI (gh) authenticated with admin access to the repository
#   - Repository must exist on GitHub
#   - Target branches must already exist
#   - jq installed for JSON processing
# =============================================================================

# Apply a single ruleset to a repository from a JSON file
apply-ruleset repo=target_repo ruleset_file="": (_require-repo repo)
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "{{ ruleset_file }}" ]]; then
        echo "Error: ruleset_file is required"
        echo "Usage: just apply-ruleset [repo] <path/to/ruleset.json>"
        exit 1
    fi
    RULESET_NAME=$(jq -r '.name' "{{ ruleset_file }}")
    EXISTING_ID=$(gh api "repos/{{ repo }}/rulesets" --jq ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>/dev/null || echo "")
    if [[ -n "$EXISTING_ID" ]]; then
        gh api "repos/{{ repo }}/rulesets/$EXISTING_ID" -X PUT --input "{{ ruleset_file }}" --silent \
            && echo "✓ Updated ruleset: $RULESET_NAME" \
            || echo "⚠ Failed to update ruleset: $RULESET_NAME"
    else
        gh api "repos/{{ repo }}/rulesets" -X POST --input "{{ ruleset_file }}" --silent \
            && echo "✓ Created ruleset: $RULESET_NAME" \
            || echo "⚠ Failed to create ruleset: $RULESET_NAME"
    fi

# Apply all branch protection rulesets to a repository
protect-repo repo=target_repo: (_require-repo repo) (_require-dir rulesets_dir)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ Protecting Repository: {{ repo }}"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo "→ Applying branch protection rulesets..."
    just apply-ruleset "{{ repo }}" "{{ rulesets_dir }}/main-branch-protection.json"
    just apply-ruleset "{{ repo }}" "{{ rulesets_dir }}/main-pr-reviews.json"
    just apply-ruleset "{{ repo }}" "{{ rulesets_dir }}/integration-branch-protection.json"
    just apply-ruleset "{{ repo }}" "{{ rulesets_dir }}/integration-pr-reviews.json"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║ Repository Protection Complete!"
    echo "╚════════════════════════════════════════════════════════════════════╝"

# Remove all rulesets from a repository
unprotect-repo repo=target_repo: (_require-repo repo)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "⚠ Removing all rulesets from {{ repo }}..."
    for id in $(gh api "repos/{{ repo }}/rulesets" --jq '.[].id' 2>/dev/null); do
        NAME=$(gh api "repos/{{ repo }}/rulesets/$id" --jq '.name' 2>/dev/null || echo "unknown")
        gh api "repos/{{ repo }}/rulesets/$id" -X DELETE \
            && echo "✓ Removed ruleset: $NAME (ID: $id)" \
            || echo "⚠ Failed to remove ruleset: $NAME (ID: $id)"
    done
    echo "✓ All rulesets removed"

# List all rulesets for a repository
list-rulesets repo=target_repo: (_require-repo repo)
    @gh api "repos/{{ repo }}/rulesets" --jq '.[] | "• \(.name) (ID: \(.id)) - \(.enforcement)"' 2>/dev/null || echo "No rulesets found or insufficient permissions"

# =============================================================================
# Internal Validation Recipes
# =============================================================================

# Require a repo parameter to be set
[private]
_require-repo repo:
    {{ if repo == "" { error("Repository not specified. Run 'just init' or provide repo parameter.") } else { "" } }}

# Require a file to exist
[private]
_require-file file:
    {{ if path_exists(file) == "false" { error("Required file not found: " + file) } else { "" } }}

# Require a directory to exist
[private]
_require-dir dir:
    {{ if path_exists(dir) == "false" { error("Required directory not found: " + dir) } else { "" } }}
