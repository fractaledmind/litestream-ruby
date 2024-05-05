# frozen_string_literal: true

require "rails/engine"

module Litestream
  class Engine < ::Rails::Engine
    isolate_namespace Litestream

    config.litestream = ActiveSupport::OrderedOptions.new

    # Load the `litestream:install` generator into the host Rails app
    generators do
      require_relative "generators/litestream/install_generator"
    end

    # Load the `litestream:*` Rake task into the host Rails app
    rake_tasks do
      load "tasks/litestream_tasks.rake"
    end

    initializer "litestream.config" do
      config.litestream.each do |name, value|
        Litestream.public_send(:"#{name}=", value)
      end
    end
  end
end
