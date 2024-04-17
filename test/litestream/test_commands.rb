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
end
