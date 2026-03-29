---
id: 48214b5a-d97d-4805-80bb-fabe5c73df00
title: "Phase 29: Automation - Notifications"
status: pending
depends_on:
  - e587174a-70dc-412e-8c17-07637ada8ca4  # phase-28
checklists:
  - 674b3bcb-ee95-496e-ac24-4d144685f05b  # implementation-tracking
issues: []
---

# Phase 29: Automation - Notifications

## 1. Current State Assessment

- [ ] Check for existing notification setup
- [ ] Review webhook configurations
- [ ] Identify notification triggers
- [ ] Check for secret management

### Existing Assets

None - notifications not yet configured.

### Gaps Identified

- [ ] notify-slack.yml
- [ ] notify-discord.yml

---

## 2. Contextual Goal

Implement notification workflows for Slack and Discord to keep teams informed of releases, security issues, and CI failures. Notifications should be configurable with different channels for different event types.

### Success Criteria

- [ ] Slack notifications on releases
- [ ] Discord notifications on releases
- [ ] Security alerts routed correctly
- [ ] CI failure notifications
- [ ] Secrets properly managed

### Out of Scope

- PagerDuty/OpsGenie integration
- Email notifications

---

## 3. Implementation

### 3.1 notify-slack.yml

```yaml
name: Notify Slack

on:
  release:
    types: [published]
  workflow_run:
    workflows: ["CI"]
    types: [completed]
  workflow_dispatch:
    inputs:
      message:
        description: 'Custom message'
        required: true

jobs:
  notify-release:
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: 'releases'
          payload: |
            {
              "blocks": [
                {
                  "type": "header",
                  "text": {
                    "type": "plain_text",
                    "text": "New Release: ${{ github.event.release.tag_name }}"
                  }
                },
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "${{ github.event.release.body }}"
                  }
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": {"type": "plain_text", "text": "View Release"},
                      "url": "${{ github.event.release.html_url }}"
                    }
                  ]
                }
              ]
            }
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}

  notify-failure:
    if: github.event_name == 'workflow_run' && github.event.workflow_run.conclusion == 'failure'
    runs-on: ubuntu-latest
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: 'ci-alerts'
          payload: |
            {
              "text": "CI Failed: ${{ github.event.workflow_run.name }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*CI Failure*\nWorkflow: ${{ github.event.workflow_run.name }}\nBranch: ${{ github.event.workflow_run.head_branch }}"
                  }
                }
              ]
            }
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

### 3.2 notify-discord.yml

```yaml
name: Notify Discord

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      message:
        description: 'Custom message'
        required: true

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Notify Discord
        uses: sarisia/actions-status-discord@v1
        if: github.event_name == 'release'
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          title: "New Release: ${{ github.event.release.tag_name }}"
          description: ${{ github.event.release.body }}
          url: ${{ github.event.release.html_url }}
          color: 0x00ff00

      - name: Custom notification
        if: github.event_name == 'workflow_dispatch'
        uses: sarisia/actions-status-discord@v1
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          title: "Announcement"
          description: ${{ inputs.message }}
```

### 3.3 Required Secrets

| Secret | Purpose |
|--------|---------|
| `SLACK_BOT_TOKEN` | Slack API token |
| `DISCORD_WEBHOOK` | Discord webhook URL |

### 3.4 Channel Routing

| Event | Slack Channel | Discord Channel |
|-------|---------------|-----------------|
| Release | #releases | releases |
| CI Failure | #ci-alerts | ci-alerts |
| Security | #security | security |

---

## 4. Review & Validation

- [ ] Slack notifications work
- [ ] Discord notifications work
- [ ] Messages format correctly
- [ ] Secrets are secured
- [ ] Implementation tracking checklist updated
