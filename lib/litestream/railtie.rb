# frozen_string_literal: true

require "rails/railtie"

module Litestream
  class Railtie < ::Rails::Railtie
    # Load the `litestream:install` generator into the host Rails app
    generators do
      require_relative "generators/litestream/install_generator"
    end

    # Load the `litestream:*` Rake task into the host Rails app
    rake_tasks do
      load "tasks/litestream_tasks.rake"
    end
  end
end
