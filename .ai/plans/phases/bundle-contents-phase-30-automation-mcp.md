---
id: 66d2f055-ea20-46b5-8905-f7acd89c06c5
title: "Phase 30: Automation - MCP"
status: pending
depends_on:
  - 48214b5a-d97d-4805-80bb-fabe5c73df00  # phase-29
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
  - 52545f6d-de4f-421f-8444-3f8d683c3ad0  # testing-validation
issues: []
---

# Phase 30: Automation - MCP

## 1. Current State Assessment

- [ ] Check for existing MCP automation
- [ ] Review ecosystem discovery tools
- [ ] Identify evaluation frameworks
- [ ] Check for MCP server registry

### Existing Assets

- MCP testing taxonomy (references/)
- MCP protocol tests (Phase 11)

### Gaps Identified

- [ ] mcp-eval.yml (server evaluation)
- [ ] mcp-discovery.yml (ecosystem scanning with category-based search)
- [ ] discovery-config.yml (configurable search criteria)
- [ ] known-servers.yml (registry of known/evaluated servers)

---

## 2. Contextual Goal

Implement MCP-specific automation workflows for evaluating MCP server implementations and discovering ecosystem resources. The evaluation workflow runs comprehensive tests against MCP servers using the taxonomy defined in references. The discovery workflow scans for new MCP servers and tools in the ecosystem.

### Success Criteria

- [ ] MCP evaluation workflow functional
- [ ] Evaluation reports generated
- [ ] Ecosystem discovery runs on schedule (weekly)
- [ ] Search criteria configurable per category
- [ ] Known servers tracked to avoid duplicates
- [ ] New discoveries create issues automatically
- [ ] Results published to repository
- [ ] Badges/scores visible

### Out of Scope

- Running third-party MCP servers
- Maintaining a public registry
- Manual server evaluation (human task)

---

## 3. Implementation

### 3.1 mcp-eval.yml

```yaml
name: MCP Server Evaluation

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
  pull_request:
  schedule:
    - cron: '0 6 * * 1'  # Weekly
  workflow_dispatch:
    inputs:
      server:
        description: 'Server to evaluate (default: local)'
        default: 'local'

jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build server
        run: cargo build --release

      - name: Run protocol conformance
        run: |
          cargo test --test mcp_conformance -- --format json > conformance.json

      - name: Run functional tests
        run: |
          cargo test --test mcp_functional -- --format json > functional.json

      - name: Run performance benchmarks
        run: |
          cargo bench -- --format json > performance.json

      - name: Generate evaluation report
        run: |
          python scripts/generate-eval-report.py \
            --conformance conformance.json \
            --functional functional.json \
            --performance performance.json \
            --output evaluation-report.md

      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: mcp-evaluation
          path: evaluation-report.md

      - name: Update README badge
        if: github.ref == 'refs/heads/main'
        run: |
          # Calculate score and update badge

  compare:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: evaluate
    steps:
      - name: Compare with baseline
        run: |
          # Compare PR results with main branch baseline
```

### 3.2 discovery-config.yml

Configuration file defining search criteria for MCP server discovery:

