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
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    options.symbolize_keys!

    Litestream::Commands.replicate(async: true, **options)
  end

  desc "Restore a SQLite database from a Litestream replica, for example `rake litestream:restore -- -database=storage/production.sqlite3`"
  task restore: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    database = options.delete("--database") || options.delete("-database")
    options.symbolize_keys!

    Litestream::Commands.restore(database, async: true, **options)
  end

  desc "List all databases and associated replicas in the config file, for example `rake litestream:databases -- -no-expand-env`"
  task databases: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    options.symbolize_keys!

    Litestream::Commands.databases(async: true, **options)
  end

  desc "List all generations for a database or replica, for example `rake litestream:generations -- -database=storage/production.sqlite3`"
  task generations: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    database = options.delete("--database") || options.delete("-database")
    options.symbolize_keys!

    Litestream::Commands.generations(database, async: true, **options)
  end

  desc "List all snapshots for a database or replica, for example `rake litestream:snapshots -- -database=storage/production.sqlite3`"
  task snapshots: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    database = options.delete("--database") || options.delete("-database")
    options.symbolize_keys!

    Litestream::Commands.snapshots(database, async: true, **options)
  end

  desc "List all wal files for a database or replica, for example `rake litestream:wal -- -database=storage/production.sqlite3`"
  task wal: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    database = options.delete("--database") || options.delete("-database")
    options.symbolize_keys!

    Litestream::Commands.wal(database, async: true, **options)
  end
end
