# Templates Directory

このディレクトリには、Q Task Managerで使用するテンプレートファイルが格納されています。

## 📁 テンプレートファイル

### `task-template.md`
- **用途**: 各プロジェクトの`task.md`生成用テンプレート
- **使用場所**: `setup-project.sh create`コマンド実行時
- **説明**: Worker AIが実行するタスクの定義書テンプレート

### `project-template.json`
- **用途**: 各プロジェクトの`project.json`生成用テンプレート
- **使用場所**: `setup-project.sh create`コマンド実行時
- **説明**: プロジェクト設定とWorker情報の管理ファイルテンプレート

## 🔧 プレースホルダー

### project-template.json
- `{{PROJECT_NAME}}` - プロジェクト名
- `{{CREATED_AT}}` - 作成日時（ISO 8601形式）
- `{{PARENT_BRUNCH}}` - 親ブランチ名
- `{{DESCRIPTION}}` - プロジェクト説明

### task-template.md
- `${PROJECT_NAME}` - プロジェクト名
- `${WORKER_ID}` - Worker ID（worker1, worker2, worker3）
- その他の変数（詳細はファイル内を参照）

## 📋 使用方法

テンプレートファイルは`setup-project.sh`によって自動的に使用されます：

```bash
./setup-project.sh create my-project
```

上記コマンド実行時に：
1. `task-template.md` → `./tasks/my-project/task.md`
2. `project-template.json` → `./tasks/my-project/project.json`
3. `./tasks/my-project/worktree/` ディレクトリを作成

各Worker用のディレクトリ（`worker1`, `worker2`, `worker3`）は、各Workerが`create-worktree.sh`を実行した際に作成されます。

## ⚠️ 注意事項

- テンプレートファイルを直接編集する場合は、プレースホルダーの形式を維持してください
- 新しいプロジェクト作成時にのみテンプレートが適用されます
- 既存プロジェクトには影響しません

---

**更新日**: 2025-06-22  
**バージョン**: 1.0.0
