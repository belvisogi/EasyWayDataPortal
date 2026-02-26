#!/bin/bash
set -e

if [ "$#" -lt 5 ]; then
    echo "Usage: $0 <SourceBranch> <TargetBranch> <Title> <Description> <SecurityChecklist> [Draft: true/false]"
    echo "Example: $0 feature-1 develop 'feat: added stuff' 'Description...' '- [x] Check 1'"
    exit 1
fi

SOURCE_BRANCH="$1"
TARGET_BRANCH="$2"
TITLE="$3"
DESCRIPTION="$4"
CHECKLIST="$5"
DRAFT="${6:-false}"

    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
else
    echo "❌ Could not parse GitHub owner and repository from '$REMOTE_URL'"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️ GITHUB_TOKEN not found. Falling back to Local Link Mode."
    
    # Use python for reliable URL encoding
    ENCODED_URL=$(python -c '
import urllib.parse, sys
title = urllib.parse.quote(sys.argv[1])
body = urllib.parse.quote(sys.argv[2] + "\n\n" + sys.argv[3])
print(f"https://github.com/{sys.argv[4]}/{sys.argv[5]}/compare/{sys.argv[7]}...{sys.argv[6]}?expand=1&title={title}&body={body}")
' "$TITLE" "$DESCRIPTION" "$CHECKLIST" "$OWNER" "$REPO" "$SOURCE_BRANCH" "$TARGET_BRANCH")

    echo "✅ Pull Request link generated successfully!"
    echo "👉 Automatically Pre-filled URL: $ENCODED_URL"
    exit 0
fi

API_URL="https://api.github.com/repos/$OWNER/$REPO/pulls"

# Safely construct JSON using a python helper since jq is not guaranteed, and Bash string escape is fragile
JSON_DATA=$(python -c '
import json, sys
data = {
    "title": sys.argv[1],
    "body": sys.argv[2] + "\n\n" + sys.argv[3],
    "head": sys.argv[4],
    "base": sys.argv[5],
    "draft": sys.argv[6].lower() == "true"
}
print(json.dumps(data))
' "$TITLE" "$DESCRIPTION" "$CHECKLIST" "$SOURCE_BRANCH" "$TARGET_BRANCH" "$DRAFT")

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA")

# Split HTTP body and status code
HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$HTTP_STATUS" -eq 201 ]; then
    echo "✅ Pull Request created successfully!"
    # Grab the URL from the response cleanly
    PR_URL=$(python -c "import sys, json; print(json.loads(sys.argv[1]).get('html_url', ''))" "$HTTP_BODY")
    echo "👉 URL: $PR_URL"
else
    echo "❌ Failed to create PR. HTTP Status: $HTTP_STATUS"
    echo "Details:"
    echo "$HTTP_BODY"
    exit 1
fi
