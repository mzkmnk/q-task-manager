# DRY原則（Don't Repeat Yourself）開発ルール

## 概要

Q Task Managerプロジェクトでは、DRY原則を徹底して適用し、保守性と拡張性の高いコードベースを維持します。この原則は、シェルスクリプト、TypeScript、設定ファイル、ドキュメントなど、プロジェクト全体に適用されます。

## 基本原則

### 1. 重複の排除
- **同じロジック・処理を複数箇所に記述しない**
- **類似した機能は共通化して再利用する**
- **コピー&ペーストによる開発を避ける**
- **設定値や定数の重複を避ける**

### 2. 単一責任の原則
- **一つの関数・モジュール・ファイルは一つの責務のみを持つ**
- **機能ごとに適切にファイルを分離する**
- **共通処理は専用のユーティリティに集約する**
- **関心事の分離を徹底する**

### 3. 抽象化の活用
- **共通パターンを抽象化して再利用可能にする**
- **設定可能なパラメータを活用する**
- **テンプレート化できるものは積極的にテンプレート化する**

## 言語・技術別の適用

### シェルスクリプト

#### 共通ユーティリティの活用
```bash
# 共通関数の読み込み
source "$SCRIPT_DIR/utils.sh"

# 統一されたメッセージ出力
print_info "処理開始"
print_success "処理完了"
print_error "エラー発生"
```

#### 標準化されたパターン
```bash
# 引数解析の統一
parse_arguments "$@"

# エラーハンドリングの統一
handle_error_and_exit "エラーメッセージ"

# 終了処理の統一
cleanup_and_exit 0
```

### TypeScript/JavaScript

#### 共通ユーティリティの作成
```typescript
// utils/logger.ts
export const logger = {
  info: (message: string) => console.log(`[INFO] ${message}`),
  success: (message: string) => console.log(`[SUCCESS] ${message}`),
  error: (message: string) => console.error(`[ERROR] ${message}`)
};

// utils/validation.ts
export const validateRequired = (value: any, fieldName: string) => {
  if (!value) {
    throw new Error(`${fieldName} is required`);
  }
};
```

#### 型定義の共通化
```typescript
// types/common.ts
export interface BaseEntity {
  id: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ApiResponse<T> {
  data: T;
  success: boolean;
  message?: string;
}
```

### 設定ファイル

#### 環境変数の一元管理
```typescript
// config/environment.ts
export const config = {
  tmux: {
    defaultSession: process.env.TMUX_DEFAULT_SESSION || 'q-task-manager',
    timeout: parseInt(process.env.TMUX_TIMEOUT || '30')
  },
  paths: {
    workspace: process.env.WORKSPACE_PATH || './tasks',
    backup: process.env.BACKUP_PATH || './backup'
  }
};
```

#### 設定テンプレートの活用
```json
// templates/project-config.json
{
  "name": "{{PROJECT_NAME}}",
  "version": "{{VERSION}}",
  "paths": {
    "src": "{{SRC_PATH}}",
    "dist": "{{DIST_PATH}}"
  }
}
```

### ドキュメント

#### テンプレートの活用
```markdown
<!-- templates/script-readme.md -->
# {{SCRIPT_NAME}}

## 概要
{{DESCRIPTION}}

## 使用方法
```bash
./{{SCRIPT_NAME}} [options]
```

## オプション
{{OPTIONS_TABLE}}
```

#### 共通セクションの再利用
- インストール手順
- トラブルシューティング
- ライセンス情報
- 貢献ガイドライン

## 汎用的な禁止事項

### ❌ 全言語共通でやってはいけないこと

1. **同一ロジックの重複**
   ```typescript
   // NG: 同じバリデーション処理を複数箇所に記述
   if (!email || !email.includes('@')) {
       throw new Error('Invalid email');
   }
   
   // OK: 共通関数を作成
   validateEmail(email);
   ```

2. **ハードコードされた値の重複**
   ```typescript
   // NG: マジックナンバーの重複
   const timeout1 = 5000;
   const timeout2 = 5000;
   
   // OK: 定数として定義
   const DEFAULT_TIMEOUT = 5000;
   ```

3. **設定値の重複**
   ```json
   // NG: 複数ファイルで同じ設定
   // config1.json: { "port": 3000 }
   // config2.json: { "port": 3000 }
   
   // OK: 共通設定ファイルから読み込み
   ```

