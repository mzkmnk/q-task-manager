#!/bin/bash

# tmux-broadcast.sh - 全ペインへのコマンド送信
# 使用方法: ./tmux-broadcast.sh <session-name> "<command>"

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "tmux-broadcast.sh" "
  ./tmux-broadcast.sh <session-name> \"<command>\"
  ./tmux-broadcast.sh <session-name> \"<command>\" [--panes 0,1,2]
  ./tmux-broadcast.sh <session-name> \"<command>\" [--exclude 3]
  ./tmux-broadcast.sh <session-name> \"<command>\" [--wait]

引数:
  session-name    tmuxセッション名
  command         実行するコマンド

オプション:
  --panes         特定のペインのみに送信 (カンマ区切り)
  --exclude       除外するペイン (カンマ区切り)
  --wait          コマンド実行後にEnterキーを送信しない
  --delay         ペイン間の実行間隔（秒）デフォルト: 0.2

例:
  ./tmux-broadcast.sh my-session \"clear\"
  ./tmux-broadcast.sh my-session \"git pull\" --panes 0,1,2
  ./tmux-broadcast.sh my-session \"cd /project\" --exclude 3
  ./tmux-broadcast.sh my-session \"npm install\" --delay 1"
}

# 全ペインにコマンドを送信
broadcast_to_all() {
    local session_name="$1"
    local command="$2"
    local send_enter="$3"
    local delay="$4"
    local target_panes=("$@")
    shift 4
    local exclude_panes=("$@")
    
    # セッションの全ペインを取得
    local all_panes
    all_panes=$(tmux list-panes -t "$session_name" -F "#{pane_index}")
    
    local executed_count=0
    
    for pane in $all_panes; do
        # 除外ペインのチェック
        local should_exclude=false
        for exclude in "${exclude_panes[@]}"; do
            if [[ "$pane" == "$exclude" ]]; then
                should_exclude=true
                break
            fi
        done
        
        if [[ "$should_exclude" == "true" ]]; then
            print_debug "ペイン $pane をスキップします（除外指定）"
            continue
        fi
        
        # 対象ペインの指定がある場合のチェック
        if [[ ${#target_panes[@]} -gt 0 ]]; then
            local is_target=false
            for target in "${target_panes[@]}"; do
                if [[ "$pane" == "$target" ]]; then
                    is_target=true
                    break
                fi
            done
            
            if [[ "$is_target" == "false" ]]; then
                print_debug "ペイン $pane をスキップします（対象外）"
                continue
            fi
        fi
        
        print_info "ペイン $pane にコマンドを送信: $command"
        
        # コマンドを送信
        tmux send-keys -t "$session_name:$pane" "$command"
        
        # Enterキーを送信（--waitオプションがない場合）
        if [[ "$send_enter" == "true" ]]; then
            tmux send-keys -t "$session_name:$pane" Enter
        fi
        
        executed_count=$((executed_count + 1))
        
        # 遅延
        if [[ "$delay" != "0" ]]; then
            sleep "$delay"
        fi
    done
    
    if [[ "$send_enter" == "true" ]]; then
        print_success "$executed_count 個のペインでコマンドを実行しました"
    else
        print_success "$executed_count 個のペインにコマンドを送信しました（実行待ち）"
    fi
}

# 特定のペイン群にコマンドを送信
broadcast_to_panes() {
    local session_name="$1"
    local command="$2"
    local send_enter="$3"
    local delay="$4"
    shift 4
    local panes=("$@")
    
    print_info "${#panes[@]} 個のペインにコマンドを送信します"
    
    for pane in "${panes[@]}"; do
        if check_pane_exists "$session_name" "$pane"; then
            print_info "ペイン $pane にコマンドを送信: $command"
            tmux send-keys -t "$session_name:$pane" "$command"
            
            if [[ "$send_enter" == "true" ]]; then
                tmux send-keys -t "$session_name:$pane" Enter
            fi
            
            if [[ "$delay" != "0" ]]; then
                sleep "$delay"
            fi
        fi
    done
    
    if [[ "$send_enter" == "true" ]]; then
        print_success "${#panes[@]} 個のペインでコマンドを実行しました"
    else
        print_success "${#panes[@]} 個のペインにコマンドを送信しました（実行待ち）"
    fi
}

# 同期モードの切り替え
toggle_sync_mode() {
    local session_name="$1"
    local enable="$2"
    
    if [[ "$enable" == "true" ]]; then
        tmux set-window-option -t "$session_name" synchronize-panes on
        print_success "同期モードを有効にしました"
    else
        tmux set-window-option -t "$session_name" synchronize-panes off
        print_success "同期モードを無効にしました"
    fi
}

# メイン処理
main() {
    # スクリプト初期化
    init_script "tmux-broadcast.sh"
    
    # 共通引数の解析
    local remaining_args
    readarray -t remaining_args < <(parse_common_args "$@")
    
    # ヘルプ表示チェック
    if [[ "${COMMON_HELP_FLAG:-}" == "true" ]]; then
        usage
        cleanup_script 0
    fi
    
    # 変数初期化
    local session_name=""
    local command=""
    local send_enter="true"
    local delay="0.2"
    local target_panes=()
    local exclude_panes=()
    local sync_mode=""
    
    # 残りの引数を解析
    local i=0
    while [[ $i -lt ${#remaining_args[@]} ]]; do
        case "${remaining_args[$i]}" in
            --wait)
                send_enter="false"
                ;;
            --panes)
                ((i++))
                if [[ $i -lt ${#remaining_args[@]} ]]; then
                    IFS=',' read -ra target_panes <<< "${remaining_args[$i]}"
                fi
                ;;
            --exclude)
                ((i++))
                if [[ $i -lt ${#remaining_args[@]} ]]; then
                    IFS=',' read -ra exclude_panes <<< "${remaining_args[$i]}"
                fi
                ;;
            --delay)
                ((i++))
                if [[ $i -lt ${#remaining_args[@]} ]]; then
                    delay="${remaining_args[$i]}"
                fi
                ;;
            --sync-on)
                sync_mode="on"
                ;;
            --sync-off)
                sync_mode="off"
                ;;
            *)
                if [[ -z "$session_name" ]]; then
                    session_name="${remaining_args[$i]}"
                elif [[ -z "$command" ]]; then
                    command="${remaining_args[$i]}"
                else
                    print_error "不明な引数: ${remaining_args[$i]}"
                    usage
                    cleanup_script 1
                fi
                ;;
        esac
        ((i++))
    done
    
    # 同期モードの切り替えのみの場合
    if [[ -n "$sync_mode" ]]; then
        if [[ -z "$session_name" ]]; then
            print_error "セッション名が必要です"
            cleanup_script 1
        fi
        run_common_checks "$session_name" true || cleanup_script 1
        toggle_sync_mode "$session_name" "$([[ "$sync_mode" == "on" ]] && echo "true" || echo "false")"
        cleanup_script 0
    fi
    
    # 必須引数のチェック
    if ! check_required_args "session_name command" "$session_name" "$command"; then
        usage
        cleanup_script 1
    fi
    
    # 事前チェック
    run_common_checks "$session_name" true || cleanup_script 1
    
    # コマンド送信
    if [[ ${#target_panes[@]} -gt 0 ]]; then
        broadcast_to_panes "$session_name" "$command" "$send_enter" "$delay" "${target_panes[@]}"
    else
        broadcast_to_all "$session_name" "$command" "$send_enter" "$delay" "${exclude_panes[@]}"
    fi
    
    cleanup_script 0
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
