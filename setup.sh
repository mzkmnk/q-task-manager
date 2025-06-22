#!/bin/bash

# Q Task Manager - tmux 4分割環境セットアップスクリプト
# 使用方法: ./setup.sh [session-name]

set -e

# 設定
SESSION_NAME="${1:-q-task-manager}"  # 第一引数があればそれを使用、なければデフォルト
WINDOW_NAME="main"

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

# tmuxがインストールされているかチェック
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        print_error "tmux がインストールされていません。"
        print_info "macOS: brew install tmux"
        print_info "Ubuntu/Debian: sudo apt-get install tmux"
        print_info "CentOS/RHEL: sudo yum install tmux"
        exit 1
    fi
    print_info "tmux が見つかりました: $(tmux -V)"
}

# 既存のセッションをチェック
check_existing_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        print_warning "セッション '$SESSION_NAME' は既に存在します。"
        read -p "既存のセッションを終了して新しく作成しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "既存のセッションを終了しています..."
            tmux kill-session -t "$SESSION_NAME"
            print_success "既存のセッションを終了しました。"
        else
            print_info "既存のセッションにアタッチします..."
            tmux attach-session -t "$SESSION_NAME"
            exit 0
        fi
    fi
}

# tmuxセッションを作成
create_session() {
    print_info "新しいtmuxセッション '$SESSION_NAME' を作成しています..."
    
    # 新しいセッションを作成（デタッチ状態で）
    tmux new-session -d -s "$SESSION_NAME" -n "$WINDOW_NAME"
    
    print_success "セッション '$SESSION_NAME' を作成しました。"
}

# 4分割レイアウトを設定
setup_layout() {
    print_info "4分割レイアウトを設定しています..."
    
    # 画面を縦に分割（左右）
    tmux split-window -h -t "$SESSION_NAME:$WINDOW_NAME"
    
    # 左側を横に分割（上下）
    tmux split-window -v -t "$SESSION_NAME:$WINDOW_NAME.0"
    
    # 右側を横に分割（上下）
    tmux split-window -v -t "$SESSION_NAME:$WINDOW_NAME.2"
    
    # レイアウトを均等に調整
    tmux select-layout -t "$SESSION_NAME:$WINDOW_NAME" tiled
    
    print_success "4分割レイアウトを設定しました。"
}

# 各ペインに初期コマンドを設定
setup_panes() {
    print_info "各ペインを初期化しています..."
    
    # ペイン0（左上）: Boss AI エリア
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'clear' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'echo "=== Boss AI エリア ==="' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'echo "Boss AIが3つのWorker AIを統括します"' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'echo ""' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'echo "手順："' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'echo "1. q chat"' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'echo "2. あなたはBossです。./instructions/boss.mdを読んで指示に従ってください。"' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" 'echo ""' Enter
    
    # ペイン1（右上）: Worker1 エリア
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.1" 'clear' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.1" 'echo "=== Worker1 エリア ==="' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.1" 'echo "Worker1 AIがここで作業します"' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.1" 'echo "Boss AIからの指示を待機中..."' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.1" 'echo ""' Enter
    
    # ペイン2（左下）: Worker2 エリア
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.2" 'clear' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.2" 'echo "=== Worker2 エリア ==="' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.2" 'echo "Worker2 AIがここで作業します"' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.2" 'echo "Boss AIからの指示を待機中..."' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.2" 'echo ""' Enter
    
    # ペイン3（右下）: Worker3 エリア
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.3" 'clear' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.3" 'echo "=== Worker3 エリア ==="' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.3" 'echo "Worker3 AIがここで作業します"' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.3" 'echo "Boss AIからの指示を待機中..."' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.3" 'echo ""' Enter
    tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.3" 'echo "$(date): Q Task Manager AI協働セッション開始"' Enter
    
    # Boss AIペイン（左上）を選択
    tmux select-pane -t "$SESSION_NAME:$WINDOW_NAME.0"
    
    print_success "AI協働環境を初期化しました。"
}

# ステータスバーをカスタマイズ
setup_status_bar() {
    print_info "ステータスバーを設定しています..."
    
    # ステータスバーの設定
    tmux set-option -t "$SESSION_NAME" status-left-length 50
    tmux set-option -t "$SESSION_NAME" status-right-length 100
    tmux set-option -t "$SESSION_NAME" status-left "#[fg=green,bold]Q-Task-Manager #[fg=blue]#S #[default]"
    tmux set-option -t "$SESSION_NAME" status-right "#[fg=yellow]%Y-%m-%d %H:%M #[fg=green]#H"
    tmux set-option -t "$SESSION_NAME" status-bg black
    tmux set-option -t "$SESSION_NAME" status-fg white
    
    print_success "ステータスバーを設定しました。"
}

# セッションにアタッチ
attach_session() {
    print_info "セッション '$SESSION_NAME' にアタッチしています..."
    print_success "Q Task Manager AI協働環境が準備できました！"
    print_info ""
    print_info "🤖 Boss AI起動手順："
    print_info "1. 左上ペインで「q chat」を実行"
    print_info "2. Amazon Q起動後、以下のプロンプトを入力："
    print_info "   「あなたはBossです。./instructions/boss.mdを読んで指示に従ってください。」"
    print_info "3. Boss AIにプロジェクト情報を入力"
    print_info "4. Worker AIたちが自動起動されます"
    print_info ""
    print_info "使用方法:"
    print_info "  ./setup.sh                    # デフォルトセッション名 'q-task-manager' を使用"
    print_info "  ./setup.sh my-project         # カスタムセッション名 'my-project' を使用"
    print_info ""
    print_info "ペイン構成:"
    print_info "  左上: Boss AI エリア（現在選択中）"
    print_info "  右上: Worker1 エリア"
    print_info "  左下: Worker2 エリア"
    print_info "  右下: Worker3 エリア"
    print_info ""
    print_info "tmux操作:"
    print_info "  Ctrl+b → 矢印キー: ペイン間移動"
    print_info "  Ctrl+b → d: セッションをデタッチ"
    print_info "  Ctrl+b → ?: ヘルプ表示"
    print_info ""
    print_info "セッション再接続: tmux attach-session -t $SESSION_NAME"
    print_info ""
    
    # セッションにアタッチ
    tmux attach-session -t "$SESSION_NAME"
}

# メイン処理
main() {
    print_info "Q Task Manager - tmux 4分割環境セットアップを開始します..."
    print_info "セッション名: $SESSION_NAME"
    print_info ""
    
    check_tmux
    check_existing_session
    create_session
    setup_layout
    setup_panes
    setup_status_bar
    attach_session
}

# スクリプト実行
main "$@"
