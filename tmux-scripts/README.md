# tmux-scripts

tmux操作を自動化するためのスクリプト集。責務ごとに分離された設計により、保守性と再利用性を重視しています。

## 📁 スクリプト一覧

| スクリプト | 責務 | 主な機能 |
|-----------|------|----------|
| [tmux-utils.sh](#tmux-utilssh) | 共通ユーティリティ | カラー出力、エラーハンドリング、事前チェック |
| [tmux-exec.sh](#tmux-execsh) | コマンド実行 | 特定ペインでのコマンド実行、出力キャプチャ |
| [tmux-broadcast.sh](#tmux-broadcastsh) | 一括操作 | 全ペイン・選択ペインへのコマンド送信 |
| [tmux-sync.sh](#tmux-syncsh) | 同期操作 | ペイン間でのファイル・ディレクトリ同期 |
| [tmux-layout.sh](#tmux-layoutsh) | レイアウト管理 | ペイン分割、サイズ調整、レイアウト保存 |
| [tmux-session.sh](#tmux-sessionsh) | セッション管理 | セッション作成、複製、情報表示 |

## 🚀 クイックスタート

```bash
# 基本的な使用例
./tmux-exec.sh my-session 0 "ls -la"                    # ペイン0でコマンド実行
./tmux-broadcast.sh my-session "clear"                  # 全ペインをクリア
./tmux-layout.sh my-session tiled                       # 4分割レイアウト適用
./tmux-session.sh list                                  # セッション一覧表示
```

## 📖 各スクリプト詳細

### tmux-utils.sh
**共通ユーティリティ関数**

他のスクリプトから読み込んで使用する共通機能を提供。

**主な機能:**
- カラー出力関数（info, success, error, warning, debug）
- tmux/セッション/ペインの存在チェック
- エラーハンドリング
- 設定ファイル読み込み

**使用方法:**
```bash
# 他のスクリプトから読み込み
source "$(dirname "${BASH_SOURCE[0]}")/tmux-utils.sh"

# デバッグモード有効化
TMUX_DEBUG=1 ./any-script.sh
```

### tmux-exec.sh
**特定ペインでのコマンド実行**

指定したペインで任意のコマンドを実行し、必要に応じて出力をキャプチャ。

**基本構文:**
```bash
./tmux-exec.sh <session-name> <pane-id> "<command>" [options]
```

**オプション:**
- `--wait`: Enterキーを送信せず、コマンド入力のみ
- `--capture`: 実行後にペインの内容をキャプチャして表示

**使用例:**
```bash
./tmux-exec.sh my-session 0 "ls -la"
./tmux-exec.sh my-session 1 "cd /project && npm start" --wait
./tmux-exec.sh my-session 2 "git status" --capture
```

### tmux-broadcast.sh
**全ペインへのコマンド送信**

複数のペインに同じコマンドを一括送信。対象ペインの選択や除外も可能。

**基本構文:**
```bash
./tmux-broadcast.sh <session-name> "<command>" [options]
```

**オプション:**
- `--panes 0,1,2`: 特定のペインのみに送信
- `--exclude 3`: 指定ペインを除外
- `--wait`: Enterキーを送信しない
- `--delay 1`: ペイン間の実行間隔（秒）
- `--sync-on/--sync-off`: 同期モードの切り替え

**使用例:**
```bash
./tmux-broadcast.sh my-session "clear"                    # 全ペインをクリア
./tmux-broadcast.sh my-session "git pull" --panes 0,1,2  # ペイン0,1,2のみ
./tmux-broadcast.sh my-session "cd /project" --exclude 3 # ペイン3を除外
./tmux-broadcast.sh my-session "npm install" --delay 1   # 1秒間隔で実行
```

### tmux-sync.sh
**ペイン間でのファイル・ディレクトリ同期**

ペイン間でファイルやディレクトリを同期。ファイル変更の監視機能も提供。

**基本構文:**
```bash
./tmux-sync.sh <session-name> <source-pane> <target-pane> <path> [options]
```

**オプション:**
- `--sync-dirs <panes> <directory>`: 複数ペインのディレクトリを同期
- `--watch <source> <targets> <path>`: ファイル変更を監視して自動同期
- `--exclude "*.log,node_modules"`: 除外パターン指定
- `--dry-run`: 実行予定の操作を表示のみ

**使用例:**
```bash
./tmux-sync.sh my-session 0 1 "/path/to/file.txt"              # ファイル同期
./tmux-sync.sh my-session --sync-dirs 0,1,2 "/project"         # ディレクトリ同期
./tmux-sync.sh my-session --watch 0 1,2,3 "/src" --exclude "*.log"  # 監視同期
```

**必要なツール:**
- `fswatch` (macOS): `brew install fswatch`
- `inotify-tools` (Linux): `apt-get install inotify-tools`

### tmux-layout.sh
**レイアウト管理**

ペインのレイアウト変更、サイズ調整、分割操作を提供。カスタムレイアウトの保存・復元も可能。

**基本構文:**
```bash
./tmux-layout.sh <session-name> <layout> [options]
```

**レイアウト種類:**
- `tiled`: 4分割（2x2グリッド）
- `even-horizontal`: 水平均等分割
- `even-vertical`: 垂直均等分割
- `main-horizontal`: メイン画面＋水平分割
- `main-vertical`: メイン画面＋垂直分割

**オプション:**
- `--resize <pane> <direction> <size>`: ペインサイズ調整
- `--split <pane> <direction>`: ペイン分割
- `--save <name>`: 現在のレイアウトを保存
- `--restore <name>`: 保存されたレイアウトを復元
- `--list`: 保存されたレイアウト一覧
- `--info`: 現在のレイアウト情報表示

**使用例:**
```bash
./tmux-layout.sh my-session tiled                        # 4分割レイアウト
./tmux-layout.sh my-session --resize 0 right 10         # ペイン0を右に10拡張
./tmux-layout.sh my-session --split 0 horizontal        # ペイン0を水平分割
./tmux-layout.sh my-session --save my-layout            # レイアウト保存
./tmux-layout.sh my-session --restore my-layout         # レイアウト復元
```

### tmux-session.sh
**セッション管理**

tmuxセッションの作成、複製、情報表示、バックアップなどの管理機能を提供。

**基本構文:**
```bash
./tmux-session.sh <command> [options]
```

**コマンド:**
- `list`: 全セッション一覧表示
- `info <session>`: セッション詳細情報
- `switch <session>`: セッション切り替え
- `kill <session>`: セッション終了
- `rename <old> <new>`: セッション名変更
- `clone <source> <new>`: セッション複製
- `stats`: セッション統計情報
- `backup <session>`: セッションバックアップ

**オプション:**
- `--force`: 確認なしで実行

**使用例:**
```bash
./tmux-session.sh list                                   # セッション一覧
./tmux-session.sh info my-session                       # セッション詳細
./tmux-session.sh clone template-session new-project    # セッション複製
./tmux-session.sh kill old-session --force              # 強制終了
./tmux-session.sh backup my-session                     # バックアップ作成
```

## 🔧 環境変数

| 変数名 | 説明 | デフォルト |
|--------|------|-----------|
| `TMUX_DEBUG` | デバッグメッセージ表示 | 無効 |

**使用例:**
```bash
TMUX_DEBUG=1 ./tmux-exec.sh my-session 0 "ls"
```

## 📋 使用パターン

### 並列開発環境の構築
```bash
# 1. セッション作成（setup.shを使用）
../setup.sh project-name

# 2. 4分割レイアウト適用
./tmux-layout.sh project-name tiled

# 3. 全ペインで基本セットアップ
./tmux-broadcast.sh project-name "cd /project"

# 4. 各ペインで異なるアプローチを開始
./tmux-exec.sh project-name 0 "git checkout -b approach-1"
./tmux-exec.sh project-name 1 "git checkout -b approach-2"
./tmux-exec.sh project-name 2 "git checkout -b approach-3"

# 5. 必要に応じてファイル同期
./tmux-sync.sh project-name 0 1,2,3 "/project/config"
```

### 開発サーバーの一括起動
```bash
# 各ペインで異なるサーバーを起動
./tmux-exec.sh dev-session 0 "npm run dev"
./tmux-exec.sh dev-session 1 "npm run api"
./tmux-exec.sh dev-session 2 "npm run test:watch"
./tmux-exec.sh dev-session 3 "npm run storybook"
```

### レイアウトのカスタマイズと保存
```bash
# カスタムレイアウトを作成
./tmux-layout.sh my-session --split 0 horizontal
./tmux-layout.sh my-session --resize 0 right 20
./tmux-layout.sh my-session --split 2 vertical

# レイアウトを保存
./tmux-layout.sh my-session --save development-layout

# 他のセッションで復元
./tmux-layout.sh other-session --restore development-layout
```

## 🛠️ トラブルシューティング

### よくある問題と解決方法

**Q: セッションが見つからないエラーが出る**
```bash
# セッション一覧を確認
./tmux-session.sh list

# セッション名を正確に指定
./tmux-exec.sh "正確なセッション名" 0 "command"
```

**Q: ペインが存在しないエラーが出る**
```bash
# セッション情報を確認
./tmux-session.sh info my-session

# 存在するペインIDを使用
./tmux-exec.sh my-session 0 "command"  # 0から開始
```

**Q: デバッグ情報を確認したい**
```bash
# デバッグモードで実行
TMUX_DEBUG=1 ./tmux-exec.sh my-session 0 "command"
```

## 📝 開発者向け情報

### スクリプトの拡張方法

新しい機能を追加する場合：

1. **tmux-utils.sh**に共通機能を追加
2. 新しいスクリプトを作成し、`tmux-utils.sh`を読み込み
3. 適切なエラーハンドリングとヘルプ機能を実装
4. このREADMEを更新

### コーディング規約

- Bash strict mode (`set -e`) を使用
- 関数名は動詞_名詞形式
- エラーメッセージは具体的で解決方法を含む
- デバッグ情報は`print_debug`を使用
- ヘルプ機能は必須実装

## 📄 ライセンス

MIT License

---

**作成日**: 2025-06-21  
**バージョン**: 1.0.0  
**対応tmuxバージョン**: 2.0以上
