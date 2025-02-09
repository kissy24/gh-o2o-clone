#!/bin/bash

# ============ 設定 =============
OLD_ORG="old-org"   # 移行元のOrganization
NEW_ORG="new-org"   # 移行先のOrganization
GITHUB_TOKEN="your_personal_access_token"

# リポジトリの一覧を取得
echo "Fetching repositories from $OLD_ORG..."
REPO_LIST=$(gh repo list $OLD_ORG --limit 200 --json name -q ".[].name")

# クローン & 新Organizationへプッシュ
mkdir -p migration && cd migration

for REPO in $REPO_LIST; do
    echo "Cloning repository: $REPO"
    gh repo clone "$OLD_ORG/$REPO" -- --mirror

    echo "Creating repository in $NEW_ORG: $REPO"
    gh repo create "$NEW_ORG/$REPO" --private

    echo "Pushing to $NEW_ORG..."
    cd "$REPO.git"
    git remote set-url origin "https://github.com/$NEW_ORG/$REPO.git"
    git push --mirror
    cd ..
done

echo "✅ リポジトリ移行完了！"