4. **ドキュメントの重複**
   ```markdown
   <!-- NG: 同じ説明を複数ファイルに記述 -->
   
   <!-- OK: 共通テンプレートまたは参照を使用 -->
   ```

### ❌ 言語固有の禁止事項

#### TypeScript/JavaScript
```typescript
// NG: 同じ型定義の重複
interface User1 { id: string; name: string; }
interface User2 { id: string; name: string; }

// OK: 共通型定義
interface BaseUser { id: string; name: string; }
```

#### シェルスクリプト
```bash
# NG: 同じチェック処理の重複
if ! command -v git &> /dev/null; then
    echo "git not found"
    exit 1
fi

# OK: 共通関数を使用
check_command "git" || exit_with_error "git not found"
```

## 推奨パターン

### ✅ 推奨される実装

#### 新しいスクリプト作成時のテンプレート
```bash
#!/bin/bash

# script-name.sh - スクリプトの説明
# 使用方法: ./script-name.sh <args>

set -e

# 共通ユーティリティを読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-utils.sh"

# 使用方法を表示
usage() {
    show_usage "script-name.sh" "
  ./script-name.sh <required-arg> [options]

引数:
  required-arg    必須引数の説明

オプション:
  --optional      オプション引数の説明

例:
  ./script-name.sh example-value --optional"
}

# メイン処理の関数
main_function() {
    local arg1="$1"
    local arg2="$2"
    
    print_info "処理を開始します"
    
    # 実際の処理
    # ...
    
    print_success "処理が完了しました"
}

# メイン処理
main() {
    # スクリプト初期化
    init_script "script-name.sh"
    
    # 変数初期化
    local required_arg=""
    local optional_flag="false"
    
    # 引数解析（標準パターン）
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
            --optional)
                optional_flag="true"
                shift
                ;;
            *)
                if [[ -z "$required_arg" ]]; then
                    required_arg="$1"
                else
                    print_error "不明な引数: $1"
                    usage
                    cleanup_script 1
                fi
                shift
                ;;
        esac
    done
    
    # 必須引数チェック
    if [[ -z "$required_arg" ]]; then
        print_error "必須引数が不足しています"
        usage
        cleanup_script 1
    fi
    
    # 事前チェック
    run_common_checks "$required_arg" true || cleanup_script 1
    
    # メイン処理実行
    main_function "$required_arg" "$optional_flag"
    
    cleanup_script 0
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## コードレビューチェックリスト

### 新規スクリプト作成時
- [ ] tmux-utils.shを読み込んでいる
- [ ] init_script()を呼び出している
- [ ] cleanup_script()で終了している
- [ ] 統一されたメッセージ関数を使用している
- [ ] 標準化された引数解析パターンを使用している
- [ ] 適切なエラーハンドリングを実装している
- [ ] ヘルプ機能を実装している

### 既存スクリプト修正時
- [ ] 重複コードを共通関数に抽出した
- [ ] 類似処理を統一した
- [ ] ハードコードされた値を設定可能にした
- [ ] エラーメッセージを統一した

## 互換性要件

### Bash バージョン対応
- **対象バージョン**: Bash 3.2以上（macOSデフォルト対応）
- **禁止機能**:
  - 連想配列（`declare -A`）
  - `readarray`コマンド
  - Bash 4.0以降の機能

### 推奨される互換性パターン
```bash
# NG: 連想配列
declare -A args
args[key]="value"

# OK: 環境変数または通常の変数
local key_value="value"

# NG: readarray
readarray -t array < <(command)

# OK: whileループ
while IFS= read -r line; do
    array+=("$line")
done < <(command)
```

## 継続的改善

### 定期的な見直し
1. **月次レビュー**: 重複コードの検出と統合
2. **機能追加時**: 既存パターンとの整合性確認
3. **リファクタリング**: DRY原則違反の修正

### メトリクス監視
- コード重複率の測定
- 共通関数の使用率
- エラーハンドリングの統一度

## 参考資料

- [The Pragmatic Programmer - DRY原則](https://pragprog.com/)
- [Clean Code - 関数の原則](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)

---

**作成日**: 2025-06-21  
**バージョン**: 1.0.0  
**適用範囲**: Q Task Manager全体  
**更新頻度**: 月次または機能追加時
