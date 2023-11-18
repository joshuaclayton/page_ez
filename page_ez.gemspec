# frozen_string_literal: true

require_relative "lib/page_ez/version"

Gem::Specification.new do |spec|
  spec.name = "page_ez"
  spec.version = PageEz::VERSION
  spec.authors = ["Josh Clayton"]
  spec.email = ["joshua.clayton@gmail.com"]

  spec.summary = "PageEz is a tool to define page objects with Capybara"
  spec.description = "PageEz is a tool to define page objects with Capybara"
  spec.homepage = "https://github.com/joshuaclayton/page_ez"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/joshuaclayton/page_ez"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capybara", "~> 3.0"
  spec.add_runtime_dependency "activesupport", "> 5.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "sinatra", "~> 3.0"
  spec.add_development_dependency "selenium-webdriver", "~> 4.10"
  spec.add_development_dependency "puma", "~> 6.3"
  spec.add_development_dependency "launchy", "~> 2.5"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-lcov", "~> 0.8"
end
