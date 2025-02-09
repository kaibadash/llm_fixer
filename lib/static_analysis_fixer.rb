# frozen_string_literal: true

require "openai"
require "open3"
require "tempfile"
require "pry"
require "erb"

class StaticAnalysisFixer
  DEFAULT_MODEL = "gpt-4o"
  DEFAULT_API_BASE = "https://api.openai.com/v1"

  def initialize(api_key)
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
    return true if status.success?

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
      puts "After correction, there are still errors:"
      puts new_output
      return false
    end

    puts "#{file_path} was fixed!"
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
    prompt = build_prompt(file_path, command, error_output, file_content)

    full_response = ""
    @client.chat(
      parameters: {
        model: @model,
        messages: [{ role: "user", content: prompt }],
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

  def build_prompt(file_path, command, error_output, file_content)
    template_path = File.join(File.dirname(__FILE__), 'templates/fix_prompt.erb')
    template = ERB.new(File.read(template_path))
    template.result(binding)
  end

  def apply_patch(patch)
    Tempfile.create("patch") do |f|
      f.write(patch)
      f.close
      patch_command = "patch -f -p1 < #{f.path}"
      system(patch_command)
    end
  end
end
