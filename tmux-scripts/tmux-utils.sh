#!/bin/bash

# tmux-utils.sh - 共通ユーティリティ関数
# 他のtmuxスクリプトから読み込んで使用

# 色付きメッセージ用の関数
print_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_debug() {
    if [[ "${TMUX_DEBUG:-}" == "1" ]]; then
        echo -e "\033[1;35m[DEBUG]\033[0m $1"
    fi
}

# tmuxがインストールされているかチェック
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        print_error "tmux がインストールされていません。"
        return 1
    fi
    print_debug "tmux が見つかりました: $(tmux -V)"
    return 0
}

# セッションが存在するかチェック
check_session_exists() {
    local session_name="$1"
    if [[ -z "$session_name" ]]; then
        print_error "セッション名が指定されていません"
        return 1
    fi
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        print_debug "セッション '$session_name' が存在します"
        return 0
    else
        print_error "セッション '$session_name' が存在しません"
        return 1
    fi
}

# ペインが存在するかチェック
check_pane_exists() {
    local session_name="$1"
    local pane_id="$2"
    
    if [[ -z "$session_name" || -z "$pane_id" ]]; then
        print_error "セッション名またはペインIDが指定されていません"
        return 1
    fi
    
    if tmux list-panes -t "$session_name" -F "#{pane_index}" 2>/dev/null | grep -q "^$pane_id$"; then
        print_debug "ペイン '$session_name:$pane_id' が存在します"
        return 0
    else
        print_error "ペイン '$session_name:$pane_id' が存在しません"
        return 1
    fi
}

# 使用方法を表示
show_usage() {
    local script_name="$1"
    local usage_text="$2"
    
    echo "使用方法: $script_name"
    echo "$usage_text"
    echo ""
    echo "環境変数:"
    echo "  TMUX_DEBUG=1    デバッグメッセージを表示"
    echo ""
}

# エラー時の終了処理
exit_with_error() {
    local message="$1"
    local exit_code="${2:-1}"
    
    print_error "$message"
    exit "$exit_code"
}

# 成功時の終了処理
exit_with_success() {
    local message="$1"
    
    print_success "$message"
    exit 0
}

# 設定ファイルの読み込み（将来の拡張用）
load_config() {
    local config_file="${1:-$HOME/.tmux-scripts.conf}"
    
    if [[ -f "$config_file" ]]; then
        print_debug "設定ファイルを読み込みます: $config_file"
        source "$config_file"
    else
        print_debug "設定ファイルが見つかりません: $config_file"
    fi
}

# 共通の引数解析ヘルパー関数（Bash 3.2対応）
parse_common_args() {
    local help_flag=""
    local debug_flag=""
    local force_flag=""
    local remaining_args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                help_flag="true"
                shift
                ;;
            --debug|-d)
                export TMUX_DEBUG=1
                debug_flag="true"
                shift
                ;;
            --force|-f)
                force_flag="true"
                shift
                ;;
            *)
                # 未処理の引数を配列に追加
                remaining_args+=("$1")
                shift
                ;;
        esac
    done
    
    # フラグの状態を環境変数で返す
    [[ "$help_flag" == "true" ]] && export COMMON_HELP_FLAG="true"
    [[ "$debug_flag" == "true" ]] && export COMMON_DEBUG_FLAG="true"
    [[ "$force_flag" == "true" ]] && export COMMON_FORCE_FLAG="true"
    
    # 未処理の引数を返す
    printf '%s\n' "${remaining_args[@]}"
}

# 共通の事前チェック処理
run_common_checks() {
    local session_name="$1"
    local check_session="${2:-true}"
    
    check_tmux || return 1
    
    if [[ "$check_session" == "true" && -n "$session_name" ]]; then
        check_session_exists "$session_name" || return 1
    fi
    
    return 0
}

# 共通のスクリプト初期化処理
init_script() {
    local script_name="$1"
    
    # 設定読み込み
    load_config
    
    # デバッグモード設定
    if [[ "${TMUX_DEBUG:-}" == "1" ]]; then
        print_debug "デバッグモードが有効です"
        print_debug "スクリプト: $script_name"
    fi
}

# 共通のヘルプ表示処理
handle_help() {
    local script_name="$1"
    local usage_text="$2"
    local show_help="${3:-false}"
    
    if [[ "$show_help" == "true" ]]; then
        show_usage "$script_name" "$usage_text"
        exit 0
    fi
}

# 共通のスクリプト終了処理
cleanup_script() {
    local exit_code="${1:-0}"
    
    # 一時ファイルのクリーンアップなど
    if [[ -d "/tmp/tmux_sync_dir" ]]; then
        rm -rf "/tmp/tmux_sync_dir" 2>/dev/null || true
    fi
    
    exit "$exit_code"
}

# 共通の必須引数チェック（Bash 3.2対応）
check_required_args() {
    local arg_names="$1"
    shift
    local provided_args=("$@")
    
    # 引数名をスペース区切りで分割
    IFS=' ' read -ra required_names <<< "$arg_names"
    
    local i=0
    for required_name in "${required_names[@]}"; do
        if [[ $i -ge ${#provided_args[@]} || -z "${provided_args[$i]}" ]]; then
            print_error "必須引数が不足しています: $required_name"
            return 1
        fi
        ((i++))
    done
    
    return 0
}

# このスクリプトが直接実行された場合の処理
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_usage "tmux-utils.sh" "このファイルは他のスクリプトから読み込んで使用してください。"
fi
