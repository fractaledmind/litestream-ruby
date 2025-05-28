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

  spec.files = Dir["{app,config,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  spec.bindir = "exe"
  spec.executables << "litestream"

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "sqlite3"
  ">= 7.0".tap do |rails_version|
    spec.add_dependency "actionpack", rails_version
    spec.add_dependency "actionview", rails_version
    spec.add_dependency "activejob", rails_version
    spec.add_dependency "activesupport", rails_version
    spec.add_dependency "railties", rails_version
  end
  spec.add_development_dependency "rails"
  spec.add_development_dependency "rubyzip"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
