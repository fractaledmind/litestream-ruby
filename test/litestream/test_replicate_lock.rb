require "test_helper"
require "fileutils"
require "tmpdir"

class TestReplicateLock < ActiveSupport::TestCase
  # Logs when it starts and stops, and "overlap" if another copy is running.
  FAKE_LITESTREAM = <<~SH
    #!/bin/sh
    if ! mkdir "$0.running" 2>/dev/null; then echo overlap >> "$0.log"; exit 42; fi
    echo "start $$" >> "$0.log"
    trap 'echo "stop $$" >> "$0.log"; rmdir "$0.running"; exit 0' INT TERM
    while :; do sleep 0.1; done
  SH

  def setup
    @dir = Dir.mktmpdir
    @executable = File.join(@dir, "litestream")
    File.write(@executable, FAKE_LITESTREAM)
    File.chmod(0o755, @executable)
    @lock_path = File.join(@dir, ".production.sqlite3-litestream.lock")
    Litestream.config_path = File.join(@dir, "litestream.yml")
    File.write(Litestream.config_path, "dbs:\n  - path: #{@dir}/production.sqlite3\n")
  end

  def teardown
    @pids&.each do |pid|
      Process.kill(:KILL, pid)
      Process.wait(pid)
    rescue Errno::ESRCH, Errno::ECHILD
    end
    Litestream.config_path = nil
    FileUtils.rm_rf(@dir)
    # Leave a clean $? for the tests that read it after a stubbed command.
    system("true")
  end

  def replicate(**options)
    Litestream::Commands.stub :executable, @executable do
      Litestream::Commands.replicate(**options).tap { (@pids ||= []) << _1 if _1.is_a?(Integer) }
    end
  end

  def log = File.exist?("#{@executable}.log") ? File.readlines("#{@executable}.log", chomp: true) : []

  def lock_free? = File.open(@lock_path, File::RDONLY | File::CREAT) { _1.flock(File::LOCK_EX | File::LOCK_NB) } != false

  def wait_until(timeout: 5)
    deadline = Time.now + timeout
    sleep 0.05 until yield || Time.now > deadline
    yield
  end

  def stop(pid)
    Process.kill(:TERM, pid)
    Process.wait(pid)
  end

  def test_a_second_replicate_waits_until_the_first_exits
    first = replicate(async: true)
    assert wait_until { log == ["start #{first}"] }
    second = nil
    _, err = capture_subprocess_io do
      second = replicate(async: true)
      sleep 1
    end

    assert_equal ["start #{first}"], log
    assert_match "Waiting for #{@lock_path}", err
    stop(first)
    assert wait_until { log == ["start #{first}", "stop #{first}", "start #{second}"] }, log.inspect
  end

  def test_a_foreground_replicate_waits_too
    first = replicate(async: true)
    assert wait_until { log.size == 1 }
    foreground = Thread.new { capture_subprocess_io { replicate } }
    sleep 1

    assert_equal ["start #{first}"], log
    stop(first)
    assert wait_until { log.size == 3 }, log.inspect
    assert_match(/\Astart /, log.last)
  ensure
    log.grep(/\Astart /).each do |line|
      Process.kill(:TERM, line.split.last.to_i)
    rescue Errno::ESRCH
    end
    foreground&.join(5)
  end

  def test_the_lock_stays_with_litestream_when_its_parent_is_killed
    script = <<~RUBY
      require "active_support/all"
      require "litestream"
      Litestream.config_path = #{Litestream.config_path.inspect}
      Litestream::Commands.define_singleton_method(:executable) { |**| #{@executable.inspect} }
      Litestream::Commands.replicate(async: true)
      sleep
    RUBY
    parent = Process.spawn(RbConfig.ruby, "-I", File.expand_path("../../lib", __dir__), "-e", script)
    assert wait_until { log.size == 1 }
    litestream = log.first.split.last.to_i
    Process.kill(:KILL, parent)
    Process.wait(parent)

    refute lock_free?, "litestream should still hold the lock"
    Process.kill(:TERM, litestream)
    assert wait_until { lock_free? }
  end

  def test_stopping_a_waiting_replicate_starts_nothing
    holder = File.open(@lock_path, File::RDONLY | File::CREAT)
    holder.flock(File::LOCK_EX)
    waiting = nil
    capture_subprocess_io do
      waiting = replicate(async: true)
      sleep 0.5
    end
    Process.kill(:INT, waiting)
    Process.wait(waiting)
    holder.close
    sleep 0.5

    assert_empty log
    assert lock_free?
  end

  def test_lock_paths_follow_the_config
    ENV["LITESTREAM_TEST_DIR"] = @dir
    File.write(Litestream.config_path, <<~YAML)
      dbs:
        - path: $LITESTREAM_TEST_DIR/a.sqlite3
        - path: sqlite3://#{@dir}/b.sqlite3
          meta-path: #{@dir}/meta/b
        - dir: #{@dir}/tenants
          pattern: "*.sqlite3"
        - dir: #{@dir}/more
          meta-dir: #{@dir}/more-meta
    YAML

    paths = Litestream::Commands.send(:lock_paths, ["litestream", "replicate", "--config", Litestream.config_path])

    assert_equal [
      "#{@dir}/.a.sqlite3-litestream.lock",
      "#{@dir}/meta/b.lock",
      "#{@dir}/more-meta/.litestream.lock",
      "#{@dir}/tenants/.litestream.lock"
    ], paths
  ensure
    ENV.delete("LITESTREAM_TEST_DIR")
  end

  def test_lock_paths_without_env_expansion
    File.write(Litestream.config_path, "dbs:\n  - path: #{@dir}/$NAME.sqlite3\n")

    paths = Litestream::Commands.send(:lock_paths, ["litestream", "replicate", "--config", Litestream.config_path, "-no-expand-env"])

    assert_equal ["#{@dir}/.$NAME.sqlite3-litestream.lock"], paths
  end
end
