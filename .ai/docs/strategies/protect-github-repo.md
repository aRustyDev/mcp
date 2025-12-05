---
id: 2769C84B-479C-4EE3-9970-0AF4A973C82E
title: "GitHub Repository Protection Strategy"
status: "✅ Active"
date: 2025-01-13
author: aRustyDev
type: strategy
related:
  - ../adr/frontmatter-standard.md
---

# GitHub Repository Protection Strategy

## Overview

This document defines the strategy for protecting GitHub repositories using branch rulesets. The goal is to enforce a consistent, secure workflow across all repositories that prevents accidental or unauthorized changes to critical branches.

---

## Branch Model

### Protected Branches

| Branch        | Purpose                                  | Protection Level |
| ------------- | ---------------------------------------- | ---------------- |
| `main`        | Production-ready code, release source    | Maximum          |
| `integration` | Pre-release staging, feature integration | High             |

### Workflow

```
feature/* ──────┐
bugfix/*  ──────┼──► PR ──► integration ──► PR ──► main
hotfix/*  ──────┘
```

1. **Feature Development**: Work on `feature/*`, `bugfix/*`, or `hotfix/*` branches
2. **Integration**: Merge to `integration` via Pull Request with review
3. **Release**: Merge `integration` to `main` via Pull Request with review

---

## Protection Rules

### Main Branch Protection

The `main` branch receives the highest level of protection:

| Rule                  | Setting       | Rationale                                   |
| --------------------- | ------------- | ------------------------------------------- |
| Direct pushes         | ❌ Blocked    | All changes must go through PR              |
| Force pushes          | ❌ Blocked    | Preserve history integrity                  |
| Branch deletion       | ❌ Blocked    | Prevent accidental loss                     |
| Required PR reviews   | ✅ 1 reviewer | Ensure code quality and knowledge sharing   |
| Dismiss stale reviews | ✅ Enabled    | Reviews must be current with latest changes |
| Resolve conversations | ✅ Required   | All feedback must be addressed              |
| Linear history        | ✅ Required   | Clean, traceable commit history             |

### Integration Branch Protection

The `integration` branch serves as a staging area before production:

| Rule                  | Setting       | Rationale                                   |
| --------------------- | ------------- | ------------------------------------------- |
| Direct pushes         | ❌ Blocked    | All changes must go through PR              |
| Force pushes          | ❌ Blocked    | Preserve history integrity                  |
| Branch deletion       | ❌ Blocked    | Prevent accidental loss                     |
| Required PR reviews   | ✅ 1 reviewer | Ensure code quality                         |
| Dismiss stale reviews | ✅ Enabled    | Reviews must be current with latest changes |
| Resolve conversations | ✅ Required   | All feedback must be addressed              |

---

## Implementation

### Ruleset Files

Rulesets are stored as JSON files in `.github/rulesets/`. The rulesets are split into two categories to enable granular bypass permissions:

1. **Core Protection Rulesets** (no bypass): Enforce fundamental branch safety rules
2. **PR Review Rulesets** (with bypass): Enforce review requirements, allowing designated users to bypass when needed

```
.github/rulesets/
├── main-branch-protection.json      # Core rules: deletion, force-push, linear history
├── main-pr-reviews.json             # PR review requirements (bypassable)
├── integration-branch-protection.json  # Core rules: deletion, force-push
└── integration-pr-reviews.json      # PR review requirements (bypassable)
```

#### Why Split Rulesets?

GitHub Rulesets bypass actors work at the **ruleset level**, not at the individual rule level. To allow a user to bypass only the `required_approving_review_count` while still enforcing other rules (like preventing force pushes), the rules must be separated into different rulesets.

### Justfile Recipes

The following recipes are available for managing repository protection:

| Recipe                             | Description                            |
| ---------------------------------- | -------------------------------------- |
| `just protect-repo <repo>`         | Apply all branch protection rulesets   |
| `just apply-ruleset <repo> <file>` | Apply a single ruleset from JSON file  |
| `just unprotect-repo <repo>`       | Remove all rulesets (use with caution) |
| `just list-rulesets <repo>`        | List all rulesets for a repository     |

### Usage Examples

```bash
# Protect a repository (applies all rulesets)
just protect-repo aRustyDev/my-repo

# Apply a single ruleset
just apply-ruleset aRustyDev/my-repo .github/rulesets/main-branch-protection.json

# View current protection status
just list-rulesets aRustyDev/my-repo

# Remove all protections
just unprotect-repo aRustyDev/my-repo
```

---

## GitHub Rulesets API

### Why Rulesets Over Branch Protection Rules?

GitHub Repository Rulesets (introduced 2023) offer advantages over legacy branch protection rules:

