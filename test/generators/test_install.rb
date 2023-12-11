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
      assert_match "path: $LITESTREAM_DATABASE_PATH", content
      assert_match "url: $LITESTREAM_REPLICA_URL", content
      assert_match "access-key-id: $LITESTREAM_REPLICA_KEY_ID", content
      assert_match "secret-access-key: $LITESTREAM_REPLICA_ACCESS_KEY", content
    end
  end
end
