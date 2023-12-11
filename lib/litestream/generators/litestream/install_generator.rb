# frozen_string_literal: true

require "rails/generators/base"

module Litestream
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_config_file
        template "litestream.yml", "config/litestream.yml"
      end

      def copy_initializer_file
        template "litestream.rb", "config/initializers/litestream.rb"
      end

      def create_or_update_procfile
        if File.exist?("Procfile")
          append_to_file "Procfile", "litestream: bin/rails litestream:replicate"
        else
          create_file "Procfile" do
            <<~PROCFILE
              rails: bundle exec rails server --port $PORT
              litestream: bin/rails litestream:replicate
            PROCFILE
          end
        end
      end
    end
  end
end
