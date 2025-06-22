#!/bin/bash

# tmux-layout.sh - レイアウト管理
# 使用方法: ./tmux-layout.sh <session-name> <layout-command>

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "tmux-layout.sh" "
  ./tmux-layout.sh <session-name> <layout>
  ./tmux-layout.sh <session-name> --resize <pane-id> <direction> <size>
  ./tmux-layout.sh <session-name> --split <pane-id> <direction>
  ./tmux-layout.sh <session-name> --custom <layout-string>

引数:
  session-name    tmuxセッション名
  layout          レイアウト名 (tiled, even-horizontal, even-vertical, main-horizontal, main-vertical)

オプション:
  --resize        ペインサイズを調整
  --split         ペインを分割
  --custom        カスタムレイアウト文字列を適用
  --save          現在のレイアウトを保存
  --restore       保存されたレイアウトを復元

レイアウト:
  tiled           4分割（2x2グリッド）
  even-horizontal 水平均等分割
  even-vertical   垂直均等分割
  main-horizontal メイン画面＋水平分割
  main-vertical   メイン画面＋垂直分割

例:
  ./tmux-layout.sh my-session tiled
  ./tmux-layout.sh my-session --resize 0 right 10
  ./tmux-layout.sh my-session --split 0 horizontal
  ./tmux-layout.sh my-session --save my-layout"
}

# 定義済みレイアウトを適用
apply_layout() {
    local session_name="$1"
    local layout="$2"
    
    print_info "レイアウト '$layout' を適用します"
    
    case "$layout" in
        tiled)
            tmux select-layout -t "$session_name" tiled
            print_success "4分割レイアウトを適用しました"
            ;;
        even-horizontal)
            tmux select-layout -t "$session_name" even-horizontal
            print_success "水平均等分割レイアウトを適用しました"
            ;;
        even-vertical)
            tmux select-layout -t "$session_name" even-vertical
            print_success "垂直均等分割レイアウトを適用しました"
            ;;
        main-horizontal)
            tmux select-layout -t "$session_name" main-horizontal
            print_success "メイン水平レイアウトを適用しました"
            ;;
        main-vertical)
            tmux select-layout -t "$session_name" main-vertical
            print_success "メイン垂直レイアウトを適用しました"
            ;;
        *)
            print_error "不明なレイアウト: $layout"
            print_info "利用可能なレイアウト: tiled, even-horizontal, even-vertical, main-horizontal, main-vertical"
            return 1
            ;;
    esac
}

# ペインサイズを調整
resize_pane() {
    local session_name="$1"
    local pane_id="$2"
    local direction="$3"
    local size="$4"
    
    print_info "ペイン $pane_id のサイズを調整します ($direction: $size)"
    
    case "$direction" in
        up|U)
            tmux resize-pane -t "$session_name:$pane_id" -U "$size"
            ;;
        down|D)
            tmux resize-pane -t "$session_name:$pane_id" -D "$size"
            ;;
        left|L)
            tmux resize-pane -t "$session_name:$pane_id" -L "$size"
            ;;
        right|R)
            tmux resize-pane -t "$session_name:$pane_id" -R "$size"
            ;;
        *)
            print_error "不明な方向: $direction"
            print_info "利用可能な方向: up, down, left, right"
            return 1
            ;;
    esac
    
    print_success "ペインサイズを調整しました"
}

# ペインを分割
split_pane() {
    local session_name="$1"
    local pane_id="$2"
    local direction="$3"
    local command="$4"
    
    print_info "ペイン $pane_id を分割します ($direction)"
    
    case "$direction" in
        horizontal|h)
            if [[ -n "$command" ]]; then
                tmux split-window -h -t "$session_name:$pane_id" "$command"
            else
                tmux split-window -h -t "$session_name:$pane_id"
            fi
            print_success "ペインを水平分割しました"
            ;;
        vertical|v)
            if [[ -n "$command" ]]; then
                tmux split-window -v -t "$session_name:$pane_id" "$command"
            else
                tmux split-window -v -t "$session_name:$pane_id"
            fi
            print_success "ペインを垂直分割しました"
            ;;
        *)
            print_error "不明な分割方向: $direction"
            print_info "利用可能な方向: horizontal, vertical"
            return 1
            ;;
    esac
}

# カスタムレイアウトを適用
apply_custom_layout() {
    local session_name="$1"
    local layout_string="$2"
    
    print_info "カスタムレイアウトを適用します"
    print_debug "レイアウト文字列: $layout_string"
    
    tmux select-layout -t "$session_name" "$layout_string"
    print_success "カスタムレイアウトを適用しました"
}

