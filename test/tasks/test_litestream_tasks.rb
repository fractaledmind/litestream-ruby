require "test_helper"
require "rake"

class TestLitestreamTasks < ActiveSupport::TestCase
  def setup
    Rake.application.rake_require "tasks/litestream_tasks"
    Rake::Task.define_task(:environment)
    Rake::Task["litestream:env"].reenable
    Rake::Task["litestream:replicate"].reenable
    Rake::Task["litestream:restore"].reenable
    Rake::Task["litestream:databases"].reenable
    Rake::Task["litestream:generations"].reenable
    Rake::Task["litestream:snapshots"].reenable
    Rake::Task["litestream:validate"].reenable
  end

  def teardown
    Litestream.configuration = nil
    ARGV.replace []
  end

  class TestEnvTask < TestLitestreamTasks
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
  end

  class TestReplicateTask < TestLitestreamTasks
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
  end

  class TestRestoreTask < TestLitestreamTasks
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
      fake.expect :call, nil, ["db/test.sqlite3", {"--if-db-not-exists" => nil}]
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

  class TestDatabasesTask < TestLitestreamTasks
    def test_databases_task_with_no_arguments
      fake = Minitest::Mock.new
      fake.expect :call, nil, [{}]
      Litestream::Commands.stub :databases, fake do
        Rake.application.invoke_task "litestream:databases"
      end
      fake.verify
    end

    def test_databases_task_with_arguments
      ARGV.replace ["--", "--no-expand-env"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [{"--no-expand-env" => nil}]
      Litestream::Commands.stub :databases, fake do
        Rake.application.invoke_task "litestream:databases"
      end
      fake.verify
    end

    def test_databases_task_with_arguments_without_separator
      ARGV.replace ["--no-expand-env"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [{}]
      Litestream::Commands.stub :databases, fake do
        Rake.application.invoke_task "litestream:databases"
      end
      fake.verify
    end
  end

  class TestGenerationsTask < TestLitestreamTasks
    def test_generations_task_with_only_database_using_single_dash
      ARGV.replace ["--", "-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3", {}]
      Litestream::Commands.stub :generations, fake do
        Rake.application.invoke_task "litestream:generations"
      end
      fake.verify
    end

    def test_generations_task_with_only_database_using_double_dash
      ARGV.replace ["--", "--database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3", {}]
      Litestream::Commands.stub :generations, fake do
        Rake.application.invoke_task "litestream:generations"
      end
      fake.verify
    end

    def test_generations_task_with_arguments
      ARGV.replace ["--", "-database=db/test.sqlite3", "--if-db-not-exists"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3", {"--if-db-not-exists" => nil}]
      Litestream::Commands.stub :generations, fake do
        Rake.application.invoke_task "litestream:generations"
      end
      fake.verify
    end

    def test_generations_task_with_arguments_without_separator
      ARGV.replace ["-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [nil, {}]
      Litestream::Commands.stub :generations, fake do
        Rake.application.invoke_task "litestream:generations"
      end
      fake.verify
    end
  end

  class TestSnapshotsTask < TestLitestreamTasks
    def test_snapshots_task_with_only_database_using_single_dash
      ARGV.replace ["--", "-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3", {}]
      Litestream::Commands.stub :snapshots, fake do
        Rake.application.invoke_task "litestream:snapshots"
      end
      fake.verify
    end

    def test_snapshots_task_with_only_database_using_double_dash
      ARGV.replace ["--", "--database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3", {}]
      Litestream::Commands.stub :snapshots, fake do
        Rake.application.invoke_task "litestream:snapshots"
      end
      fake.verify
    end

    def test_snapshots_task_with_arguments
      ARGV.replace ["--", "-database=db/test.sqlite3", "--if-db-not-exists"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3", {"--if-db-not-exists" => nil}]
      Litestream::Commands.stub :snapshots, fake do
        Rake.application.invoke_task "litestream:snapshots"
      end
      fake.verify
    end

    def test_snapshots_task_with_arguments_without_separator
      ARGV.replace ["-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [nil, {}]
      Litestream::Commands.stub :snapshots, fake do
        Rake.application.invoke_task "litestream:snapshots"
      end
      fake.verify
    end
  end

  class TestValidateTask < TestLitestreamTasks
    def test_validate_task_with_only_database_using_single_dash
      ARGV.replace ["--", "-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      out = nil
      fake.expect :call, {size:{original: 1, replica: 1}, tables:{original: 2, replica: 2}}, ["db/test.sqlite3", {}]

      Litestream::Commands.stub :validate, fake do
        out, _err = capture_io do
          Rake.application.invoke_task "litestream:validate"
        end
      end

      fake.verify
      assert_match(/size\s+original\s+1\s+replica\s+1/, out)
      assert_match(/tables\s+original\s+2\s+replica\s+2/, out)
    end

    def test_validate_task_with_only_database_using_double_dash
      ARGV.replace ["--", "--database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      out = nil
      fake.expect :call, {size:{original: 1, replica: 1}, tables:{original: 2, replica: 2}}, ["db/test.sqlite3", {}]

      Litestream::Commands.stub :validate, fake do
        out, _err = capture_io do
          Rake.application.invoke_task "litestream:validate"
        end
      end

      fake.verify
      assert_match(/size\s+original\s+1\s+replica\s+1/, out)
      assert_match(/tables\s+original\s+2\s+replica\s+2/, out)
    end

    def test_validate_task_with_arguments
      ARGV.replace ["--", "-database=db/test.sqlite3", "--if-db-not-exists"]
      fake = Minitest::Mock.new
      out = nil
      fake.expect :call, {size:{original: 1, replica: 1}, tables:{original: 2, replica: 2}}, ["db/test.sqlite3", {"--if-db-not-exists" => nil}]

      Litestream::Commands.stub :validate, fake do
        out, _err = capture_io do
          Rake.application.invoke_task "litestream:validate"
        end
      end

      fake.verify
      assert_match(/size\s+original\s+1\s+replica\s+1/, out)
      assert_match(/tables\s+original\s+2\s+replica\s+2/, out)
    end

    def test_validate_task_with_arguments_without_separator
      ARGV.replace ["-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      out = nil
      fake.expect :call, nil, [nil, {}]

      Litestream::Commands.stub :validate, fake do
        out, _err = capture_io do
          Rake.application.invoke_task "litestream:validate"
        end
      end

      fake.verify
      assert_equal "", out
    end
  end
end
