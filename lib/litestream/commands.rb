require_relative "upstream"

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

    module Output
      class << self
        def format(data)
          return "" if data.nil? || data.empty?

          headers = data.first.keys.map(&:to_s)
          widths = headers.map.with_index { |h, i|
            [h.length, data.map { |r| r[data.first.keys[i]].to_s.length }.max].max
          }

          format_str = widths.map { |w| "%-#{w}s" }.join("  ")
          ([headers] + data.map(&:values)).map { |row|
            sprintf(format_str, *row.map(&:to_s))
          }.join("\n")
        end
      end
    end

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

      # Replicate can be run either as a fork or in the same process, depending on the context.
      # Puma will start replication as a forked process, while running replication from a rake
      # tasks won't.
      def replicate(async: false, **argv)
        cmd = prepare("replicate", argv)
        run_replicate(cmd, async: async)
      rescue
        raise CommandFailedException, "Failed to execute `#{cmd.join(" ")}`"
      end

      def restore(database, **argv)
        raise DatabaseRequiredException, "database argument is required for restore command, e.g. litestream:restore -- --database=path/to/database.sqlite" if database.nil?

        execute("restore", argv, database, tabled_output: false)
      end

      def databases(**argv)
        execute("databases", argv)
      end

      def generations(database, **argv)
        raise DatabaseRequiredException, "database argument is required for generations command, e.g. litestream:generations -- --database=path/to/database.sqlite" if database.nil?

        execute("generations", argv, database)
      end

      def snapshots(database, **argv)
        raise DatabaseRequiredException, "database argument is required for snapshots command, e.g. litestream:snapshots -- --database=path/to/database.sqlite" if database.nil?

        execute("snapshots", argv, database)
      end

      def wal(database, **argv)
        raise DatabaseRequiredException, "database argument is required for wal command, e.g. litestream:wal -- --database=path/to/database.sqlite" if database.nil?

        execute("wal", argv, database)
      end

      private

      def execute(command, argv = {}, database = nil, tabled_output: true)
        cmd = prepare(command, argv, database)
        results = run(cmd, tabled_output: tabled_output)

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

      def run(cmd, tabled_output:)
        stdout = `#{cmd.join(" ")}`.chomp
        return stdout unless tabled_output

        keys, *rows = stdout.split("\n").map { _1.split(/\s+/) }
        rows.map { keys.zip(_1).to_h }
      end

      def run_replicate(cmd, async:)
        if async
          exec(*cmd) if fork.nil?
        else
          # When running in-process, we capture output continuously and write to stdout.
          IO.popen(cmd, err: [:child, :out]) do |io|
            io.each_line { |line| puts line }
          end
        end
      end
    end
  end
end
