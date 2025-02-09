# gh-o2o-clone

Scripts for clones required for concurrent operations verification between GitHub Organizations.

## Organization Migration Procedures (Japanese)

⚠ あくまで概要です。実手順は異なるかも

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
2. 新Organizationに新しいリポジトリを作成（空リポジトリ）
3. リモートを変更し、新Organizationにプッシュ

⚠ 注意点

- IssuesやPull RequestsはGitHub APIを使わないと移行できない（次の手順参照）
- .github/ 内の設定（Actions, Dependabot）を見直す

### 4. Issues・PR・Wikiの移行

GitHubはリポジトリ転送時にはIssues・PRを維持できますが、手動で移行する場合はGitHub APIを活用して移行します。

1. Issuesのエクスポート
2. 新Organizationにインポート
    - gh CLIを使って新しいリポジトリにIssuesを作成
    - jq などを使って適切にフォーマット変換が必要

### 5. Teams・Permissionsの移行

GitHubにはTeamsを直接コピーする機能はないので、手動で設定する必要があります。

1. 移行元のチーム構成を確認（GitHub API推奨）
2. 移行先Organizationにチームを作成
3. メンバーを追加
4. 各リポジトリの権限を再設定

### 6. GitHub Actions・CI/CDの移行

- .github/workflows/ 配下のファイルを新リポジトリにコピー
- Organization Secrets の設定を移行（手動）
- Self-hosted Runner を使用している場合、新Organizationに登録し直す

### 7. Projectsの移行

1. 移行元のOrganization/リポジトリからGitHub Projectsをエクスポート（JSON）
2. 移行先のOrganization/リポジトリにGitHub Projectsを作成
3. エクスポートしたデータをもとに、カラムやカード（IssueやNote）を再作成
4. 各カードのメタ情報（ラベル、担当者、ステータス）を再設定

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

## About Scripts (Japanese)

### GitHub Organization 移行スクリプト - できること & できないこと

| ステップ | 移行対象 | できること（✅） | できないこと（❌） | 備考 |
|----------|----------|-----------------|-----------------|------|
| **1. リポジトリ移行** | Git履歴（Branches・Tags・Commits） | ✅ 履歴を保持したまま移行 <br> ✅ 全リポジトリ一括ミラーリング | ❌ GitHub Secrets は移行不可 <br> ❌ Webhooks, Actions は別途対応 | GitHub CLI (`gh repo create` + `git push --mirror`) を使用 |
| **2. Issues・PR・Labels** | Issues・Pull Requests・Labels | ✅ Issues のタイトル・本文を保持 <br> ✅ PR のタイトル・本文を保持 <br> ✅ Labels を移行 | ❌ Issues・PR のコメントは移行不可 <br> ❌ PR のマージ履歴・ステータスは移行不可 | `gh api` で新リポジトリに再作成 |
| **3. Wiki** | Wiki（ドキュメント） | ✅ Wiki の履歴を保持したまま移行 | ❌ Wiki のコメントは移行不可 | `git clone --bare` でWikiの履歴を保持しつつ移行 |
| **4. Teams** | Teams・メンバー・権限 | ✅ Team の名前を保持 <br> ✅ Team の作成（空の状態） | ❌ メンバー・権限の自動移行不可（手動追加が必要） | `gh api` でTeamのみ作成、メンバー追加は手動対応 |
| **5. GitHub Actions** | ActionsのSecrets・Workflows | ✅ `.github/workflows/` を移行（手動コピー） | ❌ Secrets は移行不可（手動登録が必要） <br> ❌ Self-hosted Runner の設定は移行不可 | `gh api` でSecretsを取得し、手動で設定 |
| **6. GitHub Projects** | カンバン（ボード・カラム・カード） | ✅ カンバンの名前を保持 <br> ✅ カラム（To Do, In Progress, Doneなど）を移行 <br> ✅ カード（Issue, Note）を移行 | ❌ カードのコメント・履歴は移行不可 <br> ❌ 自動ルール（Automation）は移行不可 | `gh api` を使用し、ボード・カラム・カードを新プロジェクトに作成 |

### 補足

✅ 完全に移行できるもの

- **リポジトリのGit履歴**（Branches, Tags, Commits）
- **GitHub Projectsのカラム・カード**
- **Issues・PRのタイトル・本文**
- **Wikiの履歴**
- **Labels**
- **GitHub ActionsのWorkflows（手動コピー）**

❌ 手動対応が必要なもの

- **GitHub ActionsのSecrets**（セキュリティ上の制約）
- **Issues・PRのコメント**
- **Projectsの自動ルール（Automation）**
- **PRのマージ履歴・ステータス**
- **Teamsのメンバー・権限**

### おすすめの進め方

1. **リポジトリ移行（ステップ1）をまずテスト**
2. **小規模なプロジェクトで GitHub Projects・Issues・Wiki の移行を試す**
3. **手動対応が必要な箇所（Secrets・Teams・Actions）を整理**
4. **本番環境での移行を計画（事前に通知＆並行稼働期間を設定）**

GitHubの制約上 **完全自動化は難しい部分もあるため、APIで可能な範囲をスクリプトで処理し、細かい調整は手動で対応** するのが現実的です。  
まずはテスト環境で **1つのリポジトリを対象に試して**、問題点を確認しながら進めることをおすすめします！ 🚀
