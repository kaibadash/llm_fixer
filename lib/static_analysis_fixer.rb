# frozen_string_literal: true

require "openai"
require "open3"
require "tempfile"
require "pry"
require "erb"
require "colorize"

# Main class to handle static analysis fixes
class StaticAnalysisFixer
  DEFAULT_MODEL = "gpt-4o"
  DEFAULT_API_BASE = "https://api.openai.com/v1"

  def initialize(api_key)
    # Initialize OpenAI client with API key
    @client = OpenAI::Client.new(
      access_token: ENV.fetch("API_KEY", api_key),
      uri_base: ENV.fetch("LLM_API_BASE", DEFAULT_API_BASE),
      request_timeout: 600,
    )
    @model = ENV.fetch("LLM_MODEL", DEFAULT_MODEL)
  end

  def fix_file(args)
    command = args.join(" ")
    output, status = run_command(command)
    if status.success?
      puts "No errors found"
      return true
    end

    # Search for existing file paths from command line arguments in reverse order
    file_path = args.reverse.find { |arg| File.exist?(arg) }
    return false unless file_path

    # Request correction from LLM
    patch = generate_fix(file_path, command, output)
    return false unless patch

    # Apply the patch
    apply_patch(patch)

    # Check again
    new_output, new_status = run_command(command)

    unless new_status.success?
      puts "After correction, there are still errors:".red
      puts new_output
      return false
    end

    puts "#{file_path} was fixed!".green
    true
  end

  private

  def run_command(command)
    command_parts = command.split
    command_path = `which #{command_parts[0]}`.strip
    return ["Command not found: #{command_parts[0]}", false] if command_path.empty?

    Open3.capture2(ENV.to_h, command_path, *command_parts[1..])
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
          if content
            puts content
            full_response += content
          end
        },
      },
    )

    full_response
  end

  def build_messages(file_path, command, error_output, file_content)
    templates = {
      system: "fix_prompt_system.erb",
      assistant: "fix_prompt_assistant.erb",
      user: "fix_prompt_user.erb",
    }

    messages = []
    b = binding
    system_template = ERB.new(File.read(File.join(File.dirname(__FILE__),
                                                  "templates/#{templates[:system]}")))
    messages << { role: "system", content: system_template.result(b) }
    assistant_template = ERB.new(File.read(File.join(File.dirname(__FILE__),
                                                     "templates/#{templates[:assistant]}")))
    messages << { role: "assistant", content: assistant_template.result(b) }
    user_template = ERB.new(File.read(File.join(File.dirname(__FILE__),
                                                "templates/#{templates[:user]}")))
    messages << { role: "user", content: user_template.result(b) }

    messages
  end

  def apply_patch(patch)
    puts "patch: \n#{patch}"
    puts "==============="
    Tempfile.create("patch") do |f|
      f.write(patch)
      f.close
      patch_command = "patch -f --no-backup-if-mismatch -p1 < #{f.path}"
      system(patch_command)
    end
  end
end
