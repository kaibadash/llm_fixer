# frozen_string_literal: true

require_relative "lib/llm_fixer/version"

Gem::Specification.new do |spec|
  spec.name = "llm_fixer"
  spec.version = LlmFixer::VERSION
  spec.authors = ["kaiba"]
  spec.email = ["kaibadash@gmail.com"]

  spec.summary = "LLM tool to automatically fix static analysis errors"
  spec.description = "A tool that uses LLM to automatically fix errors detected by static analysis tools (such as RuboCop)."
  spec.homepage = "https://github.com/kaibadash/llm_fixer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "bin"
  spec.executables = ["llm_fixer"]
  spec.require_paths = ["lib"]
  
  spec.add_dependency "colorize"
  spec.add_dependency "ruby-openai"
  spec.add_dependency "thor"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
end 