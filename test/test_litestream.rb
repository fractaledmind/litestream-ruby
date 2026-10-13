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
    Litestream.stub :`, proc { system("true") && stubbed_status } do
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

    Litestream.stub :`, proc { system("true") && stubbed_status } do
      info = Litestream.replicate_process

      assert_equal info[:status], "running"
      assert_equal info[:pid], "1179656"
      assert_equal info[:started].class, DateTime
    end
  end

  def test_proc_process_info_reads_pid_state_and_start_time
    Dir.mktmpdir do |proc_dir|
      clock_ticks = Etc.sysconf(Etc::SC_CLK_TCK)
      File.write(File.join(proc_dir, "stat"), "cpu  1 2 3\nbtime 1700000000\nprocesses 99\n")
      # exited between the directory listing and the read
      FileUtils.mkdir(File.join(proc_dir, "40"))
      write_proc_entry(proc_dir, 39, "/bin/zsh\0-c\0tail -f /app/bin/litestream replicate.log\0", "39 (zsh) S 1")
      write_proc_entry(proc_dir, 38, "/usr/bin/rclone\0replicate\0", "38 (rclone) S 1")
      write_proc_entry(proc_dir, 41, "/app/bin/litestream\0restore\0/app/db.sqlite3\0", "41 (litestream) S 1")
      write_proc_entry(proc_dir, 42, "/app/bin/litestream\0replicate\0-config\0/app/config/litestream.yml\0",
        "42 (lite) stream) S 1 42 42 0 -1 4194560 2965 0 0 0 6 0 0 0 20 0 2 0 #{250 * clock_ticks} 468332544")

      info = Litestream.send(:proc_process_info, proc_dir)

      assert_equal "42", info[:pid]
      assert_equal "sleeping", info[:status]
      assert_equal Time.at(1_700_000_250).to_datetime, info[:started]
    end
  end

  def test_ps_process_info_reads_pid_state_and_start_time
    stubbed_ps = {
      "ps -axo pid=,stat=,lstart=,comm=" => [
        "40350 Ss   Mon Jul  1 11:10:50 2024     /bin/zsh",
        "40358 S+   Mon Jul  1 11:10:57 2024     /path/to/my app/exe/arm64-darwin/litestream",
        "40364 S+   Mon Jul  1 11:10:58 2024     /path/to/my app/exe/arm64-darwin/litestream"
      ].join("\n"),
      "ps -o args= -p 40358" => "/path/to/my app/exe/arm64-darwin/litestream restore /path/to/app/db.sqlite3\n",
      "ps -o args= -p 40364" => "/path/to/my app/exe/arm64-darwin/litestream replicate --config /path/to/app/config/litestream.yml\n"
    }

    info = Litestream.stub(:`, proc { |command| system("true") && stubbed_ps.fetch(command) }) do
      Litestream.send(:ps_process_info)
    end

    assert_equal "40364", info[:pid]
    assert_equal "sleeping", info[:status]
    assert_equal Time.local(2024, 7, 1, 11, 10, 58).to_datetime, info[:started]
  end

  def test_process_info_finds_a_running_replicate_process
    Dir.mktmpdir do |tmpdir|
      dir = File.join(tmpdir, "my app")
      FileUtils.mkdir(dir)
      # Ruby stands in for the binary: argv[0] names it litestream, and the
      # script it runs is a file called "replicate".
      File.write(File.join(dir, "replicate"), "sleep 30")
      pid = Process.spawn([RbConfig.ruby, File.join(dir, "litestream")], "replicate", "-config", "litestream.yml", chdir: dir)
      sleep 0.5

      info = Litestream.send(:process_info)

      assert_equal pid.to_s, info[:pid]
      assert_includes %w[running sleeping], info[:status]
      assert_in_delta Time.now.to_i, info[:started].to_time.to_i, 10
    ensure
      if pid
        Process.kill(:TERM, pid)
        Process.wait(pid)
      end
    end
  end

  private

  def write_proc_entry(proc_dir, pid, cmdline, stat)
    FileUtils.mkdir(File.join(proc_dir, pid.to_s))
    File.write(File.join(proc_dir, pid.to_s, "cmdline"), cmdline)
    File.write(File.join(proc_dir, pid.to_s, "stat"), stat)
  end
end
