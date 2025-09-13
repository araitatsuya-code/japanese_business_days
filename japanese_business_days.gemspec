# frozen_string_literal: true

require_relative "lib/japanese_business_days/version"

Gem::Specification.new do |spec|
  spec.name = "japanese_business_days"
  spec.version = JapaneseBusinessDays::VERSION
  spec.authors = ["araitatsuya-code"]
  spec.email = ["rd0801577@gmail.com"]

  spec.summary = "Japanese business days calculation library"
  spec.description = "A Ruby library for calculating Japanese business days, handling national holidays, weekends, and custom business rules."
  spec.homepage = "https://github.com/araitatsuya-code/japanese_business_days"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/araitatsuya-code/japanese_business_days"
  spec.metadata["changelog_uri"] = "https://github.com/araitatsuya-code/japanese_business_days/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
