require "test_helper"
require "fileutils"
require "tmpdir"

class TestCommands < ActiveSupport::TestCase
  def run
    result = nil
    Litestream::Commands.stub :fork, nil do
      Litestream::Commands.stub :executable, "exe/test/litestream" do
        capture_io { result = super }
      end
    end
    result
  end

  def teardown
    Litestream.replica_bucket = ENV["LITESTREAM_REPLICA_BUCKET"] = nil
    Litestream.replica_key_id = ENV["LITESTREAM_ACCESS_KEY_ID"] = nil
    Litestream.replica_access_key = ENV["LITESTREAM_SECRET_ACCESS_KEY"] = nil
    Litestream.config_path = nil
  end

  class TestReplicateCommand < TestCommands
    def test_replicate_with_no_options
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 2, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
      end
      Litestream::Commands.stub :run_replicate, stub do
        Litestream::Commands.replicate
      end
    end

    def test_replicate_with_boolean_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--no-expand-env", argv[2]
      end
      Litestream::Commands.stub :run_replicate, stub do
        Litestream::Commands.replicate("--no-expand-env" => nil)
      end
    end

    def test_replicate_with_string_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--exec", argv[2]
        assert_equal "command", argv[3]
      end
      Litestream::Commands.stub :run_replicate, stub do
        Litestream::Commands.replicate("--exec" => "command")
      end
    end

    def test_replicate_with_symbol_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--exec", argv[2]
        assert_equal "command", argv[3]
      end
      Litestream::Commands.stub :run_replicate, stub do
        Litestream::Commands.replicate("--exec": "command")
      end
    end

    def test_replicate_with_config_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 2, argv.size
        assert_equal "--config", argv[0]
        assert_equal "CONFIG", argv[1]
      end
      Litestream::Commands.stub :run_replicate, stub do
        Litestream::Commands.replicate("--config" => "CONFIG")
      end
    end

    def test_replicate_sets_replica_bucket_env_var_from_config_when_env_var_not_set
      Litestream.replica_bucket = "mybkt"

      Litestream::Commands.stub :run_replicate, nil do
        Litestream::Commands.replicate
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_replicate_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.replica_key_id = "mykey"

      Litestream::Commands.stub :run_replicate, nil do
        Litestream::Commands.replicate
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_replicate_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run_replicate, nil do
        Litestream::Commands.replicate
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_replicate_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.replica_bucket = "mybkt"
      Litestream.replica_key_id = "mykey"
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run_replicate, nil do
        Litestream::Commands.replicate
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_replicate_does_not_set_env_var_from_config_when_env_vars_already_set
      ENV["LITESTREAM_REPLICA_BUCKET"] = "original_bkt"
      ENV["LITESTREAM_ACCESS_KEY_ID"] = "original_key"
      ENV["LITESTREAM_SECRET_ACCESS_KEY"] = "original_access"

      Litestream.replica_bucket = "mybkt"
      Litestream.replica_key_id = "mykey"
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run_replicate, nil do
        Litestream::Commands.replicate
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end
  end

  class TestRestoreCommand < TestCommands
    def test_restore_with_no_options
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "db/test.sqlite3", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.restore("db/test.sqlite3")
      end
    end

    def test_restore_with_boolean_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--if-db-not-exists", argv[2]
        assert_equal "db/test.sqlite3", argv[3]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.restore("db/test.sqlite3", "--if-db-not-exists" => nil)
      end
    end

    def test_restore_with_string_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 5, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--parallelism", argv[2]
        assert_equal "10", argv[3]
        assert_equal "db/test.sqlite3", argv[4]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.restore("db/test.sqlite3", "--parallelism" => 10)
      end
    end

    def test_restore_with_config_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_equal "CONFIG", argv[1]
        assert_equal "db/test.sqlite3", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.restore("db/test.sqlite3", "--config" => "CONFIG")
      end
    end

    def test_restore_sets_replica_bucket_env_var_from_config_when_env_var_not_set
      Litestream.replica_bucket = "mybkt"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_restore_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.replica_key_id = "mykey"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_restore_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_restore_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.replica_bucket = "mybkt"
      Litestream.replica_key_id = "mykey"
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_restore_does_not_set_env_var_from_config_when_env_vars_already_set
      ENV["LITESTREAM_REPLICA_BUCKET"] = "original_bkt"
      ENV["LITESTREAM_ACCESS_KEY_ID"] = "original_key"
      ENV["LITESTREAM_SECRET_ACCESS_KEY"] = "original_access"

      Litestream.replica_bucket = "mybkt"
      Litestream.replica_key_id = "mykey"
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end
  end

  class TestDatabasesCommand < TestCommands
    def test_databases_with_no_options
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "databases", command
        assert_equal 2, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.databases
      end
    end

    def test_databases_with_boolean_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "databases", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--no-expand-env", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.databases("--no-expand-env" => nil)
      end
    end

    def test_databases_with_string_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "databases", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--exec", argv[2]
        assert_equal "command", argv[3]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.databases("--exec" => "command")
      end
    end

    def test_databases_with_config_option
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "databases", command
        assert_equal 2, argv.size
        assert_equal "--config", argv[0]
        assert_equal "CONFIG", argv[1]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.databases("--config" => "CONFIG")
      end
    end

    def test_databases_sets_replica_bucket_env_var_from_config_when_env_var_not_set
      Litestream.replica_bucket = "mybkt"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.replica_key_id = "mykey"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.replica_bucket = "mybkt"
      Litestream.replica_key_id = "mykey"
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_does_not_set_env_var_from_config_when_env_vars_already_set
      ENV["LITESTREAM_REPLICA_BUCKET"] = "original_bkt"
      ENV["LITESTREAM_ACCESS_KEY_ID"] = "original_key"
      ENV["LITESTREAM_SECRET_ACCESS_KEY"] = "original_access"

      Litestream.replica_bucket = "mybkt"
      Litestream.replica_key_id = "mykey"
      Litestream.replica_access_key = "access"

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_read_from_custom_configured_litestream_config_path
      Litestream.config_path = "dummy/config/litestream/production.yml"

      stub = proc do |cmd, _async|
        _executable, _command, *argv = cmd

        assert_equal 2, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream/production.yml"), argv[1]
      end

      Litestream::Commands.stub :run, stub do
        Litestream::Commands.databases
      end
    end
  end

  class TestLtxCommand < TestCommands
    def test_ltx_with_no_options
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "ltx", command
        assert_equal ["--config", Rails.root.join("config/litestream.yml").to_s, "db/test.sqlite3"], argv
      end

      Litestream::Commands.stub :run, stub do
        Litestream::Commands.ltx("db/test.sqlite3")
      end
    end

    def test_ltx_with_options
      stub = proc do |cmd|
        assert_equal ["--config", "CONFIG", "--level", "all", "-json", "db/test.sqlite3"], cmd.drop(2)
      end

      Litestream::Commands.stub :run, stub do
        Litestream::Commands.ltx("db/test.sqlite3", "--config" => "CONFIG", "--level" => "all", :json => true)
      end
    end

    def test_ltx_requires_database
      error = assert_raises Litestream::Commands::DatabaseRequiredException do
        Litestream::Commands.ltx(nil)
      end

      assert_match "database argument is required for ltx command", error.message
    end
  end

  class TestStatusCommand < TestCommands
    def test_status_with_no_database
      stub = proc do |cmd|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "status", command
        assert_equal ["--config", Rails.root.join("config/litestream.yml").to_s], argv
      end

      Litestream::Commands.stub :run, stub do
        Litestream::Commands.status
      end
    end

    def test_status_expands_a_relative_database_path
      stub = proc do |cmd|
        assert_equal File.expand_path("db/test.sqlite3"), cmd.last
      end

      Litestream::Commands.stub :run, stub do
        Litestream::Commands.status("db/test.sqlite3")
      end
    end

    def test_status_with_database_and_options
      stub = proc do |cmd|
        assert_equal ["--config", "CONFIG", "--no-expand-env", "-json", File.expand_path("db/test.sqlite3")], cmd.drop(2)
      end

      Litestream::Commands.stub :run, stub do
        Litestream::Commands.status("db/test.sqlite3", "--config" => "CONFIG", "--no-expand-env" => nil, :json => true)
      end
    end
  end

  class TestRemovedCommands < TestCommands
    %w[generations snapshots wal].each do |command|
      define_method(:"test_#{command}_raises_with_migration_message") do
        error = assert_raises Litestream::Commands::CommandFailedException do
          Litestream::Commands.public_send(command, "db/test.sqlite3")
        end

        assert_equal "`#{command}` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)", error.message
      end
    end
  end

  class TestRunner < ActiveSupport::TestCase
    def setup
      @tmpdir = Dir.mktmpdir
      @litestream_install_dir = ENV["LITESTREAM_INSTALL_DIR"]
      @executable = File.join(@tmpdir, "litestream")
      File.write(@executable, <<~SH)
        #!/bin/sh
        shift
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --table)
              printf 'path                 replica\n/tmp/app.sqlite3     s3\n'
              exit 0
              ;;
            --json-object)
              printf '{"txid":"abc123"}\n'
              printf 'time=2026-01-01T00:00:00Z level=INFO msg="restore complete"\n' >&2
              exit 0
              ;;
            --json-array)
              printf '[{"path":"/tmp/app.sqlite3","replica":"s3"}]\n'
              exit 0
              ;;
            --json-empty-list)
              printf '[]\n'
              exit 0
              ;;
            --json-empty)
              exit 0
              ;;
            --skip-db)
              printf 'time=2026-01-01T00:00:00Z level=INFO msg="database already exists, skipping"\n'
              exit 0
              ;;
            --skip-replica)
              printf 'time=2026-01-01T00:00:00Z level=INFO msg="no matching backups found"\n'
              exit 0
              ;;
            --fail)
              printf 'Error: database not found in config\n' >&2
              exit 7
              ;;
            --echo)
              shift
              printf '%s\n' "$1"
              exit 0
              ;;
            --sleep)
              shift
              printf '%s\n' "$$" > "$1"
              sleep 30
              exit 0
              ;;
            --sleep-in-child)
              shift
              (trap '' TERM; printf '%s\n' "$$" > "$1"; sleep 30) &
              exit 0
              ;;
          esac
          shift
        done
      SH
      File.chmod(0o755, @executable)
      Litestream.config_path = File.join(@tmpdir, "litestream.yml")
    end

    def teardown
      if @litestream_install_dir
        ENV["LITESTREAM_INSTALL_DIR"] = @litestream_install_dir
      else
        ENV.delete("LITESTREAM_INSTALL_DIR")
      end
      Litestream::Commands.remove_instance_variable(:@litestream_install_dir_noted) if Litestream::Commands.instance_variable_defined?(:@litestream_install_dir_noted)
      Litestream.config_path = nil
      FileUtils.remove_entry(@tmpdir)
    end

    def test_successful_table_output
      assert_equal [{"path" => "/tmp/app.sqlite3", "replica" => "s3"}], run_with_fake { Litestream::Commands.databases("--table" => nil) }
    end

    def test_successful_json_object
      assert_equal({"txid" => "abc123"}, run_with_fake { Litestream::Commands.restore("db.sqlite3", json: true, "--json-object": nil) })
    end

    def test_successful_json_array
      expected = [{"path" => "/tmp/app.sqlite3", "replica" => "s3"}]

      assert_equal expected, run_with_fake { Litestream::Commands.databases(json: true, "--json-array": nil) }
    end

    def test_empty_json_list
      assert_equal [], run_with_fake { Litestream::Commands.databases("json" => true, "--json-empty-list" => nil) }
    end

    def test_empty_json_output
      assert_nil run_with_fake { Litestream::Commands.databases("json" => true, "--json-empty" => nil) }
    end

    def test_if_db_not_exists_skip_output
      expected = {"skipped" => true, "message" => "database already exists, skipping"}

      assert_equal expected, run_with_fake { Litestream::Commands.restore("db.sqlite3", json: true, "--skip-db": nil) }
    end

    def test_if_replica_exists_skip_output
      expected = {"skipped" => true, "message" => "no matching backups found"}

      assert_equal expected, run_with_fake { Litestream::Commands.restore("db.sqlite3", json: true, "--skip-replica": nil) }
    end

    def test_nonzero_exit_raises_with_status_and_stderr
      error = assert_raises(Litestream::Commands::CommandFailedException) do
        run_with_fake { Litestream::Commands.databases("--fail" => nil) }
      end

      assert_includes error.message, "databases"
      assert_includes error.message, "exit status 7"
      assert_includes error.message, "Error: database not found in config"
    end

    def test_argument_with_space_is_passed_intact
      output = run_with_fake { Litestream::Commands.restore("db.sqlite3", "--echo" => "argument with space") }

      assert_equal "argument with space\n", output
    end

    def test_timeout_kills_and_reaps_child
      pid_file = File.join(@tmpdir, "pid")

      assert_raises(Litestream::Commands::CommandTimeoutException) do
        run_with_fake { Litestream::Commands.databases(**{"timeout" => 0.1, "--sleep" => pid_file}) }
      end

      pid = wait_for_pid(pid_file)
      assert_raises(Errno::ECHILD) { Process.wait(pid, Process::WNOHANG) }
    end

    def test_timeout_kills_a_descendant_that_outlives_the_direct_child
      pid_file = File.join(@tmpdir, "pid")

      assert_raises(Litestream::Commands::CommandTimeoutException) do
        run_with_fake { Litestream::Commands.databases(**{"timeout" => 0.1, "--sleep-in-child" => pid_file}) }
      end

      pid = wait_for_pid(pid_file)
      sleep 0.05
      assert_raises(Errno::ESRCH) { Process.kill(0, pid) }
    end

    def test_integer_option_values_are_passed_as_strings
      output = run_with_fake { Litestream::Commands.restore("/tmp/app.sqlite3", "--echo" => 10) }

      assert_equal "10\n", output
    end

    def test_install_dir_note_is_printed_once
      ENV["LITESTREAM_INSTALL_DIR"] = @tmpdir

      _stdout, stderr = capture_io do
        Litestream::Commands.executable
        Litestream::Commands.executable
      end

      assert_equal 1, stderr.scan("NOTE: using LITESTREAM_INSTALL_DIR").size
    end

    private

    def run_with_fake(&block)
      Litestream::Commands.stub(:executable, @executable, &block)
    end

    def wait_for_pid(pid_file)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
      until File.exist?(pid_file) && !File.read(pid_file).strip.empty?
        flunk "fake litestream never wrote its pid" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.01
      end
      pid = File.read(pid_file).to_i
      assert_operator pid, :>, 0
      pid
    end
  end

  class TestOutput < ActiveSupport::TestCase
    def test_output_formatting_generates_table_with_data
      data = [
        {path: "/storage/database.db", replica: "s3"},
        {path: "/storage/another-database.db", replica: "s3"}
      ]

      result = Litestream::Commands::Output.format(data)
      lines = result.split("\n")

      assert_equal 3, lines.length

      assert_includes lines[0], "path"
      assert_includes lines[0], "replica"
      assert_includes lines[1], "/storage/database.db"
      assert_includes lines[2], "/storage/another-database.db"
    end

    def test_output_formatting_generates_formatted_table
      data = [
        {path: "/storage/database.db", replica: "s3"},
        {path: "/storage/another-database.db", replica: "s3"}
      ]

      result = Litestream::Commands::Output.format(data)
      lines = result.split("\n")

      replica_pos = lines[0].index("replica")
      assert_equal replica_pos, lines[1].index("s3")
      assert_equal replica_pos, lines[2].index("s3")
    end
  end
end
