#!/bin/bash

# tmux-exec.sh - 特定ペインでのコマンド実行
# 使用方法: ./tmux-exec.sh <session-name> <pane-id> "<command>"

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "tmux-exec.sh" "
  ./tmux-exec.sh <session-name> <pane-id> \"<command>\"
  ./tmux-exec.sh <session-name> <pane-id> \"<command>\" [--wait]
  ./tmux-exec.sh <session-name> <pane-id> \"<command>\" [--capture]

引数:
  session-name    tmuxセッション名
  pane-id         ペインID (0, 1, 2, 3...)
  command         実行するコマンド

オプション:
  --wait          コマンド実行後にEnterキーを送信しない
  --capture       コマンド実行後にペインの内容をキャプチャして表示

例:
  ./tmux-exec.sh my-session 0 \"ls -la\"
  ./tmux-exec.sh my-session 1 \"cd /path/to/project && npm start\" --wait
  ./tmux-exec.sh my-session 2 \"git status\" --capture"
}

# コマンドを特定のペインで実行
execute_command() {
    local session_name="$1"
    local pane_id="$2"
    local command="$3"
    local send_enter="${4:-true}"
    
    print_info "セッション '$session_name' のペイン $pane_id でコマンドを実行します"
    print_debug "実行コマンド: $command"
    
    # コマンドを送信
    tmux send-keys -t "$session_name:$pane_id" "$command"
    
    # Enterキーを送信（--waitオプションがない場合）
    if [[ "$send_enter" == "true" ]]; then
        tmux send-keys -t "$session_name:$pane_id" Enter
        print_success "コマンドを実行しました"
    else
        print_success "コマンドを送信しました（実行待ち）"
    fi
}

# ペインの内容をキャプチャ
capture_pane() {
    local session_name="$1"
    local pane_id="$2"
    
    print_info "ペイン $pane_id の内容をキャプチャします"
    
    # 少し待ってからキャプチャ（コマンド実行完了を待つ）
    sleep 1
    
    local output
    output=$(tmux capture-pane -t "$session_name:$pane_id" -p)
    
    echo "--- ペイン $pane_id の出力 ---"
    echo "$output"
    echo "--- 出力終了 ---"
}

# メイン処理
main() {
    # スクリプト初期化
    init_script "tmux-exec.sh"
    
    # 変数初期化
    local session_name=""
    local pane_id=""
    local command=""
    local send_enter="true"
    local capture_output="false"
    
    # 引数解析（シンプルな方法）
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                cleanup_script 0
                ;;
            --debug|-d)
                export TMUX_DEBUG=1
                shift
                ;;
            --wait)
                send_enter="false"
                shift
                ;;
            --capture)
                capture_output="true"
                shift
                ;;
            *)
                if [[ -z "$session_name" ]]; then
                    session_name="$1"
                elif [[ -z "$pane_id" ]]; then
                    pane_id="$1"
                elif [[ -z "$command" ]]; then
                    command="$1"
                else
                    print_error "不明な引数: $1"
                    usage
                    cleanup_script 1
                fi
                shift
                ;;
        esac
    done
    
    # 必須引数のチェック
    if [[ -z "$session_name" || -z "$pane_id" || -z "$command" ]]; then
        print_error "必須引数が不足しています"
        usage
        cleanup_script 1
    fi
    
    # 事前チェック
    run_common_checks "$session_name" true || cleanup_script 1
    check_pane_exists "$session_name" "$pane_id" || cleanup_script 1
    
    # コマンド実行
    execute_command "$session_name" "$pane_id" "$command" "$send_enter"
    
    # キャプチャオプションが指定されている場合
    if [[ "$capture_output" == "true" ]]; then
        capture_pane "$session_name" "$pane_id"
    fi
    
    cleanup_script 0
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
