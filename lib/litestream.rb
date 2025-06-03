# frozen_string_literal: true

require "sqlite3"

module Litestream
  VerificationFailure = Class.new(StandardError)

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("0.12.0", "Litestream")
    end
  end

  def self.configure
    deprecator.warn(
      "Configuring Litestream via Litestream.configure is deprecated. Use Rails.application.configure { config.litestream.* = ... } instead.",
      caller
    )
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :replica_bucket, :replica_key_id, :replica_access_key

    def initialize
    end
  end

  mattr_writer :username, :password, :queue, :replica_bucket, :replica_region, :replica_endpoint, :replica_key_id, :replica_access_key, :systemctl_command,
    :config_path
  mattr_accessor :base_controller_class, default: "::ApplicationController"

  class << self
    def verify!(database_path, replication_sleep: 10)
      database = SQLite3::Database.new(database_path)
      database.execute("CREATE TABLE IF NOT EXISTS _litestream_verification (id INTEGER PRIMARY KEY, uuid BLOB)")
      sentinel = SecureRandom.uuid
      database.execute("INSERT INTO _litestream_verification (uuid) VALUES (?)", [sentinel])
      # give the Litestream replication process time to replicate the sentinel value
      sleep replication_sleep

      backup_path = "tmp/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{sentinel}.sqlite3"
      Litestream::Commands.restore(database_path, **{"-o" => backup_path})

      backup = SQLite3::Database.new(backup_path)
      result = backup.execute("SELECT 1 FROM _litestream_verification WHERE uuid = ? LIMIT 1", sentinel) # => [[1]] || []

      raise VerificationFailure, "Verification failed for `#{database_path}`" if result.empty?

      true
    ensure
      database.execute("DELETE FROM _litestream_verification WHERE uuid = ?", sentinel)
      database.close
      Dir.glob(backup_path + "*").each { |file| File.delete(file) }
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after Litestream is loaded
    def username
      ENV["LITESTREAM_USERNAME"] || @@username || "litestream"
    end

    def password
      ENV["LITESTREAM_PASSWORD"] || @@password
    end

    def queue
      ENV["LITESTREAM_QUEUE"] || @@queue || "default"
    end

    def replica_bucket
      @@replica_bucket || configuration.replica_bucket
    end

    def replica_region
      @@replica_region
    end

    def replica_endpoint
      @@replica_endpoint
    end

    def replica_key_id
      @@replica_key_id || configuration.replica_key_id
    end

    def replica_access_key
      @@replica_access_key || configuration.replica_access_key
    end

    def systemctl_command
      @@systemctl_command || "systemctl status litestream"
    end

    def config_path
      @@config_path || Rails.root.join("config", "litestream.yml")
    end

    def replicate_process
      systemctl_info || process_info || {}
    end

    def databases
      databases = Commands.databases

      databases.each do |db|
        generations = Commands.generations(db["path"])
        snapshots = Commands.snapshots(db["path"])
        db["path"] = db["path"].gsub(Rails.root.to_s, "[ROOT]")

        db["generations"] = generations.map do |generation|
          id = generation["generation"]
          replica = generation["name"]
          generation["snapshots"] = snapshots.select { |snapshot| snapshot["generation"] == id && snapshot["replica"] == replica }
            .map { |s| s.slice("index", "size", "created") }
          generation.slice("generation", "name", "lag", "start", "end", "snapshots")
        end
      end
    end

    private

    def systemctl_info
      return if `which systemctl`.empty?

      systemctl_output = `#{Litestream.systemctl_command}`
      systemctl_exit_code = $?.exitstatus
      return unless systemctl_exit_code.zero?

      # ["● litestream.service - Litestream",
      #  "     Loaded: loaded (/lib/systemd/system/litestream.service; enabled; vendor preset: enabled)",
      #  "     Active: active (running) since Tue 2023-07-25 13:49:43 UTC; 8 months 24 days ago",
      #  "   Main PID: 1179656 (litestream)",
      #  "      Tasks: 9 (limit: 1115)",
      #  "     Memory: 22.9M",
      #  "        CPU: 10h 49.843s",
      #  "     CGroup: /system.slice/litestream.service",
      #  "             └─1179656 /usr/bin/litestream replicate",
      #  "",
      #  "Warning: some journal files were not opened due to insufficient permissions."]

      info = {}
      systemctl_output.chomp.split("\n").each do |line|
        line.strip!
        if line.start_with?("Main PID:")
          _key, value = line.split(":")
          pid, _name = value.strip.split(" ")
          info[:pid] = pid
        elsif line.start_with?("Active:")
          value, _ago = line.split(";")
          status, timestamp = value.split(" since ")
          info[:started] = DateTime.strptime(timestamp.strip, "%a %Y-%m-%d %H:%M:%S %Z")
          status_match = status.match(%r{\((?<status>.*)\)})
          info[:status] = status_match ? status_match[:status] : nil
        end
      end
      info
    end

    def process_info
      litestream_replicate_ps = `ps -ax | grep litestream | grep replicate`
      exit_code = $?.exitstatus
      return unless exit_code.zero?

      info = {}
      litestream_replicate_ps.chomp.split("\n").each do |line|
        next unless line.include?("litestream replicate")

        pid, * = line.split(" ")
        info[:pid] = pid
        state, _, lstart = `ps -o "state,lstart" #{pid}`.chomp.split("\n").last.partition(/\s+/)

        info[:status] = case state[0]
        when "I" then "idle"
        when "R" then "running"
        when "S" then "sleeping"
        when "T" then "stopped"
        when "U" then "uninterruptible"
        when "Z" then "zombie"
        end
        info[:started] = DateTime.strptime(lstart.strip, "%a %b %d %H:%M:%S %Y")
      end
      info
    end
  end
end

require_relative "litestream/version"
require_relative "litestream/upstream"
require_relative "litestream/commands"
require_relative "litestream/engine" if defined?(::Rails::Engine)
