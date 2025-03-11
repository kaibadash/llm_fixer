# frozen_string_literal: true

require "openai"
require "open3"
require "tempfile"
require "pry"
require "erb"
require "colorize"
require "ostruct"

module LlmFixer
  class StaticAnalysisFixer
    DEFAULT_MODEL = "gpt-4o"
    DEFAULT_API_BASE = "https://api.openai.com/v1"

    def initialize(api_key)
      @client = OpenAI::Client.new(
        access_token: ENV.fetch("LLM_API_KEY", api_key),
        uri_base: ENV.fetch("LLM_API_BASE", DEFAULT_API_BASE),
        request_timeout: 600,
      )
      @model = ENV.fetch("LLM_MODEL", DEFAULT_MODEL)
      puts "LLM model: #{@model}"
    end

    def fix_file(args)
      command = args.join(" ")
      output, succeeded = run_command(command)
      if succeeded
        puts "No errors found"
        return true
      end

      # Search for existing file paths from command line arguments in reverse order
      file_path = args.reverse.find { |arg| File.exist?(arg) }
      return false unless file_path

      # Request correction from LLM
      result = generate_fix(file_path, command, output)
      return false unless result

      File.write(file_path, result)

      # Check again
      _, succeeded = run_command(command)
      if succeeded
        puts "#{file_path} was fixed!".green
        true
      else
        puts "#{file_path} was not fixed!".red
        false
      end
    end

    private

    def run_command(command)
      command_parts = command.split
      command_path = `which #{command_parts[0]}`.strip
      return ["Command not found: #{command_parts[0]}", false] if command_path.empty?

      output, status = Open3.capture2(ENV.to_h, command_path, *command_parts[1..])
      succeeded = status.exitstatus.zero?
      unless succeeded
        puts "After correction, there are still errors:".red
        puts output
      end
      [output, succeeded]
    end

    def generate_fix(file_path, command, error_output)
      file_content = File.read(file_path)
      messages = build_messages(file_path, command, error_output, file_content)
      puts messages
      full_response = ""
      puts "===== Start generating fix ====="
      @client.chat(
        parameters: {
          model: @model,
          messages: messages,
          stream: proc { |chunk|
            content = chunk.dig("choices", 0, "delta", "content")
            full_response += content if content
          },
        },
      )

      full_response.strip!
      # remove markdown syntax
      full_response = full_response.split("\n")[1..-2].join("\n") + "\n" if full_response.start_with?("```")
      puts full_response
      puts "===== End generating fix ====="
      full_response
    end

    def build_messages(file_path, command, error_output, file_content)
      templates = {
        system: "fix_prompt_system.erb",
        user: "fix_prompt_user.erb",
      }

      messages = []
      b = binding
      system_template = ERB.new(File.read(File.join(File.dirname(__FILE__),
                                                    "../templates/#{templates[:system]}")))
      messages << { role: "system", content: system_template.result(b) }
      user_template = ERB.new(File.read(File.join(File.dirname(__FILE__),
                                                  "../templates/#{templates[:user]}")))
      messages << { role: "user", content: user_template.result(b) }

      messages
    end

    # LLMが警告以外の場所も直した上、差分として上げなかったため、不正なパッチになってしまったので一旦ファイル丸ごと出力されることしにた
    def apply_patch(patch)
      Tempfile.create("patch") do |f|
        f.write(patch)
        f.close
        patch_command = "patch -f --no-backup-if-mismatch -p1 < #{f.path}"
        _, stderr, status = Open3.capture3(patch_command)
        unless status.exitstatus.zero?
          puts "Failed to apply patch: #{stderr}".colorize(:red)
          exit 1
        end
      end
    end
  end
end