```yaml
# .github/mcp/discovery-config.yml
version: 1

# How often to run discovery (cron expressions per category)
schedule:
  default: "0 6 * * 1"  # Weekly on Monday 6AM

# Search sources
sources:
  - name: github
    type: code-search
    enabled: true
  - name: npm
    type: package-registry
    enabled: true
  - name: pypi
    type: package-registry
    enabled: true
  - name: crates
    type: package-registry
    enabled: true

# Discovery categories with search criteria
categories:
  database:
    description: "Database and data storage MCP servers"
    priority: high
    search_terms:
      - "mcp server postgresql"
      - "mcp server mysql"
      - "mcp server mongodb"
      - "mcp server redis"
      - "mcp server sqlite"
      - "mcp-server database"
      - "model context protocol database"
    github_topics:
      - mcp-server
      - model-context-protocol
    file_patterns:
      - "**/mcp.json"
      - "**/mcp-server.json"
    exclude_terms:
      - "archived"
      - "deprecated"
      - "unmaintained"
    labels:
      - "mcp:database"
      - "type:discovery"

  ai-tools:
    description: "AI/ML integration MCP servers"
    priority: high
    search_terms:
      - "mcp server openai"
      - "mcp server anthropic"
      - "mcp server llm"
      - "mcp server embedding"
      - "mcp-server ai"
    labels:
      - "mcp:ai-tools"
      - "type:discovery"

  dev-tools:
    description: "Developer tooling MCP servers"
    priority: medium
    search_terms:
      - "mcp server git"
      - "mcp server github"
      - "mcp server docker"
      - "mcp server kubernetes"
      - "mcp server terraform"
      - "mcp-server devops"
    labels:
      - "mcp:dev-tools"
      - "type:discovery"

  file-storage:
    description: "File and cloud storage MCP servers"
    priority: medium
    search_terms:
      - "mcp server s3"
      - "mcp server gcs"
      - "mcp server azure blob"
      - "mcp server filesystem"
      - "mcp-server storage"
    labels:
      - "mcp:file-storage"
      - "type:discovery"

  communication:
    description: "Communication and messaging MCP servers"
    priority: low
    search_terms:
      - "mcp server slack"
      - "mcp server discord"
      - "mcp server email"
      - "mcp server webhook"
    labels:
      - "mcp:communication"
      - "type:discovery"

# Minimum quality thresholds
quality_filters:
  github:
    min_stars: 5
    min_commits: 10
    max_days_since_update: 180
    require_license: true
    require_readme: true
  npm:
    min_weekly_downloads: 100
  pypi:
    min_downloads: 500
  crates:
    min_downloads: 100

# Issue template for discoveries
issue_template: |
  ## MCP Server Discovery

  **Category**: {{ category }}
  **Source**: {{ source }}
  **Discovered**: {{ discovered_at }}

  ### Server Details

  | Field | Value |
  |-------|-------|
  | Name | {{ name }} |
  | Repository | {{ repository_url }} |
  | Package | {{ package_url }} |
  | Stars | {{ stars }} |
  | Last Updated | {{ last_updated }} |
  | License | {{ license }} |

  ### Description

  {{ description }}

  ### Evaluation Checklist

  - [ ] Review README and documentation
  - [ ] Check MCP protocol compliance
  - [ ] Verify security practices
  - [ ] Test basic functionality
  - [ ] Assess maintenance status
  - [ ] Document integration requirements

  ---
  *Auto-generated by MCP Discovery workflow*
```

### 3.3 known-servers.yml

Registry of known MCP servers to avoid duplicate discoveries:

```yaml
# .github/mcp/known-servers.yml
version: 1

# Known servers organized by category
servers:
  database:
    - id: "github:modelcontextprotocol/servers/postgres"
      name: "Official PostgreSQL Server"
      status: evaluated
      added: "2024-01-15"

    - id: "github:modelcontextprotocol/servers/sqlite"
      name: "Official SQLite Server"
      status: evaluated
      added: "2024-01-15"

  ai-tools:
    - id: "github:anthropics/claude-code"
      name: "Claude Code"
      status: internal
      added: "2024-01-01"

  dev-tools:
    - id: "github:modelcontextprotocol/servers/github"
      name: "Official GitHub Server"
      status: evaluated
      added: "2024-01-15"

    - id: "github:modelcontextprotocol/servers/git"
      name: "Official Git Server"
      status: evaluated
      added: "2024-01-15"

  file-storage:
    - id: "github:modelcontextprotocol/servers/filesystem"
      name: "Official Filesystem Server"
      status: evaluated
      added: "2024-01-15"

# Servers to explicitly ignore (forks, deprecated, etc.)
ignored:
  - id: "github:*/mcp-server-template"
    reason: "Template repository"

  - id: "github:*/awesome-mcp*"
    reason: "Awesome list, not a server"

# Status values:
# - evaluated: Fully evaluated and documented
# - pending: Discovered, awaiting evaluation
# - rejected: Evaluated and rejected
# - internal: Internal/first-party server
# - ignored: Explicitly ignored
```

