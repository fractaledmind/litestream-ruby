# Takes an exclusive lock on each path, waiting for one another process holds,
# then execs the command with the locks open, so the command holds them until
# it exits. Usage: ruby lock_and_exec.rb LOCK... -- COMMAND...
require "fileutils"

trap("INT", "SYSTEM_DEFAULT")
separator = ARGV.index("--")
locks = ARGV[0...separator].map do |path|
  FileUtils.mkdir_p(File.dirname(path))
  lock = File.open(path, File::RDONLY | File::CREAT, 0o644)
  unless lock.flock(File::LOCK_EX | File::LOCK_NB)
    warn "Waiting for #{path}: another `litestream replicate` holds it"
    lock.flock(File::LOCK_EX)
  end
  lock
end
exec(*ARGV[(separator + 1)..], locks.to_h { [_1, _1] })
