---
id: e587174a-70dc-412e-8c17-07637ada8ca4
title: "Phase 28: Automation - Issues"
status: pending
depends_on:
  - 10252d3a-1d19-4bf7-ad39-e4288ac6a3e2  # phase-27
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
gate:
  required: true
  justfile_changes: minor
  review_focus:
    - Issue automation integration with justfile init
    - Label sync workflow triggering
    - Dependabot auto-merge behavior
---

# Phase 28: Automation - Issues

> **⚠️ GATE REQUIRED**: Before starting this phase, complete the [Justfile Review Gate](../bundle-contents.md#phase-gate-justfile-review) conversation with user.

## 0. Phase Gate: Justfile Review

### Pre-Phase Checklist

- [ ] Reviewed current justfile state (Phases 01-27 accumulated)
- [ ] Compared expected vs current workflow
- [ ] Discussed Phase 28 justfile changes
- [ ] User approved planned changes
- [ ] Gate conversation documented

### Phase 28 Justfile Impact

Minor changes - primarily workflow files, but some justfile recipes may be added:

| Recipe | Status | Purpose |
|--------|--------|---------|
| `sync-labels` | **New** | Trigger label sync workflow |
| `stale-check` | **New** | Run stale issue check manually |

### Integration Points

- `_create-issues` recipe should align with auto-labeling rules
- Issue templates should match triage workflow expectations
- Dependabot config integrates with auto-merge workflow

---

## 1. Current State Assessment

- [ ] Check for existing issue automation
- [ ] Review labeler configuration
- [ ] Identify stale issue handling
- [ ] Check for triage workflows

### Existing Assets

- Labels defined (Phase 01)
- Issue templates (Phase 01)

### Gaps Identified

- [ ] label-sync.yml (sync labels from config)
- [ ] stale-issues.yml (mark stale issues)
- [ ] stale-prs.yml (mark stale PRs)
- [ ] triage.yml (auto-label new issues)
- [ ] welcome.yml (welcome contributors)
- [ ] auto-assign.yml (assign reviewers)
- [ ] auto-update-branch.yml (rebase PRs when main changes)
- [ ] dependabot-auto-merge.yml (auto-merge safe updates)
- [ ] deps-major-validation.yml (comprehensive testing for major updates)

---

## 2. Contextual Goal

Implement comprehensive issue and PR automation to reduce maintainer burden. Auto-label issues based on content, mark stale items for follow-up, welcome new contributors, and automatically assign reviewers based on code ownership.

### Success Criteria

- [ ] Labels sync from configuration
- [ ] Stale issues/PRs marked automatically
- [ ] New issues auto-labeled
- [ ] First-time contributors welcomed
- [ ] Reviewers assigned automatically
- [ ] Open PRs auto-rebased when main changes
- [ ] Major dependency updates trigger comprehensive validation
- [ ] Dependabot patch updates auto-merged

### Out of Scope

- Project board automation (GitHub native)
- Complex workflow routing
- Merge queue (requires repo settings, see Phase 00)

---

## 3. Implementation

### 3.1 label-sync.yml

```yaml
name: Sync Labels

on:
  push:
    branches: [main]
    paths:
      - '.github/labels.yml'
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync labels
        uses: EndBug/label-sync@v2
        with:
          config-file: .github/labels.yml
          delete-other-labels: true
```

### 3.2 stale-issues.yml

```yaml
name: Stale Issues

on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

jobs:
  stale:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      pull-requests: write

    steps:
      - uses: actions/stale@v9
        with:
          stale-issue-message: >
            This issue has been automatically marked as stale due to inactivity.
            It will be closed in 7 days if no further activity occurs.
          stale-pr-message: >
            This PR has been automatically marked as stale due to inactivity.
            It will be closed in 14 days if no further activity occurs.
          stale-issue-label: 'stale'
          stale-pr-label: 'stale'
          days-before-stale: 30
          days-before-close: 7
          days-before-pr-close: 14
          exempt-issue-labels: 'pinned,security'
          exempt-pr-labels: 'pinned'
```

### 3.3 triage.yml

```yaml
name: Issue Triage

on:
  issues:
    types: [opened]

jobs:
  triage:
    runs-on: ubuntu-latest
    permissions:
      issues: write

    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const issue = context.payload.issue;
            const labels = [];

            // Auto-label based on title/body keywords
            if (issue.title.toLowerCase().includes('bug') ||
                issue.body?.toLowerCase().includes('steps to reproduce')) {
              labels.push('type:bug');
            }

            if (issue.title.toLowerCase().includes('feature') ||
                issue.body?.toLowerCase().includes('feature request')) {
              labels.push('type:feature');
            }

            if (labels.length > 0) {
              await github.rest.issues.addLabels({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                labels: labels
              });
            }

            // Add triage label
            await github.rest.issues.addLabels({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: issue.number,
              labels: ['status:triage']
            });
```

### 3.4 welcome.yml

```yaml
name: Welcome

on:
  issues:
    types: [opened]
  pull_request_target:
    types: [opened]

jobs:
  welcome:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/first-interaction@v1
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          issue-message: |
            Thanks for opening your first issue! We appreciate your contribution.
            A maintainer will review this shortly.
          pr-message: |
            Thanks for your first contribution! We'll review this PR soon.
            Please ensure all CI checks pass.
```

### 3.5 auto-assign.yml

```yaml
name: Auto Assign

on:
  pull_request:
    types: [opened, ready_for_review]

jobs:
  assign:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write

    steps:
      - uses: kentaro-m/auto-assign-action@v1
        with:
          configuration-path: '.github/auto-assign.yml'
```

### 3.6 auto-update-branch.yml

Auto-rebase open PRs when the base branch (main) is updated. This is particularly useful when dependency updates merge before feature PRs.

```yaml
name: Auto Update Branch

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      pr_number:
        description: 'Specific PR number to update (optional)'
        required: false

permissions:
  contents: write
  pull-requests: write

jobs:
  update-branches:
    runs-on: ubuntu-latest
    steps:
      - name: Update PR branches
        uses: actions/github-script@v7
        with:
          script: |
            const prNumber = context.payload.inputs?.pr_number;

            // Get open PRs
            let prs;
            if (prNumber) {
              // Update specific PR
              const { data: pr } = await github.rest.pulls.get({
                owner: context.repo.owner,
                repo: context.repo.repo,
                pull_number: parseInt(prNumber)
              });
              prs = [pr];
            } else {
              // Get all open PRs targeting main
              const { data: allPrs } = await github.rest.pulls.list({
                owner: context.repo.owner,
                repo: context.repo.repo,
                state: 'open',
                base: 'main',
                sort: 'updated',
                direction: 'desc'
              });
              prs = allPrs;
            }

            for (const pr of prs) {
              // Skip draft PRs
              if (pr.draft) {
                console.log(`Skipping draft PR #${pr.number}`);
                continue;
              }

              // Skip PRs with conflicts (can't auto-update)
              if (pr.mergeable === false) {
                console.log(`Skipping PR #${pr.number} - has conflicts`);
                continue;
              }

              // Skip PRs that are already up to date
              if (pr.mergeable_state === 'clean' || pr.mergeable_state === 'unstable') {
                console.log(`PR #${pr.number} is already up to date`);
                continue;
              }

              try {
                // Update the branch
                await github.rest.pulls.updateBranch({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  pull_number: pr.number,
                  expected_head_sha: pr.head.sha
                });
                console.log(`Updated PR #${pr.number}: ${pr.title}`);

                // Add comment
                await github.rest.issues.createComment({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  issue_number: pr.number,
                  body: '🔄 Branch automatically updated with latest changes from `main`.'
                });
              } catch (error) {
                console.log(`Failed to update PR #${pr.number}: ${error.message}`);
              }
            }
