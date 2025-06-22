#!/bin/bash

# cleanup-worktree.sh - プロジェクトのworktree環境をクリーンアップ
# 使用方法: ./cleanup-worktree.sh <project-name>

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-scripts/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "cleanup-worktree.sh" "
  ./cleanup-worktree.sh <project-name>        # 指定プロジェクトのworktreeをクリーンアップ
  ./cleanup-worktree.sh --all                 # 全プロジェクトのworktreeをクリーンアップ

引数:
  project-name    プロジェクト名

例:
  ./cleanup-worktree.sh sample-repos-readme-enhancement
  ./cleanup-worktree.sh --all"
}

# 指定プロジェクトのworktreeをクリーンアップ
cleanup_project_worktree() {
    local project_name="$1"
    local project_dir="$SCRIPT_DIR/tasks/$project_name"
    
    if [[ ! -d "$project_dir" ]]; then
        print_error "プロジェクト '$project_name' が存在しません"
        return 1
    fi
    
    print_info "プロジェクト '$project_name' のworktree環境をクリーンアップしています..."
    
    # Git環境の確認
    if ! git rev-parse --git-dir &>/dev/null; then
        print_error "Git環境ではありません"
        return 1
    fi
    
    local cleaned=false
    
    for worker in worker1 worker2 worker3; do
        local worker_dir="$project_dir/worktree/$worker"
        local branch_name="${project_name}-${worker}"
        
        # worktreeの削除
        if [[ -d "$worker_dir" ]]; then
            print_info "Worker '$worker' のworktreeを削除中..."
            git worktree remove "$worker_dir" --force 2>/dev/null || {
                print_warning "worktree削除に失敗: $worker_dir"
                # 強制的にディレクトリを削除
                rm -rf "$worker_dir" 2>/dev/null || true
            }
            cleaned=true
        fi
        
        # ブランチの削除（オプション）
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            read -p "ブランチ '$branch_name' も削除しますか？ (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git branch -D "$branch_name" 2>/dev/null || {
                    print_warning "ブランチ削除に失敗: $branch_name"
                }
                print_success "ブランチ '$branch_name' を削除しました"
            fi
        fi
    done
    
    # 空のworktreeディレクトリを削除
    if [[ -d "$project_dir/worktree" ]]; then
        rmdir "$project_dir/worktree" 2>/dev/null || true
    fi
    
    if [[ "$cleaned" == true ]]; then
        print_success "プロジェクト '$project_name' のworktreeクリーンアップが完了しました"
    else
        print_info "クリーンアップするworktreeが見つかりませんでした"
    fi
}

# 全プロジェクトのworktreeをクリーンアップ
cleanup_all_worktrees() {
    local tasks_dir="$SCRIPT_DIR/tasks"
    
    if [[ ! -d "$tasks_dir" ]]; then
        print_info "tasksディレクトリが存在しません"
        return 0
    fi
    
    print_warning "全プロジェクトのworktree環境をクリーンアップします"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "クリーンアップをキャンセルしました"
        return 0
    fi
    
    for project_dir in "$tasks_dir"/*; do
        if [[ -d "$project_dir" ]]; then
            local project_name=$(basename "$project_dir")
            cleanup_project_worktree "$project_name"
            echo
        fi
    done
    
    print_success "全プロジェクトのworktreeクリーンアップが完了しました"
}

# メイン処理
main() {
    # スクリプト初期化
    init_script "cleanup-worktree.sh"
    
    local project_name="$1"
    
    # ヘルプ表示
    if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then
        usage
        cleanup_script 0
    fi
    
    # 全クリーンアップ
    if [[ "$1" == "--all" ]]; then
        cleanup_all_worktrees
        cleanup_script 0
    fi
    
    # 指定プロジェクトのクリーンアップ
    cleanup_project_worktree "$project_name"
    
    cleanup_script 0
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
