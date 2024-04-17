require "test_helper"
require "rake"

class TestLitestreamTasks < ActiveSupport::TestCase
  def setup
    Rake.application.rake_require "tasks/litestream_tasks"
    Rake::Task.define_task(:environment)
    Rake::Task["litestream:env"].reenable
    Rake::Task["litestream:replicate"].reenable
    Rake::Task["litestream:restore"].reenable
  end

  def teardown
    Litestream.configuration = nil
    ARGV.replace []
  end

  def test_env_task_when_nothing_configured_warns
    out, err = capture_io do
      Rake.application.invoke_task "litestream:env"
    end

    assert_equal "", out
    assert_equal "You have not configured the Litestream gem with any values to generate ENV variables\n", err
  end

  def test_env_task_when_configured_outputs_env_variables
    Litestream.configure do |config|
      config.database_path = "path/to/database"
    end

    out, err = capture_io do
      Rake.application.invoke_task "litestream:env"
    end

    assert_equal "LITESTREAM_REPLICA_BUCKET=\nLITESTREAM_ACCESS_KEY_ID=\nLITESTREAM_SECRET_ACCESS_KEY=\n", out
    assert_equal "", err
  end

  def test_replicate_task_with_no_arguments
    fake = Minitest::Mock.new
    fake.expect :call, nil, [{}]
    Litestream::Commands.stub :replicate, fake do
      Rake.application.invoke_task "litestream:replicate"
    end
    fake.verify
  end

  def test_replicate_task_with_arguments
    ARGV.replace ["--", "--no-expand-env"]
    fake = Minitest::Mock.new
    fake.expect :call, nil, [{"--no-expand-env" => nil}]
    Litestream::Commands.stub :replicate, fake do
      Rake.application.invoke_task "litestream:replicate"
    end
    fake.verify
  end

  def test_replicate_task_with_arguments_without_separator
    ARGV.replace ["--no-expand-env"]
    fake = Minitest::Mock.new
    fake.expect :call, nil, [{}]
    Litestream::Commands.stub :replicate, fake do
      Rake.application.invoke_task "litestream:replicate"
    end
    fake.verify
  end

  def test_restore_task_with_only_database_using_single_dash
    ARGV.replace ["--", "-database=db/test.sqlite3"]
    fake = Minitest::Mock.new
    fake.expect :call, nil, ["db/test.sqlite3", {}]
    Litestream::Commands.stub :restore, fake do
      Rake.application.invoke_task "litestream:restore"
    end
    fake.verify
  end

  def test_restore_task_with_only_database_using_double_dash
    ARGV.replace ["--", "--database=db/test.sqlite3"]
    fake = Minitest::Mock.new
    fake.expect :call, nil, ["db/test.sqlite3", {}]
    Litestream::Commands.stub :restore, fake do
      Rake.application.invoke_task "litestream:restore"
    end
    fake.verify
  end

  def test_restore_task_with_arguments
    ARGV.replace ["--", "-database=db/test.sqlite3", "--if-db-not-exists"]
    fake = Minitest::Mock.new
    fake.expect :call, nil, ["db/test.sqlite3", {"--if-db-not-exists"=>nil}]
    Litestream::Commands.stub :restore, fake do
      Rake.application.invoke_task "litestream:restore"
    end
    fake.verify
  end

  def test_restore_task_with_arguments_without_separator
    ARGV.replace ["-database=db/test.sqlite3"]
    fake = Minitest::Mock.new
    fake.expect :call, nil, [nil, {}]
    Litestream::Commands.stub :restore, fake do
      Rake.application.invoke_task "litestream:restore"
    end
    fake.verify
  end
end
