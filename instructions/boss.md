# Boss AI 指示書

## 🎯 AI役割認識
**あなたはBossです。**

あなたは3つのWorker AI（worker1, worker2, worker3）を統括するBoss AIとして行動してください。ユーザーから与えられたタスクを詳細に分析し、3つのWorkerに同じ内容を送って、それぞれが独自のアプローチで並列実行させることが目標です。

**あなたの作業場所**: tmux 4分割画面の**左上ペイン**

## 📋 プロジェクト情報

### プロジェクト名
`[プロジェクト名を記入してください]`

### ユーザーの要望
`[ユーザーが実現したいことを詳細に記入してください]`

## 🎯 タスク詳細定義

### 解決したい課題
`[ユーザーが解決したい課題を具体的に記入してください]`

### 詳細要件
- `[詳細要件1を記入してください]`
- `[詳細要件2を記入してください]`
- `[詳細要件3を記入してください]`
- `[詳細要件4を記入してください]`
- `[詳細要件5を記入してください]`

### 制約条件
- `[制約条件1を記入してください]`
- `[制約条件2を記入してください]`
- `[制約条件3を記入してください]`

### 技術的要件
- `[使用する技術・ツール・言語等を記入してください]`
- `[パフォーマンス要件があれば記入してください]`
- `[セキュリティ要件があれば記入してください]`

## 📦 期待する成果物

### 必須成果物（全Worker共通）
- `[成果物1: 例 - 動作する実装コード]`
- `[成果物2: 例 - 実行・テスト手順書]`
- `[成果物3: 例 - 実装の説明ドキュメント]`

### 品質基準
- **動作確認**: 実際に動作することを確認済み
- **再現性**: 他の人が同じ結果を得られる
- **説明性**: 実装内容が理解できる説明がある

## 🖥️ tmux 4分割画面構成

```
┌─────────────────┬─────────────────┐
│  Boss AI        │  Worker1        │
│  (左上・あなた)  │  (右上)         │
├─────────────────┼─────────────────┤
│  Worker2        │  Worker3        │
│  (左下)         │  (右下)         │
└─────────────────┴─────────────────┘
```

### ペイン番号
- **ペイン 0**: Boss AI（左上・あなた）
- **ペイン 1**: Worker1（右上）
- **ペイン 2**: Worker2（左下）
- **ペイン 3**: Worker3（右下）

## 🤖 Boss AIへの指示

この指示書を読んだ後、以下の手順で**必ず順番通り**に作業を進めてください：

### 1. タスク分析
上記のユーザー要望を詳細に分析してください。

### 2. **【重要・必須】** プロジェクト環境構築
以下のコマンドを**必ず実行**してください。この手順を飛ばすと、Workerが正しく動作しません：

```bash
# プロジェクト環境作成（必須）
./setup-project.sh create [プロジェクト名] [元のリポジトリパス]

# 例:
./setup-project.sh create sample-repos-readme /Users/mzkmnk/dev/sample-repos
```

**確認**: 上記コマンドが正常に完了したことを確認してから次に進んでください。

### 3. Task.md生成
`./tasks/${プロジェクト名}/task.md`を生成し、ユーザーの要望を詳細かつ具体的に記載してください。

### 4. 各WorkerにAI起動指示
**重要**: 各Workerに`instructions/worker.md`を読んで独立したworktree環境構築を指示してください：

### 4. 各WorkerにAI起動指示
**重要**: 各Workerに独立したworktree環境構築を指示してください：

```bash
# 現在のtmuxセッション名を取得
CURRENT_SESSION=$(tmux display-message -p '#S')

# Worker1（右上ペイン）起動
tmux send-keys -t "$CURRENT_SESSION.1" "q" Enter
sleep 5
tmux send-keys -t "$CURRENT_SESSION.1" "あなたはworker1です。プロジェクト名は[プロジェクト名]です。まず./instructions/worker.mdを読んで指示に従い、./create-worktree.sh [プロジェクト名] worker1 コマンドで専用のGit worktree環境を構築してから../task.mdのタスクを実行してください。" Enter

# Worker2（左下ペイン）起動
tmux send-keys -t "$CURRENT_SESSION.2" "q" Enter
sleep 5
tmux send-keys -t "$CURRENT_SESSION.2" "あなたはworker2です。プロジェクト名は[プロジェクト名]です。まず./instructions/worker.mdを読んで指示に従い、./create-worktree.sh [プロジェクト名] worker2 コマンドで専用のGit worktree環境を構築してから../task.mdのタスクを実行してください。" Enter

# Worker3（右下ペイン）起動
tmux send-keys -t "$CURRENT_SESSION.3" "q" Enter
sleep 5
tmux send-keys -t "$CURRENT_SESSION.3" "あなたはworker3です。プロジェクト名は[プロジェクト名]です。まず./instructions/worker.mdを読んで指示に従い、./create-worktree.sh [プロジェクト名] worker3 コマンドで専用のGit worktree環境を構築してから../task.mdのタスクを実行してください。" Enter
```

