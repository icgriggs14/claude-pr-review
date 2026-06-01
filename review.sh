#!/usr/bin/env bash
set -euo pipefail

ANTHROPIC_API_KEY="${INPUT_ANTHROPIC_API_KEY}"
MODEL="${INPUT_MODEL:-claude-haiku-4-5-20251001}"
MAX_FILES="${INPUT_MAX_FILES:-10}"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "::error::anthropic_api_key input is required. Add your Anthropic API key as a GitHub Secret."
  exit 1
fi

# Extract PR number from GITHUB_REF (refs/pull/123/merge)
PR_NUMBER="${GITHUB_REF#refs/pull/}"
PR_NUMBER="${PR_NUMBER%/merge}"
REPO="$GITHUB_REPOSITORY"

if [[ -z "$PR_NUMBER" || "$PR_NUMBER" == "$GITHUB_REF" ]]; then
  echo "::error::This action must be triggered by a pull_request event."
  exit 1
fi

echo "Claude PR Review: #$PR_NUMBER in $REPO (model: $MODEL, max_files: $MAX_FILES)"

# Get PR metadata
PR_META=$(curl -sS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO/pulls/$PR_NUMBER")

PR_TITLE=$(echo "$PR_META" | jq -r '.title // "No title"')
PR_BODY=$(echo "$PR_META" | jq -r '.body // ""' | head -c 800)

# Get changed files (limited to max_files)
FILES_JSON=$(curl -sS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO/pulls/$PR_NUMBER/files?per_page=$MAX_FILES")

FILE_COUNT=$(echo "$FILES_JSON" | jq 'length')
echo "Found $FILE_COUNT changed files (reviewing up to $MAX_FILES)"

if [[ "$FILE_COUNT" -eq 0 ]]; then
  echo "No files changed in this PR — skipping review."
  exit 0
fi

# Build diff summary — truncate each file's patch to keep total prompt manageable
DIFF_SUMMARY=$(echo "$FILES_JSON" | jq -r '
  .[] |
  "### \(.filename) [\(.status)]\n" +
  (if .patch then (.patch | .[0:2500]) else "(binary or empty file)" end)
' | head -c 24000)

# Construct review prompt
PROMPT="You are an expert code reviewer. Review this pull request carefully.

**PR: ${PR_TITLE}**
${PR_BODY:+Description: $PR_BODY

}**Changed files (${FILE_COUNT} total):**
${DIFF_SUMMARY}

Provide a structured review:

## Summary
One or two sentences describing what this PR does.

## Issues
List each issue as:
- 🔴 CRITICAL: [description + suggested fix]
- 🟡 WARNING: [description + suggested fix]
- 💡 SUGGESTION: [description + suggestion]

If no issues found in a category, omit it.

## Verdict
**LGTM ✅** / **NEEDS WORK 🔧** / **BLOCKED 🚫** — one line explanation.

Be specific, actionable, and focused on correctness, security, and logic — not style."

# Build JSON payload safely using jq (handles all escaping)
REQUEST_BODY=$(jq -n \
  --arg model "$MODEL" \
  --arg content "$PROMPT" \
  '{
    model: $model,
    max_tokens: 1500,
    messages: [{role: "user", content: $content}]
  }')

echo "Calling Claude API..."

RESPONSE=$(curl -sS https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$REQUEST_BODY")

REVIEW_TEXT=$(echo "$RESPONSE" | jq -r '.content[0].text // empty')

if [[ -z "$REVIEW_TEXT" ]]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error.message // "Unknown API error"')
  echo "::error::Claude API error: $ERROR"
  echo "::error::Full response: $RESPONSE"
  exit 1
fi

# Build PR comment with Sponsors CTA
COMMENT_BODY="## 🤖 Claude PR Review

${REVIEW_TEXT}

---
*Reviewed by [claude-pr-review](https://github.com/icgriggs14/claude-pr-review) using \`${MODEL}\` · Find this useful? [Sponsor ☕](https://github.com/sponsors/icgriggs14)*"

# Post comment on the PR
COMMENT_RESPONSE=$(curl -sS -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$REPO/issues/$PR_NUMBER/comments" \
  --data "$(jq -n --arg body "$COMMENT_BODY" '{body: $body}')")

COMMENT_URL=$(echo "$COMMENT_RESPONSE" | jq -r '.html_url // empty')
if [[ -n "$COMMENT_URL" ]]; then
  echo "✓ Review posted: $COMMENT_URL"
else
  echo "::warning::Comment posted but could not parse URL. Response: $COMMENT_RESPONSE"
fi
