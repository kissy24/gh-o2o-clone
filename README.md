# gh-o2o-clone

Scripts for clones required for concurrent operations verification between GitHub Organizations.

## Organization Migration Procedures (Japanese)

### 1. 移行の全体設計

移行先のOrganizationを「移行元と並行稼働しながら構築」するため、以下の点を整理しておきます。

1. リポジトリ
    - どのリポジトリを移行するか
    - 移行方法（GitHubのリポジトリ転送機能 or Gitリポジトリの手動コピー）
    - 各リポジトリのアクセス権限の整理
2. メンバーとチーム
    - 移行元のチーム構成とその権限
    - 移行後のチーム構成（必要に応じて変更）
3. Organizationの設定
    - Webhooks, Secrets, Actions, Dependabot, Branch Protection Rules など
4. 並行稼働時の管理
    - 並行稼働期間中の変更の同期方法（例：双方向ミラーリング）
    - 完全移行時の手順

### 2. Organizationの作成と初期設定

1. GitHubで新しいOrganizationを作成
    - GitHubのOrganization作成ページから作成
    - Billing Planの確認（必要に応じて有料プランへ）
2. Organizationの設定を移行
    - Settings > Policies を確認し、移行元と同じポリシーに設定

### 3. リポジトリの移行

並行稼働のため、手動でGitリポジトリを移行する。並行稼働しながら移行する場合は、リポジトリをクローンして新Organizationにプッシュする形を取るのが無難です。

1. 移行元のリポジトリをローカルにクローン
    ```sh
    git clone --mirror https://github.com/old-org/repo-name.git
    cd repo-name.git
    ```
2. 新Organizationに新しいリポジトリを作成（空リポジトリ）
3. リモートを変更し、新Organizationにプッシュ
    ```sh
    git remote set-url origin https://github.com/new-org/repo-name.git
    git push --mirror
    ```

必要な設定を適用（Branches、Settings、Teams、CI/CDなど）

⚠ 注意点

- IssuesやPull RequestsはGitHub APIを使わないと移行できない（次の手順参照）
- .github/ 内の設定（Actions, Dependabot）を見直す

### 4. Issues・PR・Wikiの移行

GitHubはリポジトリ転送時にはIssues・PRを維持できますが、手動で移行する場合はGitHub APIを活用して移行します。

1. Issuesのエクスポート
    ```sh
    curl -H "Authorization: token GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/old-org/repo-name/issues" > issues.json
    ```
2. 新Organizationにインポート
    - gh CLIを使って新しいリポジトリにIssuesを作成
    - jq などを使って適切にフォーマット変換が必要

### 5. Teams・Permissionsの移行

GitHubにはTeamsを直接コピーする機能はないので、手動で設定する必要があります。

1. 移行元のチーム構成を確認（GitHub API推奨）
    ```sh
    curl -H "Authorization: token GITHUB_TOKEN" \
     "https://api.github.com/orgs/old-org/teams" > teams.json
    ```
2. 移行先Organizationにチームを作成
3. メンバーを追加
4. 各リポジトリの権限を再設定

### 6. GitHub Actions・CI/CDの移行

- .github/workflows/ 配下のファイルを新リポジトリにコピー
- Organization Secrets の設定を移行（手動）
- Self-hosted Runner を使用している場合、新Organizationに登録し直す

### 7. Webhooks・その他設定の移行

- Webhooksを新Organizationに設定し直す
- GitHub Appsの設定を確認
- Protected Branch Rules などを適用

### 8. 並行稼働中の同期

完全移行前に新Organizationのリポジトリと移行元のリポジトリを同期する必要がある場合、以下の方法を取る。

1. GitHub Actionsでミラーリング
    - git pull で移行元の最新を取得し、新Organizationに git push するスクリプトを設定
    - GitHub Actionsでの同期例
2. 双方向ミラーリング（重要な場合）
    - `git fetch && git push` を双方向で実行する仕組みを用意

### 9.完全移行と移行元のアーカイブ

- 一定期間の並行稼働後、移行元のOrganizationをリードオンリーにする
- 全リポジトリを削除 or アーカイブ（必要に応じて）
- メンバーへ通知を行い、移行完了
