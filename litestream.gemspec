# frozen_string_literal: true

require_relative "lib/litestream/version"

Gem::Specification.new do |spec|
  spec.name = "litestream"
  spec.version = Litestream::VERSION
  spec.authors = ["Stephen Margheim"]
  spec.email = ["stephen.margheim@gmail.com"]

  spec.summary = "Integrate Litestream with the RubyGems infrastructure."
  spec.homepage = "https://github.com/fractaledmind/litestream-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "https://github.com/fractaledmind/litestream-ruby/CHANGELOG.md"
  }

  spec.files = Dir["lib/**/*", "LICENSE", "Rakefile", "README.md"]
  spec.bindir = "exe"
  spec.executables << "litestream"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_development_dependency "rubyzip"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "sqlite3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