```

**Alternative: Label-Based Trigger**

For more control, only update PRs with a specific label:

```yaml
name: Auto Update Branch (Label-Based)

on:
  push:
    branches: [main]

jobs:
  update-labeled-prs:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - name: Update PRs with auto-update label
        uses: actions/github-script@v7
        with:
          script: |
            const { data: prs } = await github.rest.pulls.list({
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'open',
              base: 'main'
            });

            for (const pr of prs) {
              // Only update PRs with 'auto-update' label
              const hasLabel = pr.labels.some(l => l.name === 'auto-update');
              if (!hasLabel) continue;

              try {
                await github.rest.pulls.updateBranch({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  pull_number: pr.number
                });
                console.log(`Updated PR #${pr.number}`);
              } catch (error) {
                console.log(`Failed: ${error.message}`);
              }
            }
```

### 3.7 dependabot-auto-merge.yml

Auto-merge Dependabot PRs for patch/minor updates after CI passes:

```yaml
name: Dependabot Auto-Merge

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'

    steps:
      - name: Fetch Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-merge patch updates
        if: steps.metadata.outputs.update-type == 'version-update:semver-patch'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-merge minor updates (dev dependencies only)
        if: |
          steps.metadata.outputs.update-type == 'version-update:semver-minor' &&
          steps.metadata.outputs.dependency-type == 'direct:development'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Label major updates for review
        if: steps.metadata.outputs.update-type == 'version-update:semver-major'
        run: gh pr edit "$PR_URL" --add-label "needs:review,breaking-change"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3.8 deps-major-validation.yml

