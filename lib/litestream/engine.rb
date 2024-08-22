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

    initializer "litestream.config" do
      config.litestream.each do |name, value|
        Litestream.public_send(:"#{name}=", value)
      end
    end

    initializer "deprecator" do |app|
      app.deprecators[:litestream] = Litestream.deprecator
    end
  end
end
