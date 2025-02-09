#!/bin/bash

# ============ 設定 =============
OLD_ORG="old-org"
NEW_ORG="new-org"

echo "Fetching teams..."
TEAMS=$(gh api "orgs/$OLD_ORG/teams" -q ".[].slug")

for TEAM in $TEAMS; do
    echo "Migrating Team: $TEAM"
    gh api -X POST "orgs/$NEW_ORG/teams" -F name="$TEAM"
done

echo "✅ Teams 移行完了！"
