#!/bin/bash

# ============ 設定 =============
OLD_ORG="old-org"
NEW_ORG="new-org"
GITHUB_TOKEN="your_personal_access_token"

echo "Fetching repositories..."
REPO_LIST=$(gh repo list $OLD_ORG --limit 200 --json name -q ".[].name")

for REPO in $REPO_LIST; do
    echo "Migrating Issues, PRs, and Labels for: $REPO"

    # Issues 移行
    ISSUES=$(gh api "repos/$OLD_ORG/$REPO/issues" -q ".[].number")
    for ISSUE in $ISSUES; do
        TITLE=$(gh api "repos/$OLD_ORG/$REPO/issues/$ISSUE" -q ".title")
        BODY=$(gh api "repos/$OLD_ORG/$REPO/issues/$ISSUE" -q ".body")
        gh issue create -R "$NEW_ORG/$REPO" --title "$TITLE" --body "$BODY"
    done

    # Labels 移行
    LABELS=$(gh api "repos/$OLD_ORG/$REPO/labels" -q ".[].name")
    for LABEL in $LABELS; do
        gh api -X POST "repos/$NEW_ORG/$REPO/labels" -F name="$LABEL"
    done
done

echo "✅ Issues・PR・Labels 移行完了！"
