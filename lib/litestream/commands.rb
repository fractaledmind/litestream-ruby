require_relative "upstream"
require "logfmt"

module Litestream
  module Commands
    DEFAULT_DIR = File.expand_path(File.join(__dir__, "..", "..", "exe"))
    GEM_NAME = "litestream"

    # raised when the host platform is not supported by upstream litestream's binary releases
    UnsupportedPlatformException = Class.new(StandardError)

    # raised when the litestream executable could not be found where we expected it to be
    ExecutableNotFoundException = Class.new(StandardError)

    # raised when LITESTREAM_INSTALL_DIR does not exist
    DirectoryNotFoundException = Class.new(StandardError)

    # raised when a litestream command requires a database argument but it isn't provided
    DatabaseRequiredException = Class.new(StandardError)

    # raised when a litestream command fails
    CommandFailedException = Class.new(StandardError)

    class << self
      def platform
        [:cpu, :os].map { |m| Gem::Platform.local.send(m) }.join("-")
      end

      def executable(exe_path: DEFAULT_DIR)
        litestream_install_dir = ENV["LITESTREAM_INSTALL_DIR"]
        if litestream_install_dir
          if File.directory?(litestream_install_dir)
            warn "NOTE: using LITESTREAM_INSTALL_DIR to find litestream executable: #{litestream_install_dir}"
            exe_path = litestream_install_dir
            exe_file = File.expand_path(File.join(litestream_install_dir, "litestream"))
          else
            raise DirectoryNotFoundException, <<~MESSAGE
              LITESTREAM_INSTALL_DIR is set to #{litestream_install_dir}, but that directory does not exist.
            MESSAGE
          end
        else
          if Litestream::Upstream::NATIVE_PLATFORMS.keys.none? { |p| Gem::Platform.match_gem?(Gem::Platform.new(p), GEM_NAME) }
            raise UnsupportedPlatformException, <<~MESSAGE
              litestream-ruby does not support the #{platform} platform
              Please install litestream following instructions at https://litestream.io/install
            MESSAGE
          end

          exe_file = Dir.glob(File.expand_path(File.join(exe_path, "*", "litestream"))).find do |f|
            Gem::Platform.match_gem?(Gem::Platform.new(File.basename(File.dirname(f))), GEM_NAME)
          end
        end

        if exe_file.nil? || !File.exist?(exe_file)
          raise ExecutableNotFoundException, <<~MESSAGE
            Cannot find the litestream executable for #{platform} in #{exe_path}

            If you're using bundler, please make sure you're on the latest bundler version:

                gem install bundler
                bundle update --bundler

            Then make sure your lock file includes this platform by running:

                bundle lock --add-platform #{platform}
                bundle install

            See `bundle lock --help` output for details.

            If you're still seeing this message after taking those steps, try running
            `bundle config` and ensure `force_ruby_platform` isn't set to `true`. See
            https://github.com/fractaledmind/litestream-ruby#check-bundle_force_ruby_platform
            for more details.
          MESSAGE
        end

        exe_file
      end

      def replicate(async: false, **argv)
        execute("replicate", argv, async: async, tabled_output: false)
      end

      def restore(database, async: false, **argv)
        raise DatabaseRequiredException, "database argument is required for restore command, e.g. litestream:restore -- --database=path/to/database.sqlite" if database.nil?
        argv.stringify_keys!

        execute("restore", argv, database, async: async, tabled_output: false)
      end

      def databases(async: false, **argv)
        execute("databases", argv, async: async, tabled_output: true)
      end

      def generations(database, async: false, **argv)
        raise DatabaseRequiredException, "database argument is required for generations command, e.g. litestream:generations -- --database=path/to/database.sqlite" if database.nil?

        execute("generations", argv, database, async: async, tabled_output: true)
      end

      def snapshots(database, async: false, **argv)
        raise DatabaseRequiredException, "database argument is required for snapshots command, e.g. litestream:snapshots -- --database=path/to/database.sqlite" if database.nil?

        execute("snapshots", argv, database, async: async, tabled_output: true)
      end

      def wal(database, async: false, **argv)
        raise DatabaseRequiredException, "database argument is required for wal command, e.g. litestream:wal -- --database=path/to/database.sqlite" if database.nil?

        execute("wal", argv, database, async: async, tabled_output: true)
      end

      private

      def execute(command, argv = {}, database = nil, async: false, tabled_output: false)
        cmd = prepare(command, argv, database)
        results = run(cmd, async: async, tabled_output: tabled_output)

        if Array === results && results.one? && results[0]["level"] == "ERROR"
          raise CommandFailedException, "Failed to execute `#{cmd.join(" ")}`; Reason: #{results[0]["error"]}"
        else
          results
        end
      end

      def prepare(command, argv = {}, database = nil)
        ENV["LITESTREAM_REPLICA_BUCKET"] ||= Litestream.replica_bucket
        ENV["LITESTREAM_REPLICA_REGION"] ||= Litestream.replica_region
        ENV["LITESTREAM_REPLICA_ENDPOINT"] ||= Litestream.replica_endpoint
        ENV["LITESTREAM_ACCESS_KEY_ID"] ||= Litestream.replica_key_id
        ENV["LITESTREAM_SECRET_ACCESS_KEY"] ||= Litestream.replica_access_key

        args = {
          "--config" => Litestream.config_path.to_s
        }.merge(argv.stringify_keys).to_a.flatten.compact
        cmd = [executable, command, *args, database].compact
        puts cmd.inspect if ENV["DEBUG"]

        cmd
      end

      def run(cmd, async: false, tabled_output: false)
        if async
          # To release the resources of the Ruby process, just fork and exit.
          # The forked process executes litestream and replaces itself.
          exec(*cmd) if fork.nil?
        else
          stdout = `#{cmd.join(" ")}`.chomp
          tabled_output ? text_table_to_hashes(stdout) : stdout.split("\n").map { Logfmt.parse(_1) }
        end
      end

      def text_table_to_hashes(string)
        keys, *rows = string.split("\n").map { _1.split(/\s+/) }
        rows.map { keys.zip(_1).to_h }
      end
    end
  end
end
