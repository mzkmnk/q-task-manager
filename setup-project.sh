#!/bin/bash

# setup-project.sh - Boss AI専用プロジェクト環境構築ツール
# 使用方法: ./setup-project.sh <command> [args]

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-scripts/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "setup-project.sh" "
  ./setup-project.sh create <project-name> <source-repo-path>  # プロジェクト環境作成
  ./setup-project.sh status <project-name>                    # プロジェクト状況確認
  ./setup-project.sh list                                     # プロジェクト一覧
  ./setup-project.sh remove <project-name>                    # プロジェクト削除
  ./setup-project.sh cleanup <project-name>                   # worktreeクリーンアップ

引数:
  project-name        プロジェクト名
  source-repo-path    元のリポジトリのパス（絶対パスまたは相対パス）

例:
  ./setup-project.sh create user-auth-system /Users/mzkmnk/dev/sample-repos
  ./setup-project.sh create my-project ../my-repo
  ./setup-project.sh status user-auth-system
  ./setup-project.sh list"
}

# プロジェクト環境作成
create_project() {
    local base_project_name="$1"
    local source_repo_path="$2"
    
    if [[ -z "$base_project_name" ]]; then
        print_error "プロジェクト名が指定されていません"
        usage
        cleanup_script 1
    fi
    
    if [[ -z "$source_repo_path" ]]; then
        print_error "元のリポジトリパスが指定されていません"
        usage
        cleanup_script 1
    fi
    
    # タイムスタンプ付きプロジェクト名を生成
    local timestamp=$(date +"%Y%m%d%H%M%S")
    local project_name="${base_project_name}-${timestamp}"
    
    print_info "生成されたプロジェクト名: $project_name"
    
    # 元のリポジトリパスを絶対パスに変換
    if [[ "$source_repo_path" = /* ]]; then
        # 既に絶対パス
        source_repo_path="$source_repo_path"
    else
        # 相対パスを絶対パスに変換
        source_repo_path="$(cd "$source_repo_path" 2>/dev/null && pwd)"
        if [[ -z "$source_repo_path" ]]; then
            print_error "指定されたリポジトリパスが存在しません: $2"
            cleanup_script 1
        fi
    fi
    
    # 元のリポジトリがGitリポジトリかチェック（.gitディレクトリまたは.gitファイル）
    if [[ ! -d "$source_repo_path/.git" && ! -f "$source_repo_path/.git" ]]; then
        print_error "指定されたパスはGitリポジトリではありません: $source_repo_path"
        cleanup_script 1
    fi
    
    local project_dir="$SCRIPT_DIR/tasks/$project_name"
    
    if [[ -d "$project_dir" ]]; then
        print_warning "プロジェクト '$project_name' は既に存在します"
        return 0
    fi
    
    # プロジェクト構造をセットアップ
    setup_project_structure "$project_name" "$source_repo_path"
    
    print_success "プロジェクト '$project_name' の環境構築が完了しました"
    print_info "プロジェクトディレクトリ: $project_dir"
    print_info "元のリポジトリ: $source_repo_path"
    print_info "次のステップ: Boss AIからWorkerにタスクを指示してください"
}

# プロジェクトディレクトリ構造作成とファイル配置
setup_project_structure() {
    local project_name="$1"
    local source_repo_path="$2"
    local project_dir="$SCRIPT_DIR/tasks/$project_name"
    
    print_info "プロジェクト '$project_name' の環境を構築しています..."
    
    # プロジェクトディレクトリ構造作成（worktreeディレクトリのみ）
    mkdir -p "$project_dir/worktree"
    
    # task.mdテンプレートを配置
    cp "$SCRIPT_DIR/templates/task-template.md" "$project_dir/task.md"
    
    # 元のリポジトリから現在のブランチを取得
    local current_branch
    current_branch=$(cd "$source_repo_path" && git branch --show-current)
    if [[ -z "$current_branch" ]]; then
        current_branch="main"
    fi
    
    # project.jsonテンプレートを配置・置換
    if [[ -f "$SCRIPT_DIR/templates/project-template.json" ]]; then
        # テンプレートをコピーして変数を置換
        sed -e "s|{{PROJECT_NAME}}|$project_name|g" \
            -e "s|{{CREATED_AT}}|$(date -Iseconds)|g" \
            -e "s|{{PARENT_BRUNCH}}|$current_branch|g" \
            -e "s|{{SOURCE_REPO_PATH}}|$source_repo_path|g" \
            -e "s|{{DESCRIPTION}}|Boss AIによる並列タスク実行プロジェクト|g" \
            "$SCRIPT_DIR/templates/project-template.json" > "$project_dir/project.json"
    else
        # フォールバック: 従来の方式
        cat > "$project_dir/project.json" << EOF
{
  "name": "$project_name",
  "source_repo_path": "$source_repo_path",
  "parent_branch": "$current_branch",
  "created_at": "$(date -Iseconds)",
  "status": "created",
  "workers": {
    "worker1": {"status": "ready", "worktree": "./worktree/worker1"},
    "worker2": {"status": "ready", "worktree": "./worktree/worker2"},
    "worker3": {"status": "ready", "worktree": "./worktree/worker3"}
  }
}
EOF
    fi
    
    print_info "プロジェクト基本構造の作成が完了しました"
    print_info "各Worker用ディレクトリは create-worktree.sh で作成されます"
}

# プロジェクト状況確認
show_status() {
    local project_name="$1"
    
    if [[ -z "$project_name" ]]; then
        print_error "プロジェクト名が指定されていません"
        usage
        cleanup_script 1
    fi
    
    local project_dir="$SCRIPT_DIR/tasks/$project_name"
    
    if [[ ! -d "$project_dir" ]]; then
        print_error "プロジェクト '$project_name' が存在しません"
        cleanup_script 1
    fi
    
    print_info "プロジェクト '$project_name' の状況:"
    echo
    
    # プロジェクト設定表示
    if [[ -f "$project_dir/project.json" ]]; then
        echo "📋 プロジェクト設定:"
        cat "$project_dir/project.json" | grep -E '"name"|"created_at"|"status"' | sed 's/^/  /'
        echo
    fi
    
    # Worker状況表示
    echo "👥 Worker環境:"
    for worker in worker1 worker2 worker3; do
        local worker_dir="$project_dir/worktree/$worker"
        if [[ -d "$worker_dir" ]]; then
            local file_count=$(find "$worker_dir" -type f | wc -l | tr -d ' ')
            echo "  ✅ $worker: Git worktree作成済み ($file_count ファイル)"
        else
            echo "  ⏳ $worker: 未作成（create-worktree.sh で作成予定）"
        fi
    done
    echo
    
    # task.md存在確認
    if [[ -f "$project_dir/task.md" ]]; then
        echo "📄 タスク定義: 存在"
        local task_size=$(wc -l < "$project_dir/task.md" | tr -d ' ')
        echo "  サイズ: $task_size 行"
    else
        echo "📄 タスク定義: 未作成"
    fi
}

# プロジェクト一覧
list_projects() {
    local tasks_dir="$SCRIPT_DIR/tasks"
    
    if [[ ! -d "$tasks_dir" ]]; then
        print_info "プロジェクトはまだ作成されていません"
        return 0
    fi
    
    print_info "プロジェクト一覧:"
    echo
    
    local found=false
    for project_dir in "$tasks_dir"/*; do
        if [[ -d "$project_dir" ]]; then
            local project_name=$(basename "$project_dir")
            local status="不明"
            local created_at="不明"
            
            if [[ -f "$project_dir/project.json" ]]; then
                status=$(grep '"status"' "$project_dir/project.json" | sed 's/.*"status": "\([^"]*\)".*/\1/')
                created_at=$(grep '"created_at"' "$project_dir/project.json" | sed 's/.*"created_at": "\([^"]*\)".*/\1/')
            fi
            
            echo "  📁 $project_name"
            echo "     状態: $status"
            echo "     作成: $created_at"
            echo
            found=true
        fi
    done
    
    if [[ "$found" == false ]]; then
        print_info "プロジェクトはまだ作成されていません"
    fi
}

# プロジェクト削除
remove_project() {
    local project_name="$1"
    
    if [[ -z "$project_name" ]]; then
        print_error "プロジェクト名が指定されていません"
        usage
        cleanup_script 1
    fi
    
    local project_dir="$SCRIPT_DIR/tasks/$project_name"
    
    if [[ ! -d "$project_dir" ]]; then
        print_error "プロジェクト '$project_name' が存在しません"
        cleanup_script 1
    fi
    
    print_warning "プロジェクト '$project_name' を削除しようとしています"
    echo "削除対象: $project_dir"
    read -p "本当に削除しますか？ (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # プロジェクトディレクトリを削除
        rm -rf "$project_dir"
        print_success "プロジェクト '$project_name' を削除しました"
    else
        print_info "削除をキャンセルしました"
    fi
}

# メイン処理
main() {
    # スクリプト初期化
    init_script "setup-project.sh"
    
    local command="$1"
    shift
    
    case "$command" in
        "create")
            create_project "$@"
            ;;
        "status")
            show_status "$@"
            ;;
        "list")
            list_projects
            ;;
        "remove")
            remove_project "$@"
            ;;
        "cleanup")
            if [[ -f "$SCRIPT_DIR/cleanup-worktree.sh" ]]; then
                "$SCRIPT_DIR/cleanup-worktree.sh" "$@"
            else
                print_error "cleanup-worktree.sh が見つかりません"
                cleanup_script 1
            fi
            ;;
        "--help"|"-h"|"")
            usage
            ;;
        *)
            print_error "不明なコマンド: $command"
            usage
            cleanup_script 1
            ;;
    esac
    
    cleanup_script 0
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
