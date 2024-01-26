namespace :litestream do
  desc "Print the ENV variables needed for the Litestream config file"
  task env: :environment do
    if Litestream.configuration.nil?
      warn "You have not configured the Litestream gem with any values to generate ENV variables"
      next
    end

    puts "LITESTREAM_DATABASE_PATH=#{Litestream.configuration.database_path}"
    puts "LITESTREAM_REPLICA_BUCKET=#{Litestream.configuration.replica_bucket}"
    puts "LITESTREAM_ACCESS_KEY_ID=#{Litestream.configuration.replica_key_id}"
    puts "LITESTREAM_SECRET_ACCESS_KEY=#{Litestream.configuration.replica_access_key}"

    true
  end

  desc "Start a process to monitor and continuously replicate the SQLite databases defined in your configuration file"
  task replicate: :environment do
    options = {}
    if (separator_index = ARGV.index("--"))
      ARGV.slice(separator_index + 1, ARGV.length)
        .map { |pair| pair.split("=") }
        .each { |opt| options[opt[0]] = opt[1] || nil }
    end

    Litestream::Commands.replicate(options)
  end
end