### 3.4 mcp-discovery.yml

Main discovery workflow with category-based search, filtering, and auto-issue creation:

```yaml
name: MCP Server Discovery

on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday 6AM UTC
  workflow_dispatch:
    inputs:
      category:
        description: 'Category to search (or "all")'
        required: false
        default: 'all'
        type: choice
        options:
          - all
          - database
          - ai-tools
          - dev-tools
          - file-storage
          - communication
      dry_run:
        description: 'Dry run (no issue creation)'
        required: false
        default: false
        type: boolean

permissions:
  contents: write
  issues: write

jobs:
  discover:
    runs-on: ubuntu-latest
    outputs:
      discoveries: ${{ steps.filter.outputs.new_discoveries }}
      new_count: ${{ steps.filter.outputs.new_count }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install js-yaml

      - name: Load configuration
        id: config
        run: |
          echo "config<<EOF" >> $GITHUB_OUTPUT
          cat .github/mcp/discovery-config.yml >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Load known servers
        id: known
        run: |
          echo "known<<EOF" >> $GITHUB_OUTPUT
          cat .github/mcp/known-servers.yml >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Search for MCP servers
        id: search
        uses: actions/github-script@v7
        env:
          CATEGORY: ${{ inputs.category || 'all' }}
          CONFIG: ${{ steps.config.outputs.config }}
        with:
          script: |
            const yaml = require('js-yaml');
            const config = yaml.load(process.env.CONFIG);
            const targetCategory = process.env.CATEGORY;

            const discoveries = [];

            // Determine which categories to search
            const categories = targetCategory === 'all'
              ? Object.keys(config.categories)
              : [targetCategory];

            for (const categoryName of categories) {
              const category = config.categories[categoryName];
              if (!category) continue;

              console.log(`\n=== Searching category: ${categoryName} ===`);

              // Search GitHub
              for (const term of category.search_terms || []) {
                try {
                  const query = `${term} in:readme,name,description`;
                  console.log(`Searching: ${query}`);

                  const { data: results } = await github.rest.search.repos({
                    q: query,
                    sort: 'stars',
                    order: 'desc',
                    per_page: 20
                  });

                  for (const repo of results.items) {
                    // Apply quality filters
                    const filters = config.quality_filters.github;
                    if (repo.stargazers_count < filters.min_stars) continue;
                    if (repo.archived) continue;

                    const daysSinceUpdate = Math.floor(
                      (Date.now() - new Date(repo.updated_at)) / (1000 * 60 * 60 * 24)
                    );
                    if (daysSinceUpdate > filters.max_days_since_update) continue;
                    if (filters.require_license && !repo.license) continue;

                    discoveries.push({
                      id: `github:${repo.full_name}`,
                      category: categoryName,
                      source: 'github',
                      name: repo.name,
                      full_name: repo.full_name,
                      description: repo.description || '',
                      repository_url: repo.html_url,
                      package_url: null,
                      stars: repo.stargazers_count,
                      forks: repo.forks_count,
                      last_updated: repo.updated_at,
                      license: repo.license?.spdx_id || 'Unknown',
                      topics: repo.topics || [],
                      labels: category.labels || []
                    });
                  }

                  // Rate limiting pause
                  await new Promise(r => setTimeout(r, 1000));
                } catch (error) {
                  console.log(`Search error for "${term}": ${error.message}`);
                }
              }
            }

            // Deduplicate by ID
            const unique = [...new Map(discoveries.map(d => [d.id, d])).values()];
            console.log(`\nTotal discoveries: ${unique.length}`);

            core.setOutput('discoveries', JSON.stringify(unique));
            return unique;

      - name: Filter known servers
        id: filter
        uses: actions/github-script@v7
        env:
          DISCOVERIES: ${{ steps.search.outputs.discoveries }}
          KNOWN: ${{ steps.known.outputs.known }}
        with:
          script: |
            const yaml = require('js-yaml');
            const discoveries = JSON.parse(process.env.DISCOVERIES);
            const known = yaml.load(process.env.KNOWN);

            // Build set of known IDs
            const knownIds = new Set();

            // Add all known servers
            for (const category of Object.values(known.servers || {})) {
              for (const server of category) {
                knownIds.add(server.id);
              }
            }

            // Add ignored patterns
            const ignoredPatterns = (known.ignored || []).map(i => {
              const pattern = i.id.replace(/\*/g, '.*');
              return new RegExp(`^${pattern}$`);
            });

            // Filter discoveries
            const newDiscoveries = discoveries.filter(d => {
              // Check exact match
              if (knownIds.has(d.id)) {
                console.log(`Skipping known: ${d.id}`);
                return false;
              }

              // Check ignored patterns
              for (const pattern of ignoredPatterns) {
                if (pattern.test(d.id)) {
                  console.log(`Skipping ignored: ${d.id}`);
                  return false;
                }
              }

              return true;
            });

            console.log(`\nNew discoveries: ${newDiscoveries.length}`);

            core.setOutput('new_discoveries', JSON.stringify(newDiscoveries));
            core.setOutput('new_count', newDiscoveries.length);
            return newDiscoveries;

  create-issues:
    needs: discover
    if: needs.discover.outputs.new_count > 0 && inputs.dry_run != true
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Create discovery issues
        uses: actions/github-script@v7
        env:
          DISCOVERIES: ${{ needs.discover.outputs.discoveries }}
        with:
          script: |
            const discoveries = JSON.parse(process.env.DISCOVERIES);

            for (const d of discoveries) {
              // Check for existing issue
              const { data: issues } = await github.rest.issues.listForRepo({
                owner: context.repo.owner,
                repo: context.repo.repo,
                state: 'all',
                labels: 'type:discovery',
                per_page: 100
              });

              const exists = issues.some(issue =>
                issue.body && issue.body.includes(d.id)
              );

              if (exists) {
                console.log(`Issue already exists for: ${d.id}`);
                continue;
              }

              const body = `## MCP Server Discovery

