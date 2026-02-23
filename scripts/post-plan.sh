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

# Generate DOT graph from plan
DOT_GRAPH=$(echo "$PLAN_JSON" | jq -r '
  "digraph plan {",
  "  rankdir=LR;",
  "  node [shape=box, style=filled, fontname=\"Helvetica\"];",
  "  edge [fontname=\"Helvetica\", fontsize=10];",
  "",
  # Color legend
  "  subgraph cluster_legend {",
  "    label=\"Legend\"; style=dashed; fontname=\"Helvetica\";",
  "    legend_create [label=\"create\", fillcolor=\"#c6efce\"];",
  "    legend_update [label=\"update\", fillcolor=\"#ffeb9c\"];",
  "    legend_delete [label=\"delete\", fillcolor=\"#ffc7ce\"];",
  "    legend_read   [label=\"read\",   fillcolor=\"#b4c7e7\"];",
  "    legend_noop   [label=\"no-op\",  fillcolor=\"#f2f2f2\"];",
  "  }",
  "",
  # Resource nodes
  (
    .resource_changes // [] | to_entries[] |
    .value as $rc |
    .key as $i |
    ($rc.change.actions | join(",")) as $action |
    (
      if   $action == "create"      then "#c6efce"
      elif $action == "delete"      then "#ffc7ce"
      elif $action == "update"      then "#ffeb9c"
      elif $action == "read"        then "#b4c7e7"
      elif $action == "no-op"       then "#f2f2f2"
      elif ($action | test("create")) and ($action | test("delete")) then "#d9a3ff"
      else "#f2f2f2"
      end
    ) as $color |
    "  r\($i) [label=\"\($rc.type)\\n\($rc.name)\\n[\($action)]\", fillcolor=\"\($color)\"];"
  ),
  "",
  # Dependency edges from configuration
  (
    .configuration.root_module.resources // [] | to_entries[] |
    .value as $res |
    .key as $i |
    (
      $res.expressions // {} | to_entries[] |
      .value.references // [] | .[] |
      select(startswith("var.") | not) |
      split(".")[0:2] | join(".")
    ) as $dep |
    if $dep != "\($res.type).\($res.name)" then
      "  \"\($dep)\" -> \"\($res.type).\($res.name)\" [label=\"ref\"];"
    else empty end
  ),
  "",
  # Rename nodes to match dependency edges
  (
    .resource_changes // [] | to_entries[] |
    .value as $rc |
    .key as $i |
    "  r\($i) [label=\"\($rc.type)\\n\($rc.name)\\n[\($rc.change.actions | join(","))]\"];"
  ),
  "}"
')

# Build the JSON with DOT graph included
jq -n \
  --arg commit "$GITHUB_SHA" \
  --arg target_branch "$TARGET_BRANCH" \
  --arg source_branch "$SOURCE_BRANCH" \
  --arg pr_number "$PR_NUMBER" \
  --arg pr_title "$PR_TITLE" \
  --arg repo "$GITHUB_REPOSITORY" \
  --arg dir "$TERRATEAM_DIR" \
  --arg workspace "$TERRATEAM_WORKSPACE" \
  --arg dot_graph "$DOT_GRAPH" \
  --argjson plan "$PLAN_JSON" \
  '{commit: $commit, target_branch: $target_branch, source_branch: $source_branch, pr_number: $pr_number, pr_title: $pr_title, repo: $repo, dir: $dir, workspace: $workspace, plan: $plan, dot_graph: $dot_graph}' \
| curl -s -X POST -H "Content-Type: application/json" -d @- "$API_URL/plans"
