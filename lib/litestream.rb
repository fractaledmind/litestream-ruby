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
    attr_accessor :replica_bucket, :replica_key_id, :replica_access_key

    def initialize
    end
  end

  mattr_writer :username
  mattr_writer :password

  class << self
    # use method instead of attr_accessor to ensure
    # this works if variable set after Litestream is loaded
    def username
      @username ||= ENV["LITESTREAM_USERNAME"] || @@username
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after Litestream is loaded
    def password
      @password ||= ENV["LITESTREAM_PASSWORD"] || @@password
    end

    def replicate_process
      info = {}
      if !`which systemctl`.empty?
        systemctl_status = `systemctl status litestream`.chomp
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
        systemctl_status.split("\n").each do |line|
          line.strip!
          if line.start_with?("Main PID:")
            _key, value = line.split(":")
            pid, _name = value.strip.split(" ")
            info[:pid] = pid
          elsif line.start_with?("Active:")
            _key, value = line.split(":")
            value, _ago = value.split(";")
            status, timestamp = value.split(" since ")
            info[:started] = DateTime.strptime(timestamp.strip, "%Y-%m-%d %H:%M:%S %Z")
            info[:status] = status.split("(").first.strip
          end
        end
      else
        litestream_replicate_ps = `ps -a | grep litestream | grep replicate`.chomp
        litestream_replicate_ps.split("\n").each do |line|
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
      end
      info
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
  end
end

require_relative "litestream/version"
require_relative "litestream/upstream"
require_relative "litestream/commands"
require_relative "litestream/engine" if defined?(::Rails::Engine)
