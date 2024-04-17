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

    Litestream::Commands.replicate(options)
  end

  desc "Restore a SQLite database from a Litestream replica, e.g. rake litestream:restore -- -database=storage/production.sqlite3"
  task restore: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end

    Litestream::Commands.restore(options.delete("--database") || options.delete("-database"), options)
  end

  desc "List all databases and associated replicas in the config file, e.g. rake litestream:databases -- -no-expand-env"
  task databases: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end

    Litestream::Commands.databases(options)
  end

  desc "List all generations for a database or replica, e.g. rake litestream:generations -- -database=storage/production.sqlite3"
  task generations: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end

    Litestream::Commands.generations(options.delete("--database") || options.delete("-database"), options)
  end

  desc "List all snapshots for a database or replica, e.g. rake litestream:snapshots -- -database=storage/production.sqlite3"
  task snapshots: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end

    Litestream::Commands.snapshots(options.delete("--database") || options.delete("-database"), options)
  end

  desc "Validate backup of SQLite database from a Litestream replica, e.g. rake litestream:validate -- -database=storage/production.sqlite3"
  task validate: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end

    result = Litestream::Commands.validate(options.delete("--database") || options.delete("-database"), options)

    puts <<~TXT

      size
        original          #{result[:size][:original]}
        replica           #{result[:size][:replica]}
        delta             #{result[:size][:original] - result[:size][:replica]}

      tables
        original          #{result[:tables][:original]}
        replica           #{result[:tables][:replica]}
        delta             #{result[:tables][:original] - result[:tables][:replica]}
    TXT
  end
end
