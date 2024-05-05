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
