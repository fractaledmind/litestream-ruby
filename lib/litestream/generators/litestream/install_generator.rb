# frozen_string_literal: true

require "rails/generators/base"

module Litestream
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_config_file
        template "config.yml.erb", "config/litestream.yml"
      end

      def copy_initializer_file
        template "initializer.rb", "config/initializers/litestream.rb"
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

      private

      def production_sqlite_databases
        ActiveRecord::Base
          .configurations
          .configs_for(env_name: "production", include_hidden: true)
          .select { |config| ["sqlite3", "litedb"].include? config.adapter }
          .map(&:database)
      end
    end
  end
end
