namespace :litestream do
  desc "Print the ENV variables needed for the Litestream config file"
  task env: :environment do
    if Litestream.configuration.nil?
      warn "You have not configured the Litestream gem with any values to generate ENV variables"
      next
    end

    puts "LITESTREAM_DATABASE_PATH=#{Litestream.configuration.database_path}"
    puts "LITESTREAM_REPLICA_URL=#{Litestream.configuration.replica_url}"
    puts "LITESTREAM_ACCESS_KEY_ID=#{Litestream.configuration.replica_key_id}"
    puts "LITESTREAM_SECRET_ACCESS_KEY=#{Litestream.configuration.replica_access_key}"

    true
  end

  desc ""
  task replicate: :environment do
    Litestream::Commands.replicate
  end
end
