#!/bin/bash

# tmux-sync.sh - ペイン間でのファイル・ディレクトリ同期
# 使用方法: ./tmux-sync.sh <session-name> <source-pane> <target-pane> <path>

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "tmux-sync.sh" "
  ./tmux-sync.sh <session-name> <source-pane> <target-pane> <path>
  ./tmux-sync.sh <session-name> --sync-dirs <pane1,pane2,pane3> <directory>
  ./tmux-sync.sh <session-name> --watch <source-pane> <target-panes> <path>

引数:
  session-name    tmuxセッション名
  source-pane     同期元ペインID
  target-pane     同期先ペインID
  path            同期するパス

オプション:
  --sync-dirs     複数ペインのディレクトリを同期
  --watch         ファイル変更を監視して自動同期
  --exclude       除外するファイル/ディレクトリパターン
  --dry-run       実際の同期は行わず、実行予定の操作を表示

例:
  ./tmux-sync.sh my-session 0 1 \"/path/to/file.txt\"
  ./tmux-sync.sh my-session --sync-dirs 0,1,2 \"/project\"
  ./tmux-sync.sh my-session --watch 0 1,2,3 \"/src\" --exclude \"*.log,node_modules\""
}

# ペイン間でファイルを同期
sync_file() {
    local session_name="$1"
    local source_pane="$2"
    local target_pane="$3"
    local file_path="$4"
    local dry_run="$5"
    
    print_info "ファイル同期: ペイン $source_pane → ペイン $target_pane"
    print_debug "対象ファイル: $file_path"
    
    # ソースペインでファイルの存在確認
    local source_check_cmd="test -f \"$file_path\" && echo 'EXISTS' || echo 'NOT_EXISTS'"
    tmux send-keys -t "$session_name:$source_pane" "$source_check_cmd" Enter
    sleep 0.5
    
    # ファイルをコピー
    local copy_cmd="cp \"$file_path\" /tmp/tmux_sync_$(basename \"$file_path\")"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "[DRY-RUN] 実行予定: $copy_cmd"
        return 0
    fi
    
    # ソースペインでファイルを一時場所にコピー
    tmux send-keys -t "$session_name:$source_pane" "$copy_cmd" Enter
    sleep 0.5
    
    # ターゲットペインで一時ファイルを取得
    local restore_cmd="cp /tmp/tmux_sync_$(basename \"$file_path\") \"$file_path\""
    tmux send-keys -t "$session_name:$target_pane" "$restore_cmd" Enter
    
    print_success "ファイル同期が完了しました"
}

# ディレクトリを同期
sync_directory() {
    local session_name="$1"
    local source_pane="$2"
    local target_pane="$3"
    local dir_path="$4"
    local exclude_patterns="$5"
    local dry_run="$6"
    
    print_info "ディレクトリ同期: ペイン $source_pane → ペイン $target_pane"
    print_debug "対象ディレクトリ: $dir_path"
    
    # rsyncコマンドを構築
    local rsync_cmd="rsync -av"
    
    # 除外パターンを追加
    if [[ -n "$exclude_patterns" ]]; then
        IFS=',' read -ra patterns <<< "$exclude_patterns"
        for pattern in "${patterns[@]}"; do
            rsync_cmd="$rsync_cmd --exclude=\"$pattern\""
        done
    fi
    
    rsync_cmd="$rsync_cmd \"$dir_path/\" /tmp/tmux_sync_dir/"
    
    if [[ "$dry_run" == "true" ]]; then
        print_info "[DRY-RUN] 実行予定: $rsync_cmd"
        return 0
    fi
    
    # ソースペインでディレクトリを一時場所に同期
    tmux send-keys -t "$session_name:$source_pane" "mkdir -p /tmp/tmux_sync_dir" Enter
    tmux send-keys -t "$session_name:$source_pane" "$rsync_cmd" Enter
    sleep 1
    
    # ターゲットペインで一時ディレクトリから復元
    local restore_cmd="rsync -av /tmp/tmux_sync_dir/ \"$dir_path/\""
    tmux send-keys -t "$target_pane" "mkdir -p \"$dir_path\"" Enter
    tmux send-keys -t "$session_name:$target_pane" "$restore_cmd" Enter
    
    print_success "ディレクトリ同期が完了しました"
}