| Feature                  | Legacy Protection | Rulesets         |
| ------------------------ | ----------------- | ---------------- |
| Target multiple branches | ❌ One at a time  | ✅ Pattern-based |
| Organization-wide rules  | ❌ Repo-only      | ✅ Org-level     |
| Import/Export as JSON    | ❌ API only       | ✅ Native JSON   |
| Bypass permissions       | Limited           | ✅ Fine-grained  |
| Audit logging            | Basic             | ✅ Enhanced      |

### API Endpoints

| Operation      | Method | Endpoint                              |
| -------------- | ------ | ------------------------------------- |
| List rulesets  | GET    | `/repos/{owner}/{repo}/rulesets`      |
| Create ruleset | POST   | `/repos/{owner}/{repo}/rulesets`      |
| Get ruleset    | GET    | `/repos/{owner}/{repo}/rulesets/{id}` |
| Update ruleset | PUT    | `/repos/{owner}/{repo}/rulesets/{id}` |
| Delete ruleset | DELETE | `/repos/{owner}/{repo}/rulesets/{id}` |

### Ruleset JSON Schema

**Core Protection Ruleset** (no bypass):

```json
{
  "name": "main-branch-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" }
  ],
  "bypass_actors": []
}
```

**PR Review Ruleset** (with bypass):

```json
{
  "name": "main-pr-reviews",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": true,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    }
  ],
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "pull_request"
    }
  ]
}
```

### Bypass Actor Configuration

| Property      | Value                                                                     | Description                                                       |
| ------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `actor_id`    | Role/Team/Integration ID                                                  | Numeric ID (see below for role IDs)                               |
| `actor_type`  | `Integration`, `OrganizationAdmin`, `RepositoryRole`, `Team`, `DeployKey` | Type of actor (Note: `User` is NOT valid for repository rulesets) |
| `bypass_mode` | `always`, `pull_request`, `exempt`                                        | When bypass applies                                               |

**Repository Role IDs:**

| ID  | Role             | Description                                         |
| --- | ---------------- | --------------------------------------------------- |
| 1   | Maintain         | Can manage repo without access to sensitive actions |
| 2   | Write            | Can push to non-protected branches                  |
| 3   | Admin            | Full access to the repository                       |
| 5   | Repository Admin | Owner role for personal repositories                |

**Bypass Modes:**

- `always`: Bypass all rules at all times
- `pull_request`: Only bypass rules on pull requests (recommended for review bypasses)
- `exempt`: Rules not run, no audit entry created

---

## Available Rule Types

| Rule Type                 | Description                                      |
| ------------------------- | ------------------------------------------------ |
| `deletion`                | Prevent branch deletion                          |
| `non_fast_forward`        | Prevent force pushes (history rewrite)           |
| `pull_request`            | Require pull requests with configurable reviews  |
| `required_linear_history` | Require linear commit history (no merge commits) |
| `required_signatures`     | Require signed commits                           |
| `required_status_checks`  | Require CI/CD checks to pass                     |
| `update`                  | Prevent non-admin updates                        |

---

## Prerequisites

1. **GitHub CLI**: Authenticated with admin access to the target repository

   ```bash
   gh auth status
   ```

2. **jq**: For JSON processing

   ```bash
   jq --version
   ```

3. **Repository Admin Access**: Required to create/modify rulesets

---

## Troubleshooting

### Common Issues

| Issue                     | Solution                                        |
| ------------------------- | ----------------------------------------------- |
| "Resource not accessible" | Ensure you have admin access to the repository  |
| "Ruleset already exists"  | The recipe will update existing rulesets        |
| "Branch doesn't exist"    | `protect-integration` creates branch if missing |
| "Invalid ruleset format"  | Validate JSON in `.github/rulesets/` files      |

### Verification

After applying protection, verify with:

```bash
# List applied rulesets
just list-rulesets owner/repo

# Test protection (should fail)
git push origin main  # Should be rejected

# Verify in GitHub UI
# Settings → Rules → Rulesets
```

---

## Security Considerations

1. **Bypass Actors**: Bypass actors are configured only on PR review rulesets, allowing designated users to merge without approval while still being subject to core branch protections (no force push, no deletion). The bypass uses `"bypass_mode": "pull_request"` to limit bypass capability to PR merges only.

2. **Enforcement Level**: Use `"enforcement": "active"` for production. Use `"enforcement": "evaluate"` for testing without blocking.

3. **Review Requirements**: Minimum 1 reviewer is recommended. Increase for sensitive repositories.

4. **Emergency Access**: Document procedures for legitimate emergency direct pushes (requires temporary ruleset modification).

---

## References

- [GitHub Rulesets Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets)
- [GitHub REST API - Rulesets](https://docs.github.com/en/rest/repos/rules)
- [Migrating from Branch Protection to Rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets#about-rulesets-branch-protection-rules-and-protected-tags)