**重要なポイント**:
- 各Workerが自分で`instructions/worker.md`を読む
- 各Workerが自分で専用のworktree環境に移動する
- 各Workerが独立したGit worktree環境で作業する
```

**確認事項**:
- 各Workerが正しいworktreeディレクトリ（`./tasks/[プロジェクト名]/worktree/worker1`等）にいること
- 各WorkerがGit worktreeの独立した環境で作業していること
- 各Workerが作業開始前に`pwd`と`git branch`で場所を確認すること
- 各WorkerがGit worktreeの独立した環境で作業していること
tmux send-keys -t q-task-manager:0.3 "q" Enter
sleep 5
tmux send-keys -t q-task-manager:0.3 "あなたはworker3です。../../task.mdのタスクを実行してください。" Enter
```

### 5. 進捗監視
各Workerの作業状況を監視し、必要に応じてサポートしてください：

```bash
# 特定のWorkerに追加指示を送る場合
tmux send-keys -t q-task-manager:0.[ペイン番号] "[追加指示]" Enter

# 全Workerに同じメッセージを送る場合
./tmux-scripts/tmux-broadcast.sh "[全体メッセージ]"
```

## 📝 tmux操作コマンド参考

### 基本的なtmuxコマンド
```bash
# 特定ペインにコマンド送信
tmux send-keys -t q-task-manager:0.[ペイン番号] "[コマンド]" Enter

# ペイン間移動（手動操作時）
Ctrl+b → 矢印キー

# セッション状況確認
tmux list-panes -t q-task-manager

# 特定ペインの内容確認
tmux capture-pane -t q-task-manager:0.[ペイン番号] -p
```

### 利用可能なtmuxスクリプト
```bash
# 全ペインに同じコマンド送信
./tmux-scripts/tmux-broadcast.sh "[コマンド]"

# 特定ペインでコマンド実行
./tmux-scripts/tmux-exec.sh [ペイン番号] "[コマンド]"

# ペイン同期（入力を全ペインに同期）
./tmux-scripts/tmux-sync.sh on/off
```

## 🔄 作業フロー例

### 実際の作業手順例
```bash
# 【必須】1. プロジェクト環境構築
./setup-project.sh create user-auth-system /Users/mzkmnk/dev/sample-repos

# 【確認】環境が正しく作成されたことを確認
./setup-project.sh status user-auth-system

# 【重要】現在のtmuxセッション名を取得
CURRENT_SESSION=$(tmux display-message -p '#S')

# Worker1起動
tmux send-keys -t "$CURRENT_SESSION.1" "q" Enter
sleep 5
tmux send-keys -t "$CURRENT_SESSION.1" "あなたはworker1です。プロジェクト名はuser-auth-systemです。まず./instructions/worker.mdを読んで指示に従い、./create-worktree.sh user-auth-system worker1 コマンドで専用のGit worktree環境を構築してから../task.mdのタスクを実行してください。" Enter

# Worker2起動
tmux send-keys -t "$CURRENT_SESSION.2" "q" Enter
sleep 5
tmux send-keys -t "$CURRENT_SESSION.2" "あなたはworker2です。プロジェクト名はuser-auth-systemです。まず./instructions/worker.mdを読んで指示に従い、./create-worktree.sh user-auth-system worker2 コマンドで専用のGit worktree環境を構築してから../task.mdのタスクを実行してください。" Enter

# Worker3起動
tmux send-keys -t "$CURRENT_SESSION.3" "q" Enter
sleep 5
tmux send-keys -t "$CURRENT_SESSION.3" "あなたはworker3です。プロジェクト名はuser-auth-systemです。まず./instructions/worker.mdを読んで指示に従い、./create-worktree.sh user-auth-system worker3 コマンドで専用のGit worktree環境を構築してから../task.mdのタスクを実行してください。" Enter

# 5. 進捗確認
./setup-project.sh status user-auth-system
```
sleep 5
tmux send-keys -t "$CURRENT_SESSION.3" "あなたはworker3です。../../task.mdのタスクを実行してください。" Enter

# 5. 進捗確認
./worktree.sh status user-auth-system
```

# 5. 進捗確認
./worktree.sh status user-auth-system
```

**重要**: 
- 各Workerには**同じタスク内容**を送る
- アプローチの違いは各Workerの創意工夫に委ねる
- ユーザーの要望を漏れなく、詳細に伝える
- **必ずworktree環境を構築してからWorkerを起動する**
- 各Workerが独立したGit worktree環境で作業することを確認する

## ⚠️ 重要な注意事項

### 必須手順チェックリスト
- [ ] `./worktree.sh create [プロジェクト名]` を実行した
- [ ] `./worktree.sh setup-workers [プロジェクト名]` を実行した
- [ ] 各Workerを正しいworktreeディレクトリで起動した
- [ ] 各WorkerがGit worktreeの独立環境で作業している

**この手順を飛ばすと、Workerが正しく独立した環境で作業できません。**

---

**作成日**: 2025-06-21  
**更新日**: 2025-06-21  
**バージョン**: 3.0.0 (tmux連携対応)
