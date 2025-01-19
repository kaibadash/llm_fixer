# frozen_string_literal: true

require "openai"
require "open3"
require "tempfile"
require "pry"

class StaticAnalysisFixer
  def initialize(api_key)
    @client = OpenAI::Client.new(access_token: api_key)
  end

  def fix_file(args)
    command = args.join(" ")
    output, status = run_command(command)
    return true if status.success?

    # コマンドライン引数から後ろ順に既存のファイルパスを探す
    file_path = args.reverse.find { |arg| File.exist?(arg) }
    return false unless file_path

    # LLMに修正を依頼
    patch = generate_fix(file_path, command, output)
    return false unless patch

    # パッチを適用
    apply_patch(patch)

    # 再度チェック
    new_output, new_status = run_command(command)

    unless new_status.success?
      puts "修正後もエラーが残っています："
      puts new_output
      return false
    end

    true
  end

  private

  def run_command(command)
    # コマンドを適切に分割して配列として実行
    command_parts = command.split
    Open3.capture2(*command_parts)
  end

  def generate_fix(file_path, command, error_output)
    file_content = File.read(file_path)
    prompt = build_prompt(file_path, command, error_output, file_content)

    full_response = ""
    @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [{ role: "user", content: prompt }],
        stream: proc { |chunk|
          content = chunk.dig("choices", 0, "delta", "content")
          if content
            print content
            full_response += content
          end
        },
      },
    )

    full_response
  end

  def build_prompt(file_path, command, error_output, file_content)
    <<~PROMPT
      以下の静的解析エラーを修正するパッチを生成してください。
      実行コマンド: #{command}

      ファイルの内容:
      #{file_content}

      エラー内容:
      #{error_output}

      unified diff形式のパッチのみを出力してください。
      ファイル名は#{file_path}としてください。
      パッチ以外の説明は不要です。
    PROMPT
  end

  def apply_patch(patch)
    Tempfile.create("patch") do |f|
      f.write(patch)
      f.close
      system("patch -p0 < #{f.path}")
    end
  end
end
