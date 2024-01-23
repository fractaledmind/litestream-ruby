require "test_helper"

class TestCommands < ActiveSupport::TestCase
  def test_replicate_with_no_arguments
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/arm64-darwin/litestream"), executable
      assert_equal "replicate", command
      assert_equal 2, argv.size
      assert_equal "--config", argv[0]
      assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
    end
    Litestream::Commands.stub :system, stub do
      capture_io do
        Litestream::Commands.replicate
      end
    end
  end

  def test_replicate_with_boolean_argument
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/arm64-darwin/litestream"), executable
      assert_equal "replicate", command
      assert_equal 3, argv.size
      assert_equal "--config", argv[0]
      assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
      assert_equal "--no-expand-env", argv[2]
    end
    Litestream::Commands.stub :system, stub do
      capture_io do
        Litestream::Commands.replicate("--no-expand-env" => nil)
      end
    end
  end

  def test_replicate_with_string_argument
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/arm64-darwin/litestream"), executable
      assert_equal "replicate", command
      assert_equal 4, argv.size
      assert_equal "--config", argv[0]
      assert_match Regexp.new("dummy/config/litestream.yml"), argv[1]
      assert_equal "--exec", argv[2]
      assert_equal "command", argv[3]
    end
    Litestream::Commands.stub :system, stub do
      capture_io do
        Litestream::Commands.replicate("--exec" => "command")
      end
    end
  end

  def test_replicate_with_config_argument
    stub = proc do |executable, command, *argv|
      assert_match Regexp.new("exe/arm64-darwin/litestream"), executable
      assert_equal "replicate", command
      assert_equal 2, argv.size
      assert_equal "--config", argv[0]
      assert_equal "CONFIG", argv[1]
    end
    Litestream::Commands.stub :system, stub do
      capture_io do
        Litestream::Commands.replicate("--config" => "CONFIG")
      end
    end
  end
end
