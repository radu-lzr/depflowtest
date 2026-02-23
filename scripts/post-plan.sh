#!/bin/sh
set -e

PLAN_JSON=$(terraform show -json "$TERRATEAM_PLAN_FILE")

jq -n \
  --arg commit "$TERRATEAM_HEAD_SHA" \
  --arg target_branch "$TERRATEAM_BASE_REF" \
  --arg source_branch "$TERRATEAM_HEAD_REF" \
  --arg pr_number "$TERRATEAM_PR_NUMBER" \
  --arg pr_title "$TERRATEAM_PR_TITLE" \
  --arg repo_owner "$TERRATEAM_REPO_OWNER" \
  --arg repo_name "$TERRATEAM_REPO_NAME" \
  --arg dir "$TERRATEAM_DIR" \
  --arg workspace "$TERRATEAM_WORKSPACE" \
  --argjson plan "$PLAN_JSON" \
  '{commit: $commit, target_branch: $target_branch, source_branch: $source_branch, pr_number: $pr_number, pr_title: $pr_title, repo: ($repo_owner + "/" + $repo_name), dir: $dir, workspace: $workspace, plan: $plan}' \
| curl -s -X POST -H "Content-Type: application/json" -d @- http://terrateamplantest.ebb4cmfnbwexdmgy.francecentral.azurecontainer.io:8000/plans
