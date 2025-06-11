namespace :litestream do
  desc "Print the ENV variables needed for the Litestream config file"
  task env: :environment do
    puts "LITESTREAM_REPLICA_BUCKET=#{Litestream.replica_bucket}"
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

  desc "List all generations for a database or replica, for example `rake litestream:generations -- -database=storage/production.sqlite3`"
  task generations: :environment do
    options = parse_argv_options
    database = options.delete(:"--database") || options.delete(:"-database")

    puts Litestream::Commands::Output.format(Litestream::Commands.generations(database, **options))
  end

  desc "List all snapshots for a database or replica, for example `rake litestream:snapshots -- -database=storage/production.sqlite3`"
  task snapshots: :environment do
    options = parse_argv_options
    database = options.delete(:"--database") || options.delete(:"-database")

    puts Litestream::Commands::Output.format(Litestream::Commands.snapshots(database, **options))
  end

  desc "List all wal files for a database or replica, for example `rake litestream:wal -- -database=storage/production.sqlite3`"
  task wal: :environment do
    options = parse_argv_options
    database = options.delete(:"--database") || options.delete(:"-database")

    puts Litestream::Commands::Output.format(
      Litestream::Commands.wal(database, **options)
    )
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
