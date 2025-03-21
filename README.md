<!-- @format -->

# LLM fixer

A tool that automatically fixes static analysis errors.

## Installation

Add this line to your Gemfile:

```ruby
gem 'llm_fixer'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install llm_fixer
```

## Environment Variables

You can customize the behavior using the following environment variables:

- `LLM_API_KEY` : LLM API key
- `LLM_API_BASE` : Base URL for the LLM API
- `LLM_MODEL` : LLM model to use

## Usage

Set the environment variables:

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

### Execution

Run your static analysis tool command (e.g., RuboCop):

```bash
llm_fixer fix your-lint-or-test-command path/to/target

# RuboCop example
llm_fixer fix bundle exec rubocop path/to/target.rb
```
