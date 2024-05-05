# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "litestream/generators/litestream/install_generator"

class LitestreamGeneratorTest < Rails::Generators::TestCase
  tests Litestream::Generators::InstallGenerator
  destination File.expand_path("../tmp", __dir__)

  setup :prepare_destination

  def after_teardown
    FileUtils.rm_rf destination_root
    super
  end

  test "should generate a Litestream configuration file" do
    run_generator

    assert_file "config/litestream.yml" do |content|
      assert_match "- path: storage/test.sqlite3", content
      assert_match "- path: storage/queue.sqlite3", content
      assert_match "- path: storage/errors.sqlite3", content
      assert_match "bucket: $LITESTREAM_REPLICA_BUCKET", content
      assert_match "access-key-id: $LITESTREAM_ACCESS_KEY_ID", content
      assert_match "secret-access-key: $LITESTREAM_SECRET_ACCESS_KEY", content
    end

    assert_file "config/initializers/litestream.rb" do |content|
      assert_match "config.replica_bucket = litestream_credentials.replica_bucket", content
      assert_match "config.replica_key_id = litestream_credentials.replica_key_id", content
      assert_match "config.replica_access_key = litestream_credentials.replica_access_key", content
    end
  end
end
