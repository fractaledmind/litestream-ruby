Puma::Plugin.create do
  attr_reader :litestream_pid, :log_writer

  def start(launcher)
    @log_writer = launcher.log_writer

    launcher.events.on_booted do
      @litestream_pid = fork do
        Litestream::Commands.replicate(async: true)
      end
    end

    launcher.events.on_stopped { stop_litestream }
    launcher.events.on_restart { stop_litestream }
  end

  private
    def stop_litestream
      Process.waitpid(litestream_pid, Process::WNOHANG)
      log_writer.log "Stopping Litestream..."
      Process.kill(:INT, litestream_pid) if litestream_pid
      Process.wait(litestream_pid)
    rescue Errno::ECHILD, Errno::ESRCH
    end
end
