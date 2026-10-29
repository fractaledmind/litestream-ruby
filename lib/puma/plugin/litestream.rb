require "puma/plugin"

# Copied from https://github.com/rails/solid_queue/blob/15408647f1780033dad223d3198761ea2e1e983e/lib/puma/plugin/solid_queue.rb
Puma::Plugin.create do
  attr_reader :litestream_pid, :log_writer

  def start(launcher)
    @log_writer = launcher.log_writer

    in_background do
      monitor_litestream
    end

    launcher.events.on_booted do
      @litestream_pid = Litestream::Commands.replicate(async: true)
    end

    launcher.events.on_stopped { stop_litestream }
    launcher.events.on_restart { stop_litestream }
  end

  private

  # Clears the pid first: a phased restart fires restart, then booted only
  # once every worker is back, and meanwhile the monitor must not take the
  # pid stopped here for Litestream dying.
  def stop_litestream
    pid, @litestream_pid = litestream_pid, nil
    return unless pid

    Process.waitpid(pid, Process::WNOHANG)
    log_writer.log "Stopping Litestream..."
    Process.kill(:INT, pid)
    Process.wait(pid)
  rescue Errno::ECHILD, Errno::ESRCH
  end

  def monitor_litestream
    monitor(:litestream_dead?, "Detected Litestream has gone away, stopping Puma...")
  end

  def monitor(process_dead, message)
    loop do
      if send(process_dead)
        log message
        Process.kill(:INT, $$)
        break
      end
      sleep 2
    end
  end

  def litestream_dead?
    Process.waitpid(litestream_pid, Process::WNOHANG) if litestream_pid
    false
  rescue Errno::ECHILD, Errno::ESRCH
    true
  end

  def log(...)
    log_writer.log(...)
  end
end
