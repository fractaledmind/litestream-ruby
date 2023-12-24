# Use this hook to configure the litestream-ruby gem.
# All configuration options will be available as environment variables, e.g.
# config.database_path becomes LITESTREAM_DATABASE_PATH
# This allows you to configure Litestream using Rails encrypted credentials,
# or some other mechanism where the values are only avaialble at runtime.

Litestream.configure do |config|
  # An example of using Rails encrypted credentials to configure Litestream.
  # litestream_credentials = Rails.application.credentials.litestream
  #
  # The absolute or relative path to a SQLite database file.
  # Litestream will monitor this file for changes and replicate them to the
  # any of the configured replicas specified for this database in the
  # `litestream.yml` configuration file.
  # When using SQLite as your database engine for ActiveRecord, you should always
  # set this to the path of your SQLite database file. You can do so using Rails'
  # existing knowledge of the database path.
  # config.database_path = ActiveRecord::Base.connection_db_config.database

  # Short-hand form of specifying a replica location.
  # When using S3, a value will look like "s3://mybkt.litestream.io/db"
  # Litestream also supports Azure Blog Storage, Backblaze B2, DigitalOcean Spaces,
  # Scaleway Object Storage, Google Cloud Storage, Linode Object Storage, and
  # any SFTP server.
  # In this example, we are using Rails encrypted credentials to store the URL to
  # our storage provider bucket.
  # config.replica_url = litestream_credentials.replica_url

  # Replica-specific authentication key.
  # Litestream needs authentication credentials to access your storage provider bucket.
  # In this example, we are using Rails encrypted credentials to store the access key ID.
  # config.replica_key_id = litestream_credentials.replica_key_id

  # Replica-specific secret key.
  # Litestream needs authentication credentials to access your storage provider bucket.
  # In this example, we are using Rails encrypted credentials to store the secret access key.
  # config.replica_access_key = litestream_credentials.replica_access_key
end
