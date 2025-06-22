#!/bin/bash

# tmux-session.sh - セッション管理
# 使用方法: ./tmux-session.sh <command> [options]

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "tmux-session.sh" "
  ./tmux-session.sh list
  ./tmux-session.sh info <session-name>
  ./tmux-session.sh switch <session-name>
  ./tmux-session.sh kill <session-name>
  ./tmux-session.sh rename <old-name> <new-name>
  ./tmux-session.sh clone <source-session> <new-session>

コマンド:
  list            全セッションを一覧表示
  info            セッションの詳細情報を表示
  switch          セッションを切り替え
  kill            セッションを終了
  rename          セッション名を変更
  clone           セッションを複製

例:
  ./tmux-session.sh list
  ./tmux-session.sh info my-session
  ./tmux-session.sh switch my-session
  ./tmux-session.sh kill old-session
  ./tmux-session.sh rename old-name new-name
  ./tmux-session.sh clone template-session new-project"
}

# 全セッションを一覧表示
list_sessions() {
    print_info "tmuxセッション一覧:"
    
    if ! tmux list-sessions 2>/dev/null; then
        print_info "アクティブなセッションはありません"
        return 0
    fi
    
    echo ""
    print_info "詳細情報:"
    tmux list-sessions -F "#{session_name}: #{session_windows} windows, created #{session_created_string}" 2>/dev/null | while read -r line; do
        print_info "  $line"
    done
}

# セッションの詳細情報を表示
show_session_info() {
    local session_name="$1"
    
    print_info "セッション '$session_name' の詳細情報:"
    
    # セッション基本情報
    local session_info
    session_info=$(tmux list-sessions -t "$session_name" -F "作成日時: #{session_created_string}, ウィンドウ数: #{session_windows}, アタッチ数: #{session_attached}")
    print_info "$session_info"
    
    echo ""
    print_info "ウィンドウ一覧:"
    tmux list-windows -t "$session_name" -F "  ウィンドウ #{window_index}: #{window_name} (#{window_panes} panes) #{?window_active,[active],}"
    
    echo ""
    print_info "ペイン一覧:"
    tmux list-panes -t "$session_name" -F "  ペイン #{pane_index}: #{pane_current_command} #{?pane_active,[active],} (#{pane_width}x#{pane_height})"
    
    # 現在のレイアウト
    echo ""
    local layout
    layout=$(tmux list-windows -t "$session_name" -F "#{window_layout}")
    print_info "現在のレイアウト: $layout"
}

# セッションを切り替え
switch_session() {
    local session_name="$1"
    
    print_info "セッション '$session_name' に切り替えます"
    
    if [[ -n "$TMUX" ]]; then
        # 既にtmux内にいる場合
        tmux switch-client -t "$session_name"
        print_success "セッションを切り替えました"
    else
        # tmux外にいる場合
        tmux attach-session -t "$session_name"
    fi
}

# セッションを終了
kill_session() {
    local session_name="$1"
    local force="$2"
    
    if [[ "$force" != "true" ]]; then
        print_warning "セッション '$session_name' を終了しようとしています"
        read -p "本当に終了しますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "キャンセルしました"
            return 0
        fi
    fi
    
    print_info "セッション '$session_name' を終了します"
    tmux kill-session -t "$session_name"
    print_success "セッションを終了しました"
}

# セッション名を変更
rename_session() {
    local old_name="$1"
    local new_name="$2"
    
    print_info "セッション名を変更します: '$old_name' → '$new_name'"
    
    # 新しい名前が既に存在するかチェック
    if tmux has-session -t "$new_name" 2>/dev/null; then
        print_error "セッション '$new_name' は既に存在します"
        return 1
    fi
    
    tmux rename-session -t "$old_name" "$new_name"
    print_success "セッション名を変更しました"
}

# セッションを複製
clone_session() {
    local source_session="$1"
    local new_session="$2"
    
    print_info "セッション '$source_session' を '$new_session' として複製します"
    
    # 新しいセッション名が既に存在するかチェック
    if tmux has-session -t "$new_session" 2>/dev/null; then
        print_error "セッション '$new_session' は既に存在します"
        return 1
    fi
    
    # ソースセッションの情報を取得
    local window_count
    window_count=$(tmux list-windows -t "$source_session" | wc -l)
    
    print_info "$window_count 個のウィンドウを複製します"
    
    # 新しいセッションを作成
    tmux new-session -d -s "$new_session"
    
    # 各ウィンドウを複製
    local window_index=0
    tmux list-windows -t "$source_session" -F "#{window_index} #{window_name}" | while read -r index name; do
        if [[ "$index" != "0" ]]; then
            # 新しいウィンドウを作成
            tmux new-window -t "$new_session:$index" -n "$name"
        else
            # 最初のウィンドウの名前を変更
            tmux rename-window -t "$new_session:0" "$name"
        fi
        
        # ペイン構成を複製
        local pane_count
        pane_count=$(tmux list-panes -t "$source_session:$index" | wc -l)
        
        if [[ "$pane_count" -gt 1 ]]; then
            # 複数ペインがある場合は分割を再現
            for ((i=1; i<pane_count; i++)); do
                tmux split-window -t "$new_session:$index"
            done
            
            # レイアウトを適用
            local layout
            layout=$(tmux list-windows -t "$source_session:$index" -F "#{window_layout}")
            tmux select-layout -t "$new_session:$index" "$layout"
        fi
    done
    
    print_success "セッションを複製しました"
}