**Category**: ${d.category}
**Source**: ${d.source}
**Discovered**: ${new Date().toISOString().split('T')[0]}

### Server Details

| Field | Value |
|-------|-------|
| Name | ${d.name} |
| Repository | ${d.repository_url} |
| Package | ${d.package_url || 'N/A'} |
| Stars | ${d.stars} |
| Last Updated | ${d.last_updated.split('T')[0]} |
| License | ${d.license} |

### Description

${d.description || '_No description provided_'}

### Evaluation Checklist

- [ ] Review README and documentation
- [ ] Check MCP protocol compliance
- [ ] Verify security practices
- [ ] Test basic functionality
- [ ] Assess maintenance status
- [ ] Document integration requirements

---
**Server ID**: \`${d.id}\`
*Auto-generated by MCP Discovery workflow*`;

              const { data: issue } = await github.rest.issues.create({
                owner: context.repo.owner,
                repo: context.repo.repo,
                title: `[MCP Discovery] ${d.name}`,
                body: body,
                labels: d.labels
              });

              console.log(`Created issue #${issue.number}: ${issue.title}`);

              // Rate limit pause
              await new Promise(r => setTimeout(r, 2000));
            }

  update-known:
    needs: [discover, create-issues]
    if: always() && needs.discover.outputs.new_count > 0 && inputs.dry_run != true
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          ref: main

      - name: Update known-servers.yml
        uses: actions/github-script@v7
        env:
          DISCOVERIES: ${{ needs.discover.outputs.discoveries }}
        with:
          script: |
            const fs = require('fs');
            const yaml = require('js-yaml');

            const discoveries = JSON.parse(process.env.DISCOVERIES);
            const knownPath = '.github/mcp/known-servers.yml';
            const known = yaml.load(fs.readFileSync(knownPath, 'utf8'));

            // Add new discoveries as pending
            for (const d of discoveries) {
              if (!known.servers[d.category]) {
                known.servers[d.category] = [];
              }

              // Check if already exists
              const exists = known.servers[d.category].some(s => s.id === d.id);
              if (!exists) {
                known.servers[d.category].push({
                  id: d.id,
                  name: d.name,
                  status: 'pending',
                  added: new Date().toISOString().split('T')[0]
                });
              }
            }

            fs.writeFileSync(knownPath, yaml.dump(known, { lineWidth: -1 }));

      - name: Commit updates
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .github/mcp/known-servers.yml
          git diff --quiet --staged || git commit -m "chore(mcp): update known servers from discovery

          Added ${{ needs.discover.outputs.new_count }} new server(s) as pending.

          [skip ci]"
          git push

  summary:
    needs: [discover, create-issues, update-known]
    if: always()
    runs-on: ubuntu-latest

    steps:
      - name: Generate summary
        uses: actions/github-script@v7
        with:
          script: |
            const newCount = parseInt('${{ needs.discover.outputs.new_count }}') || 0;
            const dryRun = '${{ inputs.dry_run }}' === 'true';

            let summary = `## MCP Discovery Summary\n\n`;
            summary += `| Metric | Value |\n`;
            summary += `|--------|-------|\n`;
            summary += `| New Discoveries | ${newCount} |\n`;
            summary += `| Dry Run | ${dryRun ? 'Yes' : 'No'} |\n`;
            summary += `| Issues Created | ${dryRun ? 'N/A' : newCount} |\n`;

            if (newCount > 0) {
              const discoveries = JSON.parse('${{ needs.discover.outputs.discoveries }}');
              summary += `\n### Discoveries by Category\n\n`;

              const byCategory = {};
              for (const d of discoveries) {
                byCategory[d.category] = (byCategory[d.category] || 0) + 1;
              }

              for (const [cat, count] of Object.entries(byCategory)) {
                summary += `- **${cat}**: ${count}\n`;
              }
            }

            await core.summary.addRaw(summary).write();