Comprehensive testing for major dependency updates. Runs extended test suites to identify breaking changes before manual review. **Does NOT auto-merge.**

```yaml
name: Major Dependency Validation

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write
  checks: write

jobs:
  # Gate: Only run for Dependabot major updates
  check-trigger:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    outputs:
      is-major: ${{ steps.metadata.outputs.update-type == 'version-update:semver-major' }}
      dependency: ${{ steps.metadata.outputs.dependency-names }}
      ecosystem: ${{ steps.metadata.outputs.package-ecosystem }}
    steps:
      - name: Fetch Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

  # Full test matrix for major updates
  validation:
    needs: check-trigger
    if: needs.check-trigger.outputs.is-major == 'true'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        test-type: [unit, integration, e2e, property]
    steps:
      - uses: actions/checkout@v4

      - name: Setup test environment
        uses: ./.github/actions/setup-test-env
        with:
          test-type: ${{ matrix.test-type }}

      - name: Run ${{ matrix.test-type }} tests
        id: tests
        run: |
          # Dispatch to appropriate test runner
          case "${{ matrix.test-type }}" in
            unit)        just test-unit ;;
            integration) just test-integration ;;
            e2e)         just test-e2e ;;
            property)    just test-property ;;
          esac

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.test-type }}
          path: target/test-results/

  # Breaking change detection
  breaking-changes:
    needs: check-trigger
    if: needs.check-trigger.outputs.is-major == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Detect breaking changes (Rust)
        if: needs.check-trigger.outputs.ecosystem == 'cargo'
        run: |
          cargo install cargo-semver-checks
          cargo semver-checks check-release 2>&1 | tee breaking-changes.txt || true

      - name: Detect breaking changes (Node)
        if: needs.check-trigger.outputs.ecosystem == 'npm'
        run: |
          npx publint 2>&1 | tee breaking-changes.txt || true

      - name: Upload breaking change report
        uses: actions/upload-artifact@v4
        with:
          name: breaking-changes
          path: breaking-changes.txt

  # Benchmark comparison
  performance:
    needs: check-trigger
    if: needs.check-trigger.outputs.is-major == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/checkout@v4
        with:
          ref: main
          path: baseline

      - name: Run baseline benchmarks
        run: |
          cd baseline
          just bench --save-baseline main

      - name: Run PR benchmarks
        run: |
          just bench --baseline main --save-baseline pr

      - name: Generate comparison
        id: bench
        run: |
          just bench-compare main pr > bench-comparison.md
          echo "has-regression=$(grep -q 'REGRESSION' bench-comparison.md && echo 'true' || echo 'false')" >> $GITHUB_OUTPUT

      - name: Upload benchmark comparison
        uses: actions/upload-artifact@v4
        with:
          name: benchmark-comparison
          path: bench-comparison.md

  # Summary report
  report:
    needs: [check-trigger, validation, breaking-changes, performance]
    if: always() && needs.check-trigger.outputs.is-major == 'true'
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/download-artifact@v4
        with:
          merge-multiple: true

      - name: Generate validation report
        id: report
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');

            const dependency = '${{ needs.check-trigger.outputs.dependency }}';
            const validationResult = '${{ needs.validation.result }}';
            const breakingResult = '${{ needs.breaking-changes.result }}';
            const perfResult = '${{ needs.performance.result }}';

            let breakingChanges = '';
            try {
              breakingChanges = fs.readFileSync('breaking-changes.txt', 'utf8');
            } catch (e) {
              breakingChanges = 'No breaking changes detected or analysis not available.';
            }

            let benchComparison = '';
            try {
              benchComparison = fs.readFileSync('bench-comparison.md', 'utf8');
            } catch (e) {
              benchComparison = 'Benchmark comparison not available.';
            }

            const allPassed = validationResult === 'success' &&
                              breakingResult === 'success' &&
                              perfResult === 'success';

            const statusEmoji = allPassed ? '✅' : '⚠️';

            const body = `## ${statusEmoji} Major Dependency Update Validation

