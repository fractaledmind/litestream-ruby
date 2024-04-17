require "test_helper"

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
    Litestream.configuration = nil
    ENV["LITESTREAM_REPLICA_BUCKET"] = nil
    ENV["LITESTREAM_ACCESS_KEY_ID"] = nil
    ENV["LITESTREAM_SECRET_ACCESS_KEY"] = nil
  end

  def test_replicate_with_no_options
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/test/litestream"), executable
      assert_equal "replicate", command
      assert_equal 2, argv.size
      assert_equal "--config", argv[0]
      assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
    end
    Litestream::Commands.stub :exec, stub do
      Litestream::Commands.replicate
    end
  end

  def test_replicate_with_boolean_option
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/test/litestream"), executable
      assert_equal "replicate", command
      assert_equal 3, argv.size
      assert_equal "--config", argv[0]
      assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
      assert_equal "--no-expand-env", argv[2]
    end
    Litestream::Commands.stub :exec, stub do
      Litestream::Commands.replicate("--no-expand-env" => nil)
    end
  end

  def test_replicate_with_string_option
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/test/litestream"), executable
      assert_equal "replicate", command
      assert_equal 4, argv.size
      assert_equal "--config", argv[0]
      assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
      assert_equal "--exec", argv[2]
      assert_equal "command", argv[3]
    end
    Litestream::Commands.stub :exec, stub do
      Litestream::Commands.replicate("--exec" => "command")
    end
  end

  def test_replicate_with_config_option
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/test/litestream"), executable
      assert_equal "replicate", command
      assert_equal 2, argv.size
      assert_equal "--config", argv[0]
      assert_equal "CONFIG", argv[1]
    end
    Litestream::Commands.stub :exec, stub do
      Litestream::Commands.replicate("--config" => "CONFIG")
    end
  end

  def test_replicate_sets_replica_bucket_env_var_from_config_when_env_var_not_set
    Litestream.configure do |config|
      config.replica_bucket = "mybkt"
    end

    Litestream::Commands.stub :exec, nil do
      Litestream::Commands.replicate
    end

    assert_equal "mybkt", ENV["LITESTREAM_REPLICA_BUCKET"]
    assert_equal nil, ENV["LITESTREAM_ACCESS_KEY_ID"]
    assert_equal nil, ENV["LITESTREAM_SECRET_ACCESS_KEY"]
  end

  def test_replicate_sets_replica_key_id_env_var_from_config_when_env_var_not_set
    Litestream.configure do |config|
      config.replica_key_id = "mykey"
    end

    Litestream::Commands.stub :exec, nil do
      Litestream::Commands.replicate
    end

    assert_equal nil, ENV["LITESTREAM_REPLICA_BUCKET"]
    assert_equal "mykey", ENV["LITESTREAM_ACCESS_KEY_ID"]
    assert_equal nil, ENV["LITESTREAM_SECRET_ACCESS_KEY"]
  end

  def test_replicate_sets_replica_access_key_env_var_from_config_when_env_var_not_set
    Litestream.configure do |config|
      config.replica_access_key = "access"
    end

    Litestream::Commands.stub :exec, nil do
      Litestream::Commands.replicate
    end

    assert_equal nil, ENV["LITESTREAM_REPLICA_BUCKET"]
    assert_equal nil, ENV["LITESTREAM_ACCESS_KEY_ID"]
    assert_equal "access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
  end

  def test_replicate_sets_all_env_vars_from_config_when_env_vars_not_set
    Litestream.configure do |config|
      config.replica_bucket = "mybkt"
      config.replica_key_id = "mykey"
      config.replica_access_key = "access"
    end

    Litestream::Commands.stub :exec, nil do
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

    Litestream::Commands.stub :exec, nil do
      Litestream::Commands.replicate
    end

    assert_equal "original_bkt", ENV["LITESTREAM_REPLICA_BUCKET"]
    assert_equal "original_key", ENV["LITESTREAM_ACCESS_KEY_ID"]
    assert_equal "original_access", ENV["LITESTREAM_SECRET_ACCESS_KEY"]
  end
end