# セッションの統計情報を表示
show_session_stats() {
    print_info "tmuxセッション統計:"
    
    local total_sessions
    total_sessions=$(tmux list-sessions 2>/dev/null | wc -l || echo "0")
    print_info "  総セッション数: $total_sessions"
    
    if [[ "$total_sessions" -gt 0 ]]; then
        local total_windows
        total_windows=$(tmux list-sessions -F "#{session_windows}" 2>/dev/null | awk '{sum+=$1} END {print sum}')
        print_info "  総ウィンドウ数: $total_windows"
        
        local total_panes
        total_panes=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | xargs -I {} tmux list-panes -t {} | wc -l)
        print_info "  総ペイン数: $total_panes"
        
        echo ""
        print_info "アクティブセッション:"
        tmux list-sessions -F "  #{session_name}: #{session_attached} clients attached" 2>/dev/null
    fi
}

# セッションをバックアップ
backup_session() {
    local session_name="$1"
    local backup_dir="${2:-$HOME/.tmux-backups}"
    
    mkdir -p "$backup_dir"
    
    local backup_file="$backup_dir/${session_name}_$(date +%Y%m%d_%H%M%S).backup"
    
    print_info "セッション '$session_name' をバックアップします"
    print_info "バックアップファイル: $backup_file"
    
    {
        echo "# tmux session backup: $session_name"
        echo "# Created: $(date)"
        echo ""
        
        # セッション情報
        echo "# Session info"
        tmux list-sessions -t "$session_name" -F "session_name=#{session_name}"
        echo ""
        
        # ウィンドウ情報
        echo "# Windows"
        tmux list-windows -t "$session_name" -F "window_index=#{window_index} window_name=#{window_name} window_layout=#{window_layout}"
        echo ""
        
        # ペイン情報
        echo "# Panes"
        tmux list-panes -t "$session_name" -F "pane_index=#{pane_index} pane_current_path=#{pane_current_path} pane_current_command=#{pane_current_command}"
        
    } > "$backup_file"
    
    print_success "バックアップを作成しました: $backup_file"
}

# メイン処理
main() {
    local command=""
    local session_name=""
    local target_name=""
    local force="false"
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                exit 0
                ;;
            --force|-f)
                force="true"
                shift
                ;;
            list|info|switch|kill|rename|clone|stats|backup)
                command="$1"
                shift
                ;;
            *)
                if [[ -z "$session_name" ]]; then
                    session_name="$1"
                elif [[ -z "$target_name" ]]; then
                    target_name="$1"
                else
                    print_error "不明な引数: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # コマンドのチェック
    if [[ -z "$command" ]]; then
        print_error "コマンドが必要です"
        usage
        exit 1
    fi
    
    # 事前チェック
    check_tmux || exit 1
    
    # コマンドに応じた処理
    case "$command" in
        list)
            list_sessions
            ;;
        info)
            if [[ -z "$session_name" ]]; then
                print_error "セッション名が必要です"
                exit 1
            fi
            check_session_exists "$session_name" || exit 1
            show_session_info "$session_name"
            ;;
        switch)
            if [[ -z "$session_name" ]]; then
                print_error "セッション名が必要です"
                exit 1
            fi
            check_session_exists "$session_name" || exit 1
            switch_session "$session_name"
            ;;
        kill)
            if [[ -z "$session_name" ]]; then
                print_error "セッション名が必要です"
                exit 1
            fi
            check_session_exists "$session_name" || exit 1
            kill_session "$session_name" "$force"
            ;;
        rename)
            if [[ -z "$session_name" || -z "$target_name" ]]; then
                print_error "旧セッション名と新セッション名が必要です"
                exit 1
            fi
            check_session_exists "$session_name" || exit 1
            rename_session "$session_name" "$target_name"
            ;;
        clone)
            if [[ -z "$session_name" || -z "$target_name" ]]; then
                print_error "ソースセッション名と新セッション名が必要です"
                exit 1
            fi
            check_session_exists "$session_name" || exit 1
            clone_session "$session_name" "$target_name"
            ;;
        stats)
            show_session_stats
            ;;
        backup)
            if [[ -z "$session_name" ]]; then
                print_error "セッション名が必要です"
                exit 1
            fi
            check_session_exists "$session_name" || exit 1
            backup_session "$session_name" "$target_name"
            ;;
        *)
            print_error "不明なコマンド: $command"
            usage
            exit 1
            ;;
    esac
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
