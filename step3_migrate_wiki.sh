#!/bin/bash

# ============ 設定 =============
OLD_ORG="old-org"
NEW_ORG="new-org"

echo "Fetching repositories..."
REPO_LIST=$(gh repo list $OLD_ORG --limit 200 --json name -q ".[].name")

for REPO in $REPO_LIST; do
    echo "Migrating Wiki for: $REPO"
    git clone --bare "https://github.com/$OLD_ORG/$REPO.wiki.git"
    cd "$REPO.wiki.git"
    git push --mirror "https://github.com/$NEW_ORG/$REPO.wiki.git"
    cd ..
done

echo "✅ Wiki 移行完了！"
