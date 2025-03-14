<!-- @format -->

# LLM fixer

静的解析エラーを自動的に修正するツールです。

## インストール

Gemfile に以下を追加します:

```ruby
gem 'llm_fixer'
```

そして以下を実行します:

```bash
$ bundle install
```

または、以下のようにインストールします:

```bash
$ gem install llm_fixer
```

## 環境変数

以下の環境変数を使用して動作をカスタマイズできます:

- `LLM_API_KEY` : LLM API キー
- `LLM_API_BASE` : LLM API のベース URL
- `LLM_MODEL` : 使用する LLM モデル

## 使用方法

環境変数を設定します:

### ChatGPT

```bash
export LLM_API_KEY="your-api-key-here"
export LLM_API_BASE="https://api.openai.com/v1"
export LLM_MODEL="gpt-4o"
```

### Google Gemini

```bash
export LLM_API_KEY="your-api-key-here"
export LLM_API_BASE="https://generativelanguage.googleapis.com/v1beta"
export LLM_MODEL="gemini-2.0-pro-exp"
```

### 実行

静的解析ツールコマンド（例：RuboCop）を実行します:

```bash
llm_fixer fix your-lint-or-test-command path/to/target

# Rubocop例
llm_fixer fix bundle exec rubocop path/to/target.rb
```
