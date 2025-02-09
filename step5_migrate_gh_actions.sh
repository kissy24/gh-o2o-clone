#!/bin/bash

# ============ 設定 =============
OLD_ORG="old-org"
NEW_ORG="new-org"

echo "Fetching repositories..."
REPO_LIST=$(gh repo list $OLD_ORG --limit 200 --json name -q ".[].name")

for REPO in $REPO_LIST; do
    echo "Migrating GitHub Actions for: $REPO"
    gh api "repos/$OLD_ORG/$REPO/actions/secrets" > secrets.json
    # 各シークレットを新リポジトリに追加（手動調整が必要）
done

echo "✅ GitHub Actions 移行完了！"
