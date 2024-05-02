require "test_helper"

class TestCommands < ActiveSupport::TestCase
  def run
    result = nil
    Litestream::Commands.stub :fork, nil do
      Litestream::Commands.stub :executable, "exe/test/litestream" do
        # capture_io { result = super }
        result = super
      end
    end
    result
  end

  def teardown
    Litestream.configuration = nil
    ENV["LITESTREAM_REPLICA_BUCKET"] = nil
    ENV["LITESTREAM_ACCESS_KEY_ID"] = nil
    ENV["LITESTREAM_SECRET_ACCESS_KEY"] = nil
  end

  class TestReplicateCommand < TestCommands
    def test_replicate_with_no_options
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 2, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.replicate
      end
    end

    def test_replicate_with_boolean_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--no-expand-env", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.replicate("--no-expand-env" => nil)
      end
    end

    def test_replicate_with_string_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--exec", argv[2]
        assert_equal "command", argv[3]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.replicate("--exec" => "command")
      end
    end

    def test_replicate_with_symbol_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--exec", argv[2]
        assert_equal "command", argv[3]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.replicate("--exec": "command")
      end
    end

    def test_replicate_with_config_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "replicate", command
        assert_equal 2, argv.size
        assert_equal "--config", argv[0]
        assert_equal "CONFIG", argv[1]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.replicate("--config" => "CONFIG")
      end
    end

    def test_replicate_sets_replica_bucket_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.replicate
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_replicate_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_key_id = "mykey"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.replicate
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_replicate_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.replicate
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_replicate_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
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

      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.replicate
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end
  end

  class TestRestoreCommand < TestCommands
    def test_restore_with_no_options
      stub = proc do |cmd, async|
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
      stub = proc do |cmd, async|
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
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 5, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--parallelism", argv[2]
        assert_equal 10, argv[3]
        assert_equal "db/test.sqlite3", argv[4]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.restore("db/test.sqlite3", "--parallelism" => 10)
      end
    end

    def test_restore_with_config_option
      stub = proc do |cmd, async|
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
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_restore_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_key_id = "mykey"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_restore_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.restore("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_restore_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

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

      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

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
      stub = proc do |cmd, async|
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
      stub = proc do |cmd, async|
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
      stub = proc do |cmd, async|
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
      stub = proc do |cmd, async|
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
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_key_id = "mykey"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_databases_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

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

      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.databases
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end
  end

  class TestGenerationsCommand < TestCommands
    def test_generations_with_no_options
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "generations", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "db/test.sqlite3", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.generations("db/test.sqlite3")
      end
    end

    def test_generations_with_boolean_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "generations", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--if-db-not-exists", argv[2]
        assert_equal "db/test.sqlite3", argv[3]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.generations("db/test.sqlite3", "--if-db-not-exists" => nil)
      end
    end

    def test_generations_with_string_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "generations", command
        assert_equal 5, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--parallelism", argv[2]
        assert_equal 10, argv[3]
        assert_equal "db/test.sqlite3", argv[4]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.generations("db/test.sqlite3", "--parallelism" => 10)
      end
    end

    def test_generations_with_config_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "generations", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_equal "CONFIG", argv[1]
        assert_equal "db/test.sqlite3", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.generations("db/test.sqlite3", "--config" => "CONFIG")
      end
    end

    def test_generations_sets_replica_bucket_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.generations("db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_generations_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_key_id = "mykey"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.generations("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_generations_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.generations("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_generations_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.generations("db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_generations_does_not_set_env_var_from_config_when_env_vars_already_set
      ENV["LITESTREAM_REPLICA_BUCKET"] = "original_bkt"
      ENV["LITESTREAM_ACCESS_KEY_ID"] = "original_key"
      ENV["LITESTREAM_SECRET_ACCESS_KEY"] = "original_access"

      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.generations("db/test.sqlite3")
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end
  end

  class TestSnapshotsCommand < TestCommands
    def test_snapshots_with_no_options
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "snapshots", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "db/test.sqlite3", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.snapshots("db/test.sqlite3")
      end
    end

    def test_snapshots_with_boolean_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "snapshots", command
        assert_equal 4, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--if-db-not-exists", argv[2]
        assert_equal "db/test.sqlite3", argv[3]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.snapshots("db/test.sqlite3", "--if-db-not-exists" => nil)
      end
    end

    def test_snapshots_with_string_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "snapshots", command
        assert_equal 5, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "--parallelism", argv[2]
        assert_equal 10, argv[3]
        assert_equal "db/test.sqlite3", argv[4]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.snapshots("db/test.sqlite3", "--parallelism" => 10)
      end
    end

    def test_snapshots_with_config_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "snapshots", command
        assert_equal 3, argv.size
        assert_equal "--config", argv[0]
        assert_equal "CONFIG", argv[1]
        assert_equal "db/test.sqlite3", argv[2]
      end
      Litestream::Commands.stub :run, stub do
        Litestream::Commands.snapshots("db/test.sqlite3", "--config" => "CONFIG")
      end
    end

    def test_snapshots_sets_replica_bucket_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.snapshots("db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_snapshots_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_key_id = "mykey"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.snapshots("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_snapshots_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.snapshots("db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_snapshots_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.snapshots("db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_snapshots_does_not_set_env_var_from_config_when_env_vars_already_set
      ENV["LITESTREAM_REPLICA_BUCKET"] = "original_bkt"
      ENV["LITESTREAM_ACCESS_KEY_ID"] = "original_key"
      ENV["LITESTREAM_SECRET_ACCESS_KEY"] = "original_access"

      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, nil do
        Litestream::Commands.snapshots("db/test.sqlite3")
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end
  end

  class TestverifyCommand < TestCommands
    def test_verify_with_no_database
      assert_raises ArgumentError do
        Litestream::Commands.verify
      end
    end

    def test_verify_with_non_existent_database
      assert_raises Litestream::Commands::DatabaseRequiredException do
        Litestream::Commands.verify("db/non_existent.sqlite3")
      end
    end

    def test_verify_with_restore_not_succeeding
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 5, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "-o", argv[2]
        assert_match Regexp.new('db/test-\d{14}.sqlite3'), argv[3]
        assert_equal "test/dummy/db/test.sqlite3", argv[4]

        [{"level" => "ERROR", "error" => "cannot restore"}]
      end
      Litestream::Commands.stub :run, stub do
        assert_raises Litestream::Commands::CommandFailedException do
          Litestream::Commands.verify("test/dummy/db/test.sqlite3")
        end
      end
    end

    def test_verify_with_restore_succeeding
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 5, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "-o", argv[2]
        assert_match Regexp.new('db/test-\d{14}.sqlite3'), argv[3]
        assert_equal "test/dummy/db/test.sqlite3", argv[4]
      end
      result = nil
      Litestream::Commands.stub :run, stub do
        result = Litestream::Commands.verify("test/dummy/db/test.sqlite3")
      end

      assert_equal 20480, result["size"]["original"]
      assert_equal 0, result["size"]["restored"]
      assert_equal 2, result["tables"]["original"]
      assert_equal 0, result["tables"]["restored"]
    end

    def test_verify_with_boolean_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 6, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "-o", argv[2]
        assert_match Regexp.new('db/test-\d{14}.sqlite3'), argv[3]
        assert_equal "--if-db-not-exists", argv[4]
        assert_equal "test/dummy/db/test.sqlite3", argv[5]
      end
      result = nil
      Litestream::Commands.stub :run, stub do
        result = Litestream::Commands.verify("test/dummy/db/test.sqlite3", "--if-db-not-exists" => nil)
      end

      assert_equal 20480, result["size"]["original"]
      assert_equal 0, result["size"]["restored"]
      assert_equal 2, result["tables"]["original"]
      assert_equal 0, result["tables"]["restored"]
    end

    def test_verify_with_string_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 7, argv.size
        assert_equal "--config", argv[0]
        assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
        assert_equal "-o", argv[2]
        assert_match Regexp.new('db/test-\d{14}.sqlite3'), argv[3]
        assert_equal "--parallelism", argv[4]
        assert_equal 10, argv[5]
        assert_equal "test/dummy/db/test.sqlite3", argv[6]
      end
      result = nil
      Litestream::Commands.stub :run, stub do
        result = Litestream::Commands.verify("test/dummy/db/test.sqlite3", "--parallelism" => 10)
      end

      assert_equal 20480, result["size"]["original"]
      assert_equal 0, result["size"]["restored"]
      assert_equal 2, result["tables"]["original"]
      assert_equal 0, result["tables"]["restored"]
    end

    def test_verify_with_config_option
      stub = proc do |cmd, async|
        executable, command, *argv = cmd
        assert_match Regexp.new("exe/test/litestream"), executable
        assert_equal "restore", command
        assert_equal 5, argv.size
        assert_equal "--config", argv[0]
        assert_equal "CONFIG", argv[1]
        assert_equal "-o", argv[2]
        assert_match Regexp.new('db/test-\d{14}.sqlite3'), argv[3]
        assert_equal "test/dummy/db/test.sqlite3", argv[4]
      end
      result = nil
      Litestream::Commands.stub :run, stub do
        result = Litestream::Commands.verify("test/dummy/db/test.sqlite3", "--config" => "CONFIG")
      end

      assert_equal 20480, result["size"]["original"]
      assert_equal 0, result["size"]["restored"]
      assert_equal 2, result["tables"]["original"]
      assert_equal 0, result["tables"]["restored"]
    end

    def test_verify_sets_replica_bucket_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
      end

      Litestream::Commands.stub :run, "" do
        Litestream::Commands.verify("test/dummy/db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_verify_sets_replica_key_id_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_key_id = "mykey"
      end

      Litestream::Commands.stub :run, "" do
        Litestream::Commands.verify("test/dummy/db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_nil ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_verify_sets_replica_access_key_env_var_from_config_when_env_var_not_set
      Litestream.configure do |config|
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, "" do
        Litestream::Commands.verify("test/dummy/db/test.sqlite3")
      end

      assert_nil ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_nil ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_verify_sets_all_env_vars_from_config_when_env_vars_not_set
      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, "" do
        Litestream::Commands.verify("test/dummy/db/test.sqlite3")
      end

      assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end

    def test_verify_does_not_set_env_var_from_config_when_env_vars_already_set
      ENV["LITESTREAM_REPLICA_BUCKET"] = "original_bkt"
      ENV["LITESTREAM_ACCESS_KEY_ID"] = "original_key"
      ENV["LITESTREAM_SECRET_ACCESS_KEY"] = "original_access"

      Litestream.configure do |config|
        config.replica_bucket = "mybkt"
        config.replica_key_id = "mykey"
        config.replica_access_key = "access"
      end

      Litestream::Commands.stub :run, "" do
        Litestream::Commands.verify("test/dummy/db/test.sqlite3")
      end

      assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
      assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
      assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
    end
  end
end