```

### 3.5 Evaluation Metrics

| Category | Metrics | Weight |
|----------|---------|--------|
| Protocol Conformance | JSON-RPC, MCP init, capabilities | 40% |
| Functional | Tools, resources, prompts | 30% |
| Performance | Latency p50/p95/p99, throughput | 20% |
| Security | Input validation, fuzzing survival | 10% |

### 3.6 Discovery Sources

| Source | Search Method |
|--------|---------------|
| GitHub | Topic search, code search, readme search |
| npm | Keyword search (mcp-server, model-context-protocol) |
| PyPI | Classifier/keyword search |
| crates.io | Keyword search |

### 3.7 Discovery Categories

| Category | Priority | Example Search Terms |
|----------|----------|---------------------|
| `database` | High | postgresql, mysql, mongodb, redis, sqlite |
| `ai-tools` | High | openai, anthropic, llm, embedding |
| `dev-tools` | Medium | git, github, docker, kubernetes, terraform |
| `file-storage` | Medium | s3, gcs, azure blob, filesystem |
| `communication` | Low | slack, discord, email, webhook |

---

## 4. Review & Validation

- [ ] Evaluation produces meaningful scores
- [ ] Discovery config loads correctly
- [ ] Category-based search works
- [ ] Known servers filtered correctly
- [ ] Quality filters applied (stars, license, update date)
- [ ] New discoveries create issues automatically
- [ ] known-servers.yml updated after discovery
- [ ] Dry run mode prevents issue creation
- [ ] Reports are readable
- [ ] Automation runs on schedule (weekly)
- [ ] Implementation tracking checklist updated

---

## Final Notes

This phase completes the Bundle Expansion plan. After implementing all 30 phases:

1. Run the Testing Validation checklist
2. Update the Gap Analysis checklist
3. Create a release with the complete bundle
4. Publish documentation
