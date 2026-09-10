require "json"
require "open3"
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

    # raised when a litestream command times out
    CommandTimeoutException = Class.new(CommandFailedException)

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
            unless @litestream_install_dir_noted
              warn "NOTE: using LITESTREAM_INSTALL_DIR to find litestream executable: #{litestream_install_dir}"
              @litestream_install_dir_noted = true
            end
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

      def ltx(database, **argv)
        raise DatabaseRequiredException, "database argument is required for ltx command, e.g. litestream:ltx -- --database=path/to/database.sqlite" if database.nil?

        execute("ltx", argv, database)
      end

      # Litestream 0.5 filters `status` by the absolute database path, while
      # `ltx` and `restore` match the path as written in the config file, so a
      # relative path is expanded here to keep the documented
      # `--database=storage/production.sqlite3` form working.
      def status(database = nil, **argv)
        execute("status", argv, database && File.expand_path(database))
      end

      def generations(*)
        raise CommandFailedException, "`generations` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)"
      end

      def snapshots(*)
        raise CommandFailedException, "`snapshots` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)"
      end

      def wal(*)
        raise CommandFailedException, "`wal` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)"
      end

      private

      def execute(command, argv = {}, database = nil, tabled_output: true)
        argv = argv.stringify_keys
        timeout = argv.delete("timeout")
        output = if argv.delete("json")
          argv["-json"] = nil
          :json
        elsif tabled_output
          :table
        else
          :raw
        end

        cmd = prepare(command, argv, database)
        run(cmd, output: output, timeout: timeout)
      end

      def prepare(command, argv = {}, database = nil)
        ENV["LITESTREAM_REPLICA_BUCKET"] ||= Litestream.replica_bucket
        ENV["LITESTREAM_REPLICA_REGION"] ||= Litestream.replica_region
        ENV["LITESTREAM_REPLICA_ENDPOINT"] ||= Litestream.replica_endpoint
        ENV["LITESTREAM_ACCESS_KEY_ID"] ||= Litestream.replica_key_id
        ENV["LITESTREAM_SECRET_ACCESS_KEY"] ||= Litestream.replica_access_key

        args = {
          "--config" => Litestream.config_path.to_s
        }.merge(argv.stringify_keys).to_a.flatten.compact.map(&:to_s)
        cmd = [executable, command, *args, database].compact.map(&:to_s)
        puts cmd.inspect if ENV["DEBUG"]

        cmd
      end

      # Runs the command without a shell and returns its parsed stdout. A non-zero
      # exit raises with stderr. With a timeout, the command runs in its own
      # process group and is killed (TERM, then KILL) when the deadline passes.
      def run(cmd, output:, timeout: nil)
        stdin, stdout, stderr, wait_thread = Open3.popen3(*cmd, pgroup: true)
        stdin.close
        stdout_reader = Thread.new { stdout.read }
        stderr_reader = Thread.new { stderr.read }

        # The readers finish when the last process holding the pipes exits, so
        # waiting on them covers descendants the direct child may have left behind.
        unless wait_thread.join(timeout) && stdout_reader.join(timeout) && stderr_reader.join(timeout)
          kill_process_group("TERM", wait_thread.pid)
          wait_thread.join(1)
          kill_process_group("KILL", wait_thread.pid)
          wait_thread.join
          [stdout_reader, stderr_reader].each(&:join)
          raise CommandTimeoutException, "Failed to execute `#{cmd[1]}`: timed out after #{timeout} seconds"
        end

        status = wait_thread.value
        unless status.success?
          raise CommandFailedException, "Failed to execute `#{cmd[1]}` (exit status #{status.exitstatus}): #{stderr_reader.value.strip[0, 500]}"
        end

        case output
        when :json then parse_json(cmd, stdout_reader.value)
        when :table then parse_table(stdout_reader.value)
        else stdout_reader.value
        end
      ensure
        [stdout_reader, stderr_reader].each { |reader| reader&.join }
        [stdin, stdout, stderr].each { |io| io&.close unless io&.closed? }
      end

      def kill_process_group(signal, pid)
        Process.kill(signal, -pid)
      rescue Errno::ESRCH
      end

      # Two opt-in restore skips (-if-db-not-exists when the output exists,
      # -if-replica-exists with no backups) exit 0 and print one logfmt line on
      # stdout instead of JSON. They come back as {"skipped" => true, "message" => ...}.
      def parse_json(cmd, stdout)
        stdout = stdout.strip
        return if stdout.empty?
        return JSON.parse(stdout) if stdout.start_with?("{", "[")

        skipped = stdout.match(/\Atime=\S+ level=\S+ msg=(?:"([^"]*)"|(\S+))/)
        return {"skipped" => true, "message" => skipped[1] || skipped[2]} if skipped

        raise CommandFailedException, "Unexpected output from `#{cmd[1]}`: #{stdout.lines.first.to_s.strip[0, 200]}"
      end

      def parse_table(stdout)
        keys, *rows = stdout.strip.split("\n").map { _1.split(/\s+/) }
        return [] unless keys

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
