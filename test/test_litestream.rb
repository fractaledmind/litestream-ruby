# frozen_string_literal: true

require "test_helper"

class TestLitestream < Minitest::Test
  def teardown
    Litestream.systemctl_command = nil
  end

  def test_that_it_has_a_version_number
    refute_nil ::Litestream::VERSION
  end

  def test_replicate_process_systemd
    stubbed_status = ["● litestream.service - Litestream",
      "     Loaded: loaded (/lib/systemd/system/litestream.service; enabled; vendor preset: enabled)",
      "     Active: active (running) since Tue 2023-07-25 13:49:43 UTC; 8 months 24 days ago",
      "   Main PID: 1179656 (litestream)",
      "      Tasks: 9 (limit: 1115)",
      "     Memory: 22.9M",
      "        CPU: 10h 49.843s",
      "     CGroup: /system.slice/litestream.service",
      "             └─1179656 /usr/bin/litestream replicate",
      "",
      "Warning: some journal files were not opened due to insufficient permissions."].join("\n")
    Litestream.stub :`, stubbed_status do
      info = Litestream.replicate_process

      assert_equal info[:status], "running"
      assert_equal info[:pid], "1179656"
      assert_equal info[:started].class, DateTime
    end
  end

  def test_replicate_process_systemd_custom_command
    stubbed_status = ["● myapp-litestream.service - Litestream",
      "     Loaded: loaded (/lib/systemd/system/litestream.service; enabled; vendor preset: enabled)",
      "     Active: active (running) since Tue 2023-07-25 13:49:43 UTC; 8 months 24 days ago",
      "   Main PID: 1179656 (litestream)",
      "      Tasks: 9 (limit: 1115)",
      "     Memory: 22.9M",
      "        CPU: 10h 49.843s",
      "     CGroup: /system.slice/litestream.service",
      "             └─1179656 /usr/bin/litestream replicate",
      "",
      "Warning: some journal files were not opened due to insufficient permissions."].join("\n")
    Litestream.systemctl_command = "systemctl --user status myapp-litestream.service"

    Litestream.stub :`, stubbed_status do
      info = Litestream.replicate_process

      assert_equal info[:status], "running"
      assert_equal info[:pid], "1179656"
      assert_equal info[:started].class, DateTime
    end
  end

  def test_replicate_process_ps
    stubbed_ps_list = [
      "40358 ttys008    0:01.11 ruby --yjit bin/rails litestream:replicate",
      "40364 ttys008    0:00.07 /path/to/litestream-ruby/exe/architecture/litestream replicate --config /path/to/app/config/litestream.yml"
    ].join("\n")

    stubbed_ps_status = [
      "STAT STARTED",
      "S+   Mon Jul  1 11:10:58 2024"
    ].join("\n")

    stubbed_backticks = proc do |arg|
      case arg
      when "ps -ax | grep litestream | grep replicate"
        stubbed_ps_list
      when %(ps -o "state,lstart" 40364)
        stubbed_ps_status
      else
        ""
      end
    end

    Litestream.stub :`, stubbed_backticks do
      info = Litestream.replicate_process

      assert_equal info[:status], "sleeping"
      assert_equal info[:pid], "40364"
      assert_equal info[:started].class, DateTime
    end
  end
end
