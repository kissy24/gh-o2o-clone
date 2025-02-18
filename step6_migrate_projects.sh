#!/bin/bash

# ============ 設定 =============
OLD_ORG="old-org"
NEW_ORG="new-org"

echo "Fetching projects from $OLD_ORG..."
PROJECTS=$(gh api "orgs/$OLD_ORG/projects" -q ".[].id")

for PROJECT_ID in $PROJECTS; do
    PROJECT_NAME=$(gh api "projects/$PROJECT_ID" -q ".name")
    echo "Migrating Project: $PROJECT_NAME"

    NEW_PROJECT_ID=$(gh api -X POST "orgs/$NEW_ORG/projects" \
        -F name="$PROJECT_NAME" \
        -q ".id")

    COLUMNS=$(gh api "projects/$PROJECT_ID/columns" -q ".[].id")
    for COLUMN_ID in $COLUMNS; do
        COLUMN_NAME=$(gh api "projects/columns/$COLUMN_ID" -q ".name")
        NEW_COLUMN_ID=$(gh api -X POST "projects/$NEW_PROJECT_ID/columns" \
            -F name="$COLUMN_NAME" \
            -q ".id")

        CARDS=$(gh api "projects/columns/$COLUMN_ID/cards" -q ".[].id")
        for CARD_ID in $CARDS; do
            CARD_NOTE=$(gh api "projects/columns/cards/$CARD_ID" -q ".note")
            if [[ -n "$CARD_NOTE" ]]; then
                gh api -X POST "projects/columns/$NEW_COLUMN_ID/cards" \
                    -F note="$CARD_NOTE"
            fi
        done
    done
done

echo "✅ Projects 移行完了！"