# 現在のレイアウトを保存
save_layout() {
    local session_name="$1"
    local layout_name="$2"
    local config_dir="$HOME/.tmux-layouts"
    
    # 設定ディレクトリを作成
    mkdir -p "$config_dir"
    
    # 現在のレイアウトを取得
    local current_layout
    current_layout=$(tmux list-windows -t "$session_name" -F "#{window_layout}")
    
    # レイアウトを保存
    echo "$current_layout" > "$config_dir/$layout_name.layout"
    
    print_success "レイアウト '$layout_name' を保存しました"
    print_info "保存場所: $config_dir/$layout_name.layout"
}

# 保存されたレイアウトを復元
restore_layout() {
    local session_name="$1"
    local layout_name="$2"
    local config_dir="$HOME/.tmux-layouts"
    local layout_file="$config_dir/$layout_name.layout"
    
    if [[ ! -f "$layout_file" ]]; then
        print_error "レイアウトファイルが見つかりません: $layout_file"
        return 1
    fi
    
    # レイアウトを読み込み
    local saved_layout
    saved_layout=$(cat "$layout_file")
    
    print_info "レイアウト '$layout_name' を復元します"
    apply_custom_layout "$session_name" "$saved_layout"
}

# 保存されたレイアウト一覧を表示
list_saved_layouts() {
    local config_dir="$HOME/.tmux-layouts"
    
    if [[ ! -d "$config_dir" ]]; then
        print_info "保存されたレイアウトはありません"
        return 0
    fi
    
    print_info "保存されたレイアウト:"
    for layout_file in "$config_dir"/*.layout; do
        if [[ -f "$layout_file" ]]; then
            local layout_name
            layout_name=$(basename "$layout_file" .layout)
            print_info "  - $layout_name"
        fi
    done
}

# 現在のレイアウト情報を表示
show_layout_info() {
    local session_name="$1"
    
    print_info "現在のレイアウト情報:"
    
    # ウィンドウ情報
    local window_info
    window_info=$(tmux list-windows -t "$session_name" -F "#{window_index}: #{window_name} (#{window_panes} panes)")
    print_info "ウィンドウ: $window_info"
    
    # ペイン情報
    print_info "ペイン構成:"
    tmux list-panes -t "$session_name" -F "  ペイン #{pane_index}: #{pane_width}x#{pane_height} at (#{pane_left},#{pane_top})"
    
    # レイアウト文字列
    local layout_string
    layout_string=$(tmux list-windows -t "$session_name" -F "#{window_layout}")
    print_info "レイアウト文字列: $layout_string"
}

# メイン処理
main() {
    local session_name=""
    local layout=""
    local action=""
    local pane_id=""
    local direction=""
    local size=""
    local layout_name=""
    local layout_string=""
    local command=""
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                exit 0
                ;;
            --resize)
                action="resize"
                pane_id="$2"
                direction="$3"
                size="$4"
                shift 4
                ;;
            --split)
                action="split"
                pane_id="$2"
                direction="$3"
                command="$4"
                shift 3
                [[ -n "$command" ]] && shift
                ;;
            --custom)
                action="custom"
                layout_string="$2"
                shift 2
                ;;
            --save)
                action="save"
                layout_name="$2"
                shift 2
                ;;
            --restore)
                action="restore"
                layout_name="$2"
                shift 2
                ;;
            --list)
                action="list"
                shift
                ;;
            --info)
                action="info"
                shift
                ;;
            *)
                if [[ -z "$session_name" ]]; then
                    session_name="$1"
                elif [[ -z "$layout" && -z "$action" ]]; then
                    layout="$1"
                else
                    print_error "不明な引数: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # セッション名のチェック（一部のアクションでは不要）
    if [[ "$action" != "list" ]]; then
        if [[ -z "$session_name" ]]; then
            print_error "セッション名が必要です"
            usage
            exit 1
        fi
        
        # 事前チェック
        check_tmux || exit 1
        check_session_exists "$session_name" || exit 1
    fi
    
    # アクションに応じた処理
    case "$action" in
        resize)
            check_pane_exists "$session_name" "$pane_id" || exit 1
            resize_pane "$session_name" "$pane_id" "$direction" "$size"
            ;;
        split)
            check_pane_exists "$session_name" "$pane_id" || exit 1
            split_pane "$session_name" "$pane_id" "$direction" "$command"
            ;;
        custom)
            apply_custom_layout "$session_name" "$layout_string"
            ;;
        save)
            save_layout "$session_name" "$layout_name"
            ;;
        restore)
            restore_layout "$session_name" "$layout_name"
            ;;
        list)
            list_saved_layouts
            ;;
        info)
            show_layout_info "$session_name"
            ;;
        *)
            if [[ -n "$layout" ]]; then
                apply_layout "$session_name" "$layout"
            else
                print_error "レイアウトまたはアクションが必要です"
                usage
                exit 1
            fi
            ;;
    esac
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
