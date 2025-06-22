#!/bin/bash

# create-worktree.sh - 指定されたリポジトリからGit worktree環境を作成
# 使用方法: ./create-worktree.sh <project-name> <worker-id>

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-scripts/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "create-worktree.sh" "
  ./create-worktree.sh <project-name> <worker-id>

引数:
  project-name      プロジェクト名
  worker-id         Worker ID (worker1, worker2, worker3)

例:
  ./create-worktree.sh user-auth-system worker1
  ./create-worktree.sh sample-project worker2"
}

# Git worktree環境を作成
create_worktree() {
    local project_name="$1"
    local worker_id="$2"
    
    # 引数チェック
    if [[ -z "$project_name" || -z "$worker_id" ]]; then
        print_error "プロジェクト名とWorker IDが必要です"
        usage
        cleanup_script 1
    fi
    
    # Worker IDの妥当性チェック
    if [[ ! "$worker_id" =~ ^worker[1-3]$ ]]; then
        print_error "Worker IDは worker1, worker2, worker3 のいずれかである必要があります"
        cleanup_script 1
    fi
    
    local project_dir="$SCRIPT_DIR/tasks/$project_name"
    local project_json="$project_dir/project.json"
    
    # プロジェクトの存在確認
    if [[ ! -d "$project_dir" ]]; then
        print_error "プロジェクト '$project_name' が存在しません"
        print_info "まず './setup-project.sh create $project_name <source-repo-path>' を実行してください"
        cleanup_script 1
    fi
    
    # project.jsonの存在確認
    if [[ ! -f "$project_json" ]]; then
        print_error "project.json が見つかりません: $project_json"
        cleanup_script 1
    fi
    
    # project.jsonから元のリポジトリパスと親ブランチを取得
    local source_repo_path
    local parent_branch
    
    if command -v jq &> /dev/null; then
        source_repo_path=$(jq -r '.source_repo_path // empty' "$project_json")
        parent_branch=$(jq -r '.parent_branch // empty' "$project_json")
    else
        # jqがない場合の簡易パース
        source_repo_path=$(grep -o '"source_repo_path"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" | sed 's/.*"source_repo_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        parent_branch=$(grep -o '"parent_branch"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" | sed 's/.*"parent_branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    if [[ -z "$source_repo_path" ]]; then
        print_error "project.jsonにsource_repo_pathが設定されていません"
        cleanup_script 1
    fi
    
    if [[ -z "$parent_branch" ]]; then
        parent_branch="main"
        print_warning "親ブランチが設定されていません。mainを使用します"
    fi
    
    # 元のリポジトリの存在確認
    if [[ ! -d "$source_repo_path/.git" ]]; then
        print_error "元のリポジトリが見つかりません: $source_repo_path"
        cleanup_script 1
    fi
    
    print_info "元のリポジトリ: $source_repo_path"
    print_info "親ブランチ: $parent_branch"
    
    local worker_dir="$project_dir/worktree/$worker_id"
    local branch_name="${project_name}-${worker_id}"
    
    print_info "Worker '$worker_id' のGit worktree環境を構築しています..."
    print_info "プロジェクト: $project_name"
    print_info "作業ブランチ: $branch_name"
    print_info "作業ディレクトリ: $worker_dir"
    
    # 既存のworktreeディレクトリをチェック
    if [[ -d "$worker_dir" ]]; then
        # ディレクトリが空でない場合は確認
        if [[ -n "$(ls -A "$worker_dir" 2>/dev/null)" ]]; then
            print_warning "作業ディレクトリ '$worker_dir' は既に存在し、ファイルが含まれています"
            read -p "既存の内容を削除して再作成しますか？ (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # 既存のworktreeを削除（元のリポジトリから）
                (cd "$source_repo_path" && git worktree remove "$worker_dir" --force 2>/dev/null) || true
                rm -rf "$worker_dir"
            else
                print_info "作業をキャンセルしました"
                cleanup_script 0
            fi
        else
            # 空のディレクトリの場合は削除
            rmdir "$worker_dir" 2>/dev/null || true
        fi
    fi
    
    # 元のリポジトリに移動してworktreeを作成
    cd "$source_repo_path"
    
    # 親ブランチの存在確認
    if ! git show-ref --verify --quiet "refs/heads/$parent_branch"; then
        print_error "親ブランチ '$parent_branch' が存在しません"
        cleanup_script 1
    fi
    
    # ブランチが既に存在する場合の処理
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        print_warning "ブランチ '$branch_name' は既に存在します"
        read -p "既存のブランチを削除して再作成しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git branch -D "$branch_name"
        else
            print_info "既存のブランチを使用します"
        fi
    fi
    
    # Git worktreeを作成
    if git worktree add "$worker_dir" -b "$branch_name" "$parent_branch"; then
        print_success "Git worktreeの作成が完了しました"
    else
        print_error "Git worktreeの作成に失敗しました"
        cleanup_script 1
    fi
    
    # 作業ディレクトリに移動してREADME.mdを作成
    cd "$worker_dir"
    
    # Worker用README作成
    cat > README.md << EOF
# $worker_id 作業ディレクトリ

## プロジェクト情報
- **プロジェクト名**: $project_name
- **Worker ID**: $worker_id
- **作業ブランチ**: $branch_name
- **親ブランチ**: $parent_branch
- **元のリポジトリ**: $source_repo_path
- **作成日時**: $(date)

## 作業手順
1. \`../task.md\` を確認してタスク内容を理解
2. あなた独自のアプローチでタスクを実装
3. 実装結果をこのディレクトリに保存
4. 作業完了後、結果を報告

## Git情報
- **現在のブランチ**: $(git branch --show-current)
- **最新コミット**: $(git log --oneline -1)

## 注意事項
- このディレクトリは $worker_id 専用です
- 他のWorkerのディレクトリは変更しないでください
- 作業内容は適切にコミットしてください
EOF
    
    # 初期コミット
    git add README.md
    git commit -m "$worker_id: 初期環境構築完了"
    
    print_success "Git worktree環境の構築が完了しました！"
    
    print_info "作業環境情報:"
    print_info "  📁 作業ディレクトリ: $worker_dir"
    print_info "  🌿 作業ブランチ: $branch_name"
    print_info "  🌿 親ブランチ: $parent_branch"
    print_info "  📂 元のリポジトリ: $source_repo_path"
    print_info "  📄 タスクファイル: $project_dir/task.md"
    
    print_info "次のステップ:"
    print_info "  1. cd $worker_dir"
    print_info "  2. cat ../task.md  # タスク内容を確認"
    print_info "  3. あなた独自のアプローチでタスクを実装"
    
    print_info "Git worktree一覧:"
    cd "$source_repo_path"
    git worktree list | grep -E "($(basename "$worker_dir")|$(dirname "$worker_dir"))" || git worktree list
}

# メイン処理
main() {
    # スクリプト初期化
    init_script "create-worktree.sh"
    
    # 引数チェック
    if [[ $# -lt 2 ]]; then
        usage
        cleanup_script 1
    fi
    
    # ヘルプ表示
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        usage
        cleanup_script 0
    fi
    
    # Git worktree環境を作成
    create_worktree "$1" "$2"
    
    cleanup_script 0
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
