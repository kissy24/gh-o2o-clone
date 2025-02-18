#!/bin/bash

# ============ 設定 =============
OLD_ORG="old-org"
NEW_ORG="new-org"
PER_PAGE=100  # 1回のAPI取得数（最大100件）

echo "Fetching repositories..."
REPO_LIST=$(gh repo list "$OLD_ORG" --limit 200 --json name -q ".[].name")

for REPO in $REPO_LIST; do
    echo "Migrating Issues & PRs for: $REPO"

    # ====== ISSUE & PR の総数を取得し、最終ページを計算 ======
    TOTAL_ISSUES=$(gh api "repos/$OLD_ORG/$REPO/issues?state=all&per_page=1" -q "length")
    LAST_PAGE=$(( (TOTAL_ISSUES + PER_PAGE - 1) / PER_PAGE ))  # 総ページ数を計算

    # ====== ISSUE の移行 (最終ページから取得) ======
    PAGE=$LAST_PAGE
    while [[ $PAGE -ge 1 ]]; do
        RESPONSE=$(gh api "repos/$OLD_ORG/$REPO/issues?state=all&per_page=$PER_PAGE&page=$PAGE" | jq -c '.')

        ISSUE_COUNT=$(echo "$RESPONSE" | jq 'length')
        if [[ "$ISSUE_COUNT" -eq 0 ]]; then
            break
        fi

        echo "$RESPONSE" | jq -c '.[]' | while read -r issue; do
            ISSUE_NUMBER=$(echo "$issue" | jq -r '.number')
            TITLE=$(echo "$issue" | jq -r '.title')
            BODY=$(echo "$issue" | jq -r '.body')
            STATE=$(echo "$issue" | jq -r '.state')
            USER=$(echo "$issue" | jq -r '.user.login')

            # === 投稿者名を追加して Markdown の改行を維持 ===
            BODY="**Original author: @$USER**\n\n$BODY"

            # PR か Issue かを判別 (PRは `.pull_request` フィールドが存在)
            if echo "$issue" | jq -e 'has("pull_request")' >/dev/null; then
                # ==== Pull Request の移行 ====
                BASE_BRANCH="main"  # デフォルトのブランチ (適宜修正)
                HEAD_BRANCH="migrated-pr-$ISSUE_NUMBER"

                gh pr create -R "$NEW_ORG/$REPO" --title "$TITLE" --body "$BODY" --base "$BASE_BRANCH" --head "$HEAD_BRANCH"
                echo "✅ Migrated PR: #$ISSUE_NUMBER → New PR"

            else
                # ==== Issue の移行 ====
                NEW_ISSUE_OUTPUT=$(gh issue create -R "$NEW_ORG/$REPO" --title "$TITLE" --body "$BODY")
                NEW_ISSUE_NUMBER=$(echo "$NEW_ISSUE_OUTPUT" | grep -oE '[0-9]+$')

                if [[ -z "$NEW_ISSUE_NUMBER" ]]; then
                    echo "⚠️ Issue creation failed for #$ISSUE_NUMBER"
                    continue
                fi
                echo "✅ Migrated Issue: #$ISSUE_NUMBER → New Issue: #$NEW_ISSUE_NUMBER"

                # Closed の場合、移行後も Closed にする
                if [[ "$STATE" == "closed" ]]; then
                    gh issue close -R "$NEW_ORG/$REPO" "$NEW_ISSUE_NUMBER"
                    echo "Closed Issue: #$NEW_ISSUE_NUMBER"
                fi
            fi

            # === コメントの移行 ===
            COMMENT_PAGE=1
            while :; do
                COMMENTS=$(gh api "repos/$OLD_ORG/$REPO/issues/$ISSUE_NUMBER/comments?per_page=$PER_PAGE&page=$COMMENT_PAGE" | jq -c '.')

                COMMENT_COUNT=$(echo "$COMMENTS" | jq 'length')
                if [[ "$COMMENT_COUNT" -eq 0 ]]; then
                    break
                fi

                echo "$COMMENTS" | jq -c '.[]' | while read -r comment; do
                    COMMENT_BODY=$(echo "$comment" | jq -r '.body')
                    COMMENT_USER=$(echo "$comment" | jq -r '.user.login')

                    # === 投稿者名を追加して Markdown の改行を維持 ===
                    COMMENT_BODY="**Original author: @$COMMENT_USER**\n\n$COMMENT_BODY"

                    gh issue comment -R "$NEW_ORG/$REPO" "$NEW_ISSUE_NUMBER" -b "$COMMENT_BODY"
                done
                COMMENT_PAGE=$((COMMENT_PAGE + 1))
            done
        done

        PAGE=$((PAGE - 1))  # 最終ページから降順で取得
    done
done

echo "✅ Issues, PRs & Comments の移行完了！"
