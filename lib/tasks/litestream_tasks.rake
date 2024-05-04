namespace :litestream do
  desc "Print the ENV variables needed for the Litestream config file"
  task env: :environment do
    if Litestream.configuration.nil?
      warn "You have not configured the Litestream gem with any values to generate ENV variables"
      next
    end

    puts "LITESTREAM_REPLICA_BUCKET=#{Litestream.configuration.replica_bucket}"
    puts "LITESTREAM_ACCESS_KEY_ID=#{Litestream.configuration.replica_key_id}"
    puts "LITESTREAM_SECRET_ACCESS_KEY=#{Litestream.configuration.replica_access_key}"

    true
  end

  desc 'Monitor and continuously replicate SQLite databases defined in your config file, e.g. rake litestream:replicate -- -exec "foreman start"'
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

  desc "Restore a SQLite database from a Litestream replica, e.g. rake litestream:restore -- -database=storage/production.sqlite3"
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

  desc "List all databases and associated replicas in the config file, e.g. rake litestream:databases -- -no-expand-env"
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

  desc "List all generations for a database or replica, e.g. rake litestream:generations -- -database=storage/production.sqlite3"
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

  desc "List all snapshots for a database or replica, e.g. rake litestream:snapshots -- -database=storage/production.sqlite3"
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

  desc "verify backup of SQLite database from a Litestream replica, e.g. rake litestream:verify -- -database=storage/production.sqlite3"
  task verify: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end
    database = options.delete("--database") || options.delete("-database")
    options.symbolize_keys!

    result = Litestream::Commands.verify(database, async: true, **options)
    original_tables = result["original"]["tables"]
    restored_tables = result["restored"]["tables"]
    original_indexes = result["original"]["indexes"]
    restored_indexes = result["restored"]["indexes"]
    original_rows = result["original"]["rows"]
    restored_rows = result["restored"]["rows"]

    same_number_of_tables = original_tables == restored_tables
    same_number_of_indexes = original_indexes == restored_indexes
    same_number_of_rows = original_rows == restored_rows

    if same_number_of_tables && same_number_of_indexes && same_number_of_rows
      puts "Backup for `#{database}` verified as consistent!\n" + [
        "  tables   #{original_tables}",
        "  indexes  #{original_indexes}",
        "  rows     #{original_rows}"
      ].compact.join("\n")
    else
      abort "Verification failed for #{database}:\n" + [
        (unless same_number_of_tables
           if original_tables > restored_tables
             diff = original_tables - restored_tables
             "  Backup is missing #{diff} table#{"s" if diff > 1}"
           else
             diff = restored_tables - original_tables
             "  Backup has extra #{diff} table#{"s" if diff > 1}"
           end
         end),
        (unless same_number_of_indexes
           if original_indexes > restored_indexes
             diff = original_indexes - restored_indexes
             "  Backup is missing #{diff} index#{"es" if diff > 1}"
           else
             diff = restored_indexes - original_indexes
             "  Backup has extra #{diff} index#{"es" if diff > 1}"
           end
         end),
        (unless same_number_of_rows
           if original_rows > restored_rows
             diff = original_rows - restored_rows
             "  Backup is missing #{diff} row#{"s" if diff > 1}"
           else
             diff = restored_rows - original_rows
             "  Backup has extra #{diff} row#{"s" if diff > 1}"
           end
         end)
      ].compact.join("\n")
    end
  end
end
