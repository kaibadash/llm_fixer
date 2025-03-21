# frozen_string_literal: true

require "spec_helper"
require "llm_fixer/static_analysis_fixer"

RSpec.describe LlmFixer::StaticAnalysisFixer do
  let(:api_key) { "dummy_api_key" }
  let(:fixer) { described_class.new(api_key) }
  let(:file_path) { "sample/error_file.rb" }
  let(:command) { "rubocop #{file_path}" }
  let(:error_output) do
    "Error: Style/StringLiterals: Prefer single-quoted strings when you don't need string interpolation or special symbols."
  end

  describe "#fix_file" do
    before do
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:read).with(file_path).and_return('puts "Hello World"')
      allow(File).to receive(:write)
      allow(Open3).to receive(:capture2)
    end

    context "when the command succeeds" do
      before do
        allow(Open3).to receive(:capture2).and_return(["", double(exitstatus: 0)])
      end

      it "returns true if no errors are found" do
        expect(fixer.fix_file([command])).to eq(true)
        expect(File).not_to have_received(:write)
      end
    end

    context "when the command fails" do
      before do
        allow(Open3).to receive(:capture2).and_return([error_output, double(exitstatus: 1)],
                                                      ["", double(exitstatus: 0)])
        allow(fixer).to receive(:generate_fix).and_return("puts 'Hello World'")
      end

      it "applies LLM fixes and returns true" do
        expect(fixer.fix_file(["rubocop", file_path])).to eq(true)
        expect(File).to have_received(:write).with(file_path, "puts 'Hello World'")
      end
    end

    context "when errors remain after fixing" do
      before do
        allow(Open3).to receive(:capture2).and_return([error_output, double(exitstatus: 1)],
                                                      [error_output, double(exitstatus: 1)])
        allow(fixer).to receive(:generate_fix).and_return("puts 'Hello World'")
      end

      it "returns false" do
        expect(fixer.fix_file(["rubocop", file_path])).to eq(false)
        expect(File).to have_received(:write).with(file_path, "puts 'Hello World'")
      end
    end
  end

  describe "#generate_fix" do
    let(:client_double) { instance_double(OpenAI::Client) }

    before do
      allow(OpenAI::Client).to receive(:new).and_return(client_double)
      allow(client_double).to receive(:chat) do |params|
        params[:parameters][:stream]&.call({ "choices" => [{ "delta" => { "content" => "puts 'Hello World'" } }] })
        nil
      end
      allow(File).to receive(:read).with(file_path).and_return('puts "Hello World"')
      allow(fixer).to receive(:build_messages).and_return([])
    end

    it "returns formatted response from LLM" do
      result = fixer.send(:generate_fix, file_path, command, error_output)
      expect(result).to eq("puts 'Hello World'")
    end
  end

  describe "#run_command" do
    context "when the command is not found" do
      before do
        allow(fixer).to receive(:`).with("which rubocop").and_return("")
      end

      it "returns error message and false" do
        result, success = fixer.send(:run_command, "rubocop")
        expect(result).to include("Command not found")
        expect(success).to eq(false)
      end
    end

    context "when the command is found" do
      before do
        allow(fixer).to receive(:`).with("which rubocop").and_return("/usr/local/bin/rubocop\n")
        allow(Open3).to receive(:capture2).and_return(["No errors", double(exitstatus: 0)])
      end

      it "returns command output and true" do
        result, success = fixer.send(:run_command, "rubocop")
        expect(result).to eq("No errors")
        expect(success).to eq(true)
      end
    end
  end
end
