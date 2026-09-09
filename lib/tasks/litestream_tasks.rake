namespace :litestream do
  desc "Print the ENV variables needed for the Litestream config file"
  task env: :environment do
    puts "LITESTREAM_REPLICA_BUCKET=#{Litestream.replica_bucket}"
    puts "LITESTREAM_REPLICA_REGION=#{Litestream.replica_region}"
    puts "LITESTREAM_REPLICA_ENDPOINT=#{Litestream.replica_endpoint}"
    puts "LITESTREAM_ACCESS_KEY_ID=#{Litestream.replica_key_id}"
    puts "LITESTREAM_SECRET_ACCESS_KEY=#{Litestream.replica_access_key}"

    true
  end

  desc 'Monitor and continuously replicate SQLite databases defined in your config file, for example `rake litestream:replicate -- -exec "foreman start"`'
  task replicate: :environment do
    options = parse_argv_options

    Litestream::Commands.replicate(**options)
  end

  desc "Restore a SQLite database from a Litestream replica, for example `rake litestream:restore -- -database=storage/production.sqlite3`"
  task restore: :environment do
    options = parse_argv_options
    database = options.delete(:"--database") || options.delete(:"-database")

    puts Litestream::Commands.restore(database, **options)
  end

  desc "List all databases and associated replicas in the config file, for example `rake litestream:databases -- -no-expand-env`"
  task databases: :environment do
    options = parse_argv_options

    puts Litestream::Commands::Output.format(Litestream::Commands.databases(**options))
  end

  desc "List all LTX files for a database or replica, for example `rake litestream:ltx -- -database=storage/production.sqlite3`"
  task ltx: :environment do
    options = parse_argv_options
    database = options.delete(:"--database") || options.delete(:"-database")

    puts Litestream::Commands::Output.format(Litestream::Commands.ltx(database, **options))
  end

  desc "Show replication status, for example `rake litestream:status -- -database=storage/production.sqlite3`"
  task status: :environment do
    options = parse_argv_options
    database = options.delete(:"--database") || options.delete(:"-database")

    puts Litestream::Commands::Output.format(Litestream::Commands.status(database, **options))
  end

  desc "Explain the removal of the generations command"
  task generations: :environment do
    abort "`generations` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)"
  end

  desc "Explain the removal of the snapshots command"
  task snapshots: :environment do
    abort "`snapshots` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)"
  end

  desc "Explain the removal of the wal command"
  task wal: :environment do
    abort "`wal` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)"
  end

  private

  def parse_argv_options
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    options.symbolize_keys!
  end
end
