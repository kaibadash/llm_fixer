<!-- @format -->

# Static Analysis Fixer

A tool that automatically fixes static analysis errors.

## Environment Variables

You can customize the behavior using the following environment variables:

- `API_KEY` : LLM API key
- `LLM_API_BASE` : Base URL for LLM API
- `LLM_MODEL` : LLM model to use

## Usage

Set up your environment variables and add the `bin` directory to your PATH:

### ChatGPT

```bash
export API_KEY="your-api-key-here"
export LLM_API_BASE="https://api.openai.com/v1"
export LLM_MODEL="gpt-4o"
export PATH="$PATH:/path/to/static-analysis-fixer/bin"
```

### Google Gemini

```bash
export API_KEY="your-api-key-here"
export LLM_API_BASE="https://generativelanguage.googleapis.com/v1beta"
export LLM_MODEL="gemini-2.0-pro-exp"
export PATH="$PATH:/path/to/static-analysis-fixer/bin"
```

### Run

Run your static analysis tool command (e.g., RuboCop)

```bash
llm_autofix your-lint-or-test-command path/to/target

# Rubocop example
llm_autofix bundle exec rubocop path/to/target.rb
```

The tool will automatically detect and fix static errors in your code!