# 複数ペイン間でディレクトリを同期
sync_multiple_panes() {
    local session_name="$1"
    local dir_path="$2"
    local exclude_patterns="$3"
    local dry_run="$4"
    shift 4
    local panes=("$@")
    
    if [[ ${#panes[@]} -lt 2 ]]; then
        print_error "同期には最低2つのペインが必要です"
        return 1
    fi
    
    local source_pane="${panes[0]}"
    print_info "ソースペイン: $source_pane"
    print_info "ターゲットペイン: ${panes[*]:1}"
    
    # ソースペインから他の全ペインに同期
    for target_pane in "${panes[@]:1}"; do
        sync_directory "$session_name" "$source_pane" "$target_pane" "$dir_path" "$exclude_patterns" "$dry_run"
    done
}

# ファイル変更を監視して自動同期
watch_and_sync() {
    local session_name="$1"
    local source_pane="$2"
    local target_panes="$3"
    local watch_path="$4"
    local exclude_patterns="$5"
    
    print_info "ファイル監視を開始します"
    print_info "監視パス: $watch_path"
    print_info "ソースペイン: $source_pane"
    print_info "ターゲットペイン: $target_panes"
    
    # fswatch または inotify を使用してファイル変更を監視
    if command -v fswatch &> /dev/null; then
        print_info "fswatch を使用してファイル変更を監視します"
        
        fswatch -o "$watch_path" | while read -r; do
            print_info "ファイル変更を検出しました"
            
            IFS=',' read -ra targets <<< "$target_panes"
            for target in "${targets[@]}"; do
                if [[ -d "$watch_path" ]]; then
                    sync_directory "$session_name" "$source_pane" "$target" "$watch_path" "$exclude_patterns" "false"
                else
                    sync_file "$session_name" "$source_pane" "$target" "$watch_path" "false"
                fi
            done
        done
    else
        print_warning "fswatch が見つかりません。手動同期のみ利用可能です"
        print_info "macOS: brew install fswatch"
        print_info "Linux: apt-get install inotify-tools"
        return 1
    fi
}

# 現在のディレクトリを全ペインで同期
sync_current_directory() {
    local session_name="$1"
    local source_pane="$2"
    shift 2
    local target_panes=("$@")
    
    # ソースペインの現在のディレクトリを取得
    local current_dir_cmd="pwd"
    tmux send-keys -t "$session_name:$source_pane" "$current_dir_cmd" Enter
    sleep 0.5
    
    # 各ターゲットペインで同じディレクトリに移動
    for target_pane in "${target_panes[@]}"; do
        print_info "ペイン $target_pane のディレクトリを同期します"
        tmux send-keys -t "$session_name:$target_pane" "cd \$(tmux capture-pane -t $session_name:$source_pane -p | tail -1 | cut -d' ' -f1)" Enter
    done
    
    print_success "ディレクトリ同期が完了しました"
}

# メイン処理
main() {
    local session_name=""
    local source_pane=""
    local target_pane=""
    local path=""
    local exclude_patterns=""
    local dry_run="false"
    local sync_dirs="false"
    local watch_mode="false"
    local sync_panes=()
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                exit 0
                ;;
            --sync-dirs)
                sync_dirs="true"
                IFS=',' read -ra sync_panes <<< "$2"
                shift 2
                ;;
            --watch)
                watch_mode="true"
                shift
                ;;
            --exclude)
                exclude_patterns="$2"
                shift 2
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            *)
                if [[ -z "$session_name" ]]; then
                    session_name="$1"
                elif [[ -z "$source_pane" && "$sync_dirs" == "false" && "$watch_mode" == "false" ]]; then
                    source_pane="$1"
                elif [[ -z "$target_pane" && "$sync_dirs" == "false" && "$watch_mode" == "false" ]]; then
                    target_pane="$1"
                elif [[ -z "$path" ]]; then
                    path="$1"
                else
                    print_error "不明な引数: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 必須引数のチェック
    if [[ -z "$session_name" || -z "$path" ]]; then
        print_error "必須引数が不足しています"
        usage
        exit 1
    fi
    
    # 事前チェック
    check_tmux || exit 1
    check_session_exists "$session_name" || exit 1
    
    # 実行モードに応じた処理
    if [[ "$sync_dirs" == "true" ]]; then
        sync_multiple_panes "$session_name" "$path" "$exclude_patterns" "$dry_run" "${sync_panes[@]}"
    elif [[ "$watch_mode" == "true" ]]; then
        watch_and_sync "$session_name" "$source_pane" "$target_pane" "$path" "$exclude_patterns"
    else
        if [[ -z "$source_pane" || -z "$target_pane" ]]; then
            print_error "ソースペインとターゲットペインが必要です"
            usage
            exit 1
        fi
        
        check_pane_exists "$session_name" "$source_pane" || exit 1
        check_pane_exists "$session_name" "$target_pane" || exit 1
        
        if [[ -d "$path" ]]; then
            sync_directory "$session_name" "$source_pane" "$target_pane" "$path" "$exclude_patterns" "$dry_run"
        else
            sync_file "$session_name" "$source_pane" "$target_pane" "$path" "$dry_run"
        fi
    fi
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
