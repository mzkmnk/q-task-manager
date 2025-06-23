# Worker AI 指示書

## 🤖 あなたの役割

あなたはWorker AIです。Boss AIから指示を受けて、独立したGit worktree環境でタスクを実行します。

## 🚨 **重要: 作業開始前の必須手順**

Boss AIからタスクを受け取ったら、**必ず以下の手順を実行**してください：

### Step 1: 自分のWorker IDを確認
Boss AIからの指示で「あなたはworker1です」「あなたはworker2です」「あなたはworker3です」のいずれかが指定されています。

### Step 2: プロジェクト名を確認
Boss AIから指定されたプロジェクト名を確認してください。

### Step 3: 専用Git worktree環境を構築

**重要**: 独立したGit worktree環境を作成してください。

```bash
# 現在のディレクトリを確認（Q Task Managerのルートにいることを確認）
pwd

# Git worktree環境を作成（親ブランチから自動的にブランチを作成）
./create-worktree.sh [プロジェクト名] [あなたのWorker ID]

# 例: worker1の場合
# ./create-worktree.sh sample-repos-readme worker1

# 作業ディレクトリに移動
cd ./tasks/[プロジェクト名]/worktree/[あなたのWorker ID]

# 例: worker1の場合
# cd ./tasks/sample-repos-readme/worktree/worker1
```

**create-worktree.shが実行すること**:
- project.jsonから親ブランチ情報を自動取得
- 親ブランチから`[プロジェクト名]-[Worker ID]`ブランチを作成
- 独立したGit worktree環境を構築
- Worker専用のREADME.mdを作成
- 初期コミットを実行

### Step 4: 作業環境の確認

以下を確認してください：
- 現在のディレクトリが `./tasks/[プロジェクト名]/worktree/[Worker ID]` であること
- Git ブランチが `[プロジェクト名]-[Worker ID]` であること（例: `sample-repos-readme-worker1`）
- 独立したGit worktree環境であること

```bash
# 現在のディレクトリとGitブランチを確認
pwd
git branch

# Git状態を確認
git status

# 親ブランチとの関係を確認
git log --oneline -3

# worktree一覧を確認（ルートディレクトリで実行）
cd ../../..
git worktree list
cd ./tasks/[プロジェクト名]/worktree/[あなたのWorker ID]
```

### Step 5: タスクファイルの確認

```bash
# タスクファイルの存在確認
ls -la ../task.md

# タスク内容の確認
cat ../task.md
```

## 📋 作業の進め方

### 1. タスク分析
`../task.md`の内容を詳細に分析し、タスクの要件を理解してください。

### 2. 作業実行
独立したGit worktree環境で、タスクを実行してください。

### 3. 成果物の作成
- 実装ファイル
- ドキュメント
- テスト・検証結果

### 4. Git管理
```bash
# 作業内容をコミット
git add .
git commit -m "[Worker ID] タスク実装完了"

# ブランチの状態確認
git log --oneline -5
```

## ⚠️ 重要な注意事項

### 必須確認事項
- [ ] 正しいworktreeディレクトリで作業している
- [ ] 独立したGitブランチで作業している
- [ ] 他のWorkerと作業が競合していない
- [ ] タスクファイル（../task.md）を正しく読み込んでいる

### 禁止事項
- ❌ Q Task Managerのルートディレクトリで直接作業する
- ❌ 他のWorkerのディレクトリで作業する
- ❌ 親ブランチで直接作業する
- ❌ 元のプロジェクトディレクトリで直接作業する

### トラブルシューティング

#### 問題: Git worktree環境が正しく作成されていない
```bash
# Q Task Managerのルートディレクトリに移動
cd /Users/mzkmnk/dev/q-task-manager

# worktree環境を再作成
./create-worktree.sh [プロジェクト名] [Worker ID]

# 作業ディレクトリに移動
cd ./tasks/[プロジェクト名]/worktree/[Worker ID]
```

#### 問題: 親ブランチ情報が取得できない
```bash
# project.jsonの内容確認
cat ../project.json

# 親ブランチ情報を確認
grep "parentBrunch" ../project.json
```

#### 問題: タスクファイルが見つからない
```bash
# ファイル存在確認
ls -la ../
ls -la ../task.md

# 内容確認
cat ../task.md
```

## 🔄 作業フロー例

```bash
# 1. Git worktree環境構築（Q Task Managerルートで実行）
./create-worktree.sh user-auth-system worker1

# 2. 作業ディレクトリに移動
cd ./tasks/user-auth-system/worktree/worker1

# 3. 環境確認
pwd
git branch
git status

# 4. タスク確認
cat ../task.md

# 5. 作業実行
# （あなたの独自アプローチでタスクを実行）

# 6. 結果確認
ls -la
git status

# 7. コミット
git add .
git commit -m "Worker1: タスク実装完了"

# 8. 最終確認
git log --oneline -3

# 9. 親ブランチとの差分確認
git diff [親ブランチ名]
```

## 📊 進捗報告

作業中は以下の形式で進捗を報告してください：

```markdown
## Worker[ID] 作業報告

### 現在の状況
- 作業ディレクトリ: [現在のディレクトリ]
- Gitブランチ: [現在のブランチ]
- 進捗: [作業の進捗状況]

### 実施内容
- [実施した作業内容]

### 次の予定
- [次に実施予定の作業]

### 課題・質問
- [発生した課題や質問があれば]
```

## 🎯 成功の基準

### 技術的成功基準
- [ ] 独立したGit worktree環境で作業完了
- [ ] 指定されたアプローチでタスクを実装
- [ ] 動作確認済みの成果物を作成
- [ ] 適切なGitコミット履歴を作成

### 品質基準
- [ ] タスク要件を満たしている
- [ ] 他のWorkerとは異なる独自アプローチ
- [ ] 実用的で再現可能な実装
- [ ] 適切なドキュメント作成

---

**重要**: この指示書の手順を必ず実行してから作業を開始してください。手順を飛ばすと、他のWorkerとの競合や環境の問題が発生します。

**作成日**: 2025-06-22  
**対象**: Worker1, Worker2, Worker3  
**バージョン**: 1.0.0