**Dependency**: \`${dependency}\`
**Update Type**: Major (semver-major)

### Test Results

| Test Suite | Status |
|------------|--------|
| Unit Tests | ${validationResult === 'success' ? '✅ Passed' : '❌ Failed'} |
| Integration Tests | ${validationResult === 'success' ? '✅ Passed' : '❌ Failed'} |
| E2E Tests | ${validationResult === 'success' ? '✅ Passed' : '❌ Failed'} |
| Property Tests | ${validationResult === 'success' ? '✅ Passed' : '❌ Failed'} |

### Breaking Changes Detection

\`\`\`
${breakingChanges.substring(0, 2000)}
\`\`\`

### Performance Comparison

${benchComparison.substring(0, 2000)}

---

⚠️ **This is a MAJOR version update. Manual review required.**

**Checklist for reviewer:**
- [ ] Breaking changes have been evaluated
- [ ] Migration path documented (if needed)
- [ ] Performance impact acceptable
- [ ] All tests passing or failures explained
- [ ] Downstream consumers notified (if public API affected)
`;

            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: body
            });

      - name: Add validation label
        run: |
          if [ "${{ needs.validation.result }}" == "success" ]; then
            gh pr edit "${{ github.event.pull_request.number }}" --add-label "validated"
          else
            gh pr edit "${{ github.event.pull_request.number }}" --add-label "validation-failed"
          fi
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Key differences from auto-merge workflow:**
- Runs comprehensive test matrix (unit, integration, e2e, property)
- Detects API breaking changes (cargo-semver-checks, publint)
- Compares benchmarks against baseline
- Posts detailed validation report
- **Never auto-merges** - requires human approval
- Adds `validated` or `validation-failed` label

### 3.9 Merge Queue Configuration (Manual)

For repositories with high PR volume, enable GitHub's native Merge Queue:

**Settings → General → Pull Requests:**
- [ ] Enable "Require branches to be up to date before merging"
- [ ] Enable "Require merge queue"

**Merge Queue Benefits:**
- Automatic rebasing before merge
- Batched CI runs (efficiency)
- Guaranteed main branch stability
- No race conditions between PRs

> **Note**: Merge Queue requires repository admin access. Add to Phase 00 manual setup checklist.

---

## 4. Review & Validation

- [ ] Labels sync correctly
- [ ] Stale workflow runs on schedule
- [ ] Auto-labeling accurate
- [ ] Welcome messages appropriate
- [ ] Auto-update rebases PRs when main changes
- [ ] Dependabot patch updates auto-merge after CI
- [ ] Dependabot major updates labeled for review
- [ ] Major updates trigger comprehensive validation
- [ ] Validation report posted to PR with checklist
- [ ] Merge Queue configured (if high PR volume)
- [ ] Implementation tracking checklist updated
