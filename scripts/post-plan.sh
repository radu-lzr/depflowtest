#!/bin/sh
set -e

PLAN_JSON=$(terraform show -json "$TERRATEAM_PLAN_FILE")

# Extract PR number and title from the GitHub event payload
PR_NUMBER=$(jq -r '.pull_request.number // empty' "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
PR_TITLE=$(jq -r '.pull_request.title // empty' "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")

jq -n \
  --arg commit "$GITHUB_SHA" \
  --arg target_branch "$GITHUB_BASE_REF" \
  --arg source_branch "$GITHUB_HEAD_REF" \
  --arg pr_number "$PR_NUMBER" \
  --arg pr_title "$PR_TITLE" \
  --arg repo "$GITHUB_REPOSITORY" \
  --arg dir "$TERRATEAM_DIR" \
  --arg workspace "$TERRATEAM_WORKSPACE" \
  --argjson plan "$PLAN_JSON" \
  '{commit: $commit, target_branch: $target_branch, source_branch: $source_branch, pr_number: $pr_number, pr_title: $pr_title, repo: $repo, dir: $dir, workspace: $workspace, plan: $plan}' \
| curl -s -X POST -H "Content-Type: application/json" -d @- http://terrateamplantest.ebb4cmfnbwexdmgy.francecentral.azurecontainer.io:8000/plans
