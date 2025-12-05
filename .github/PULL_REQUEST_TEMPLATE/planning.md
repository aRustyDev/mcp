## Summary

<!-- Brief description of the planning document(s) being added or modified -->

## Planning Document Type

- [ ] Plan (`.ai/plans/<plan-name>.md`)
- [ ] Phase document (`.ai/plans/phases/<plan-name>-phase-<N>.md`)
- [ ] ADR - Architecture Decision Record (`.ai/docs/adr/*.md`)
- [ ] Index update (`.ai/INDEX.md`)
- [ ] Other planning artifact: <!-- specify -->

## Documents Affected

| File | Action | UUID |
|------|--------|------|
| `.ai/plans/example.md` | Added/Modified | `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` |

## Related Issues

<!-- Link to related issues: Fixes #123, Relates to #456 -->

## Frontmatter Checklist

### Required Fields
- [ ] `id` - Valid UUID v4 (uppercase with hyphens)
- [ ] `title` - Descriptive document title
- [ ] `status` - Emoji prefix + status text (e.g., `⏳ In Progress`, `✅ Completed`)
- [ ] `date` - ISO 8601 format (YYYY-MM-DD)
- [ ] `author` - Author username

### Optional Fields (if applicable)
- [ ] `related` - Array of related document UUIDs
- [ ] `children` - Array of child document UUIDs (for plans with phases)
- [ ] `depends_on` - Array of dependency UUIDs (for phase documents)
- [ ] `tags` - Array of categorization tags

## Plan Structure (for new plans)

- [ ] Problem statement clearly defined
- [ ] Goals/objectives listed
- [ ] Phases broken down (if multi-phase)
- [ ] Success criteria defined
- [ ] Dependencies identified

## Cross-Reference Verification

- [ ] Bidirectional links maintained (if A `related` to B, B `related` to A)
- [ ] Parent plan references child phases in `children` array
- [ ] Child phases reference parent in `related` array
- [ ] INDEX.md updated to include new documents

## Phase Document Checklist (if applicable)

- [ ] Phase numbered correctly in filename
- [ ] Tasks/steps clearly defined
- [ ] Acceptance criteria specified
- [ ] Dependencies on prior phases documented

## ADR Checklist (if applicable)

- [ ] Problem statement clearly articulated
- [ ] Decision documented
- [ ] Alternatives considered and documented
- [ ] Tradeoffs analyzed
- [ ] Implementation strategy outlined

## Validation

- [ ] All UUIDs are unique (not duplicated from other documents)
- [ ] All referenced UUIDs exist in the project
- [ ] Markdown renders correctly
- [ ] No broken internal links

## Additional Context

<!-- Any other information reviewers should know about these planning documents -->
