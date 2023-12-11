litestream_credentials = Rails.application.credentials.litestream

Litestream.configure do |config|
  config.database_path = ActiveRecord::Base.connection_db_config.database
  config.replica_url = litestream_credentials.replica_url
  config.replica_key_id = litestream_credentials.replica_key_id
  config.replica_access_key = litestream_credentials.replica_access_key
end
