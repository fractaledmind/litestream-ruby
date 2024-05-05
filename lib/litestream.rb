# frozen_string_literal: true

require "sqlite3"

module Litestream
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :replica_bucket, :replica_key_id, :replica_access_key

    def initialize
    end
  end

  VerificationFailure = Class.new(StandardError)

  def self.verify!(database_path)
    database = SQLite3::Database.new(database_path)
    database.execute("CREATE TABLE IF NOT EXISTS _litestream_verification (id INTEGER PRIMARY KEY, uuid BLOB)")
    sentinel = SecureRandom.uuid
    database.execute("INSERT INTO _litestream_verification (uuid) VALUES (?)", [sentinel])
    # give the Litestream replication process time to replicate the sentinel value
    sleep 10

    backup_path = "tmp/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{sentinel}.sqlite3"
    Litestream::Commands.restore(database_path, **{"-o" => backup_path})

    backup = SQLite3::Database.new(backup_path)
    result = backup.execute("SELECT 1 FROM _litestream_verification WHERE uuid = ? LIMIT 1", sentinel) # => [[1]] || []

    raise VerificationFailure, "Verification failed, sentinel not found" if result.empty?
  ensure
    database.execute("DELETE FROM _litestream_verification WHERE uuid = ?", sentinel)
    database.close
    Dir.glob(backup_path + "*").each { |file| File.delete(file) }
  end
end

require_relative "litestream/version"
require_relative "litestream/upstream"
require_relative "litestream/commands"
require_relative "litestream/railtie" if defined?(::Rails::Railtie)
