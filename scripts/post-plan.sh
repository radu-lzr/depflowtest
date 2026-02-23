#!/bin/sh
set -e

API_URL="${MONITOR_API_URL:-http://terrateamplantest.ebb4cmfnbwexdmgy.francecentral.azurecontainer.io:8000}"

PLAN_JSON=$(terraform show -json "$TERRATEAM_PLAN_FILE")

# Get PR info from GitHub API
PR_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls?head=$GITHUB_REPOSITORY_OWNER:$GITHUB_HEAD_REF&base=$TARGET_BRANCH&state=open" \
  2>/dev/null || echo "[]")

PR_NUMBER=$(echo "$PR_DATA" | jq -r '.[0].number // empty' 2>/dev/null || echo "")
PR_TITLE=$(echo "$PR_DATA" | jq -r '.[0].title // empty' 2>/dev/null || echo "")
SOURCE_BRANCH=$(echo "$PR_DATA" | jq -r '.[0].head.ref // empty' 2>/dev/null || echo "")

jq -n \
  --arg commit "$GITHUB_SHA" \
  --arg target_branch "$TARGET_BRANCH" \
  --arg source_branch "$SOURCE_BRANCH" \
  --arg pr_number "$PR_NUMBER" \
  --arg pr_title "$PR_TITLE" \
  --arg repo "$GITHUB_REPOSITORY" \
  --arg dir "$TERRATEAM_DIR" \
  --arg workspace "$TERRATEAM_WORKSPACE" \
  --argjson plan "$PLAN_JSON" \
  '{commit: $commit, target_branch: $target_branch, source_branch: $source_branch, pr_number: $pr_number, pr_title: $pr_title, repo: $repo, dir: $dir, workspace: $workspace, plan: $plan}' \
| curl -s -X POST -H "Content-Type: application/json" -d @- "$API_URL/plans"
