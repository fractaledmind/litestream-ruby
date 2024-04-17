# frozen_string_literal: true

module Litestream
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :database_path, :replica_bucket, :replica_key_id, :replica_access_key

    def initialize
    end
  end
end

require_relative "litestream/version"
require_relative "litestream/upstream"
require_relative "litestream/commands"
require_relative "litestream/railtie" if defined?(::Rails::Railtie)
