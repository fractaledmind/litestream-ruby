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
    Rake::Task["litestream:ltx"].reenable
    Rake::Task["litestream:status"].reenable
    Rake::Task["litestream:generations"].reenable
    Rake::Task["litestream:snapshots"].reenable
    Rake::Task["litestream:wal"].reenable
  end

  def teardown
    ARGV.replace []
  end

  class TestEnvTask < TestLitestreamTasks
    def test_env_task_when_nothing_configured_prints
      out, _err = capture_io do
        Rake.application.invoke_task "litestream:env"
      end

      assert_equal <<~TXT, out
        LITESTREAM_REPLICA_BUCKET=
        LITESTREAM_REPLICA_REGION=
        LITESTREAM_REPLICA_ENDPOINT=
        LITESTREAM_ACCESS_KEY_ID=
        LITESTREAM_SECRET_ACCESS_KEY=
      TXT
    end
  end

  class TestReplicateTask < TestLitestreamTasks
    def test_replicate_task_with_no_arguments
      fake = Minitest::Mock.new
      fake.expect :call, nil, []
      Litestream::Commands.stub :replicate, fake do
        Rake.application.invoke_task "litestream:replicate"
      end
      fake.verify
    end

    def test_replicate_task_with_arguments
      ARGV.replace ["--", "--no-expand-env"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [], "--no-expand-env": nil
      Litestream::Commands.stub :replicate, fake do
        Rake.application.invoke_task "litestream:replicate"
      end
      fake.verify
    end

    def test_replicate_task_with_arguments_without_separator
      ARGV.replace ["--no-expand-env"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, []
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
      fake.expect :call, [], ["db/test.sqlite3"]
      Litestream::Commands.stub :restore, fake do
        Rake.application.invoke_task "litestream:restore"
      end
      fake.verify
    end

    def test_restore_task_with_only_database_using_double_dash
      ARGV.replace ["--", "--database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3"]
      Litestream::Commands.stub :restore, fake do
        Rake.application.invoke_task "litestream:restore"
      end
      fake.verify
    end

    def test_restore_task_with_arguments
      ARGV.replace ["--", "-database=db/test.sqlite3", "--if-db-not-exists"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3"], "--if-db-not-exists": nil
      Litestream::Commands.stub :restore, fake do
        Rake.application.invoke_task "litestream:restore"
      end
      fake.verify
    end

    def test_restore_task_with_arguments_without_separator
      ARGV.replace ["-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [nil]
      Litestream::Commands.stub :restore, fake do
        Rake.application.invoke_task "litestream:restore"
      end
      fake.verify
    end
  end

  class TestDatabasesTask < TestLitestreamTasks
    def test_databases_task_with_no_arguments
      fake = Minitest::Mock.new
      fake.expect :call, nil, []
      Litestream::Commands.stub :databases, fake do
        Rake.application.invoke_task "litestream:databases"
      end
      fake.verify
    end

    def test_databases_task_with_arguments
      ARGV.replace ["--", "--no-expand-env"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [], "--no-expand-env": nil
      Litestream::Commands.stub :databases, fake do
        Rake.application.invoke_task "litestream:databases"
      end
      fake.verify
    end

    def test_databases_task_with_arguments_without_separator
      ARGV.replace ["--no-expand-env"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, []
      Litestream::Commands.stub :databases, fake do
        Rake.application.invoke_task "litestream:databases"
      end
      fake.verify
    end
  end

  class TestLtxTask < TestLitestreamTasks
    def test_ltx_task_with_only_database_using_single_dash
      ARGV.replace ["--", "-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3"]
      Litestream::Commands.stub :ltx, fake do
        Rake.application.invoke_task "litestream:ltx"
      end
      fake.verify
    end

    def test_ltx_task_with_only_database_using_double_dash
      ARGV.replace ["--", "--database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3"]
      Litestream::Commands.stub :ltx, fake do
        Rake.application.invoke_task "litestream:ltx"
      end
      fake.verify
    end

    def test_ltx_task_with_arguments
      ARGV.replace ["--", "-database=db/test.sqlite3", "--level=all"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3"], "--level": "all"
      Litestream::Commands.stub :ltx, fake do
        Rake.application.invoke_task "litestream:ltx"
      end
      fake.verify
    end

    def test_ltx_task_with_arguments_without_separator
      ARGV.replace ["-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [nil]
      Litestream::Commands.stub :ltx, fake do
        Rake.application.invoke_task "litestream:ltx"
      end
      fake.verify
    end
  end

  class TestStatusTask < TestLitestreamTasks
    def test_status_task_with_database
      ARGV.replace ["--", "-database=db/test.sqlite3"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3"]
      Litestream::Commands.stub :status, fake do
        Rake.application.invoke_task "litestream:status"
      end
      fake.verify
    end

    def test_status_task_without_database
      ARGV.replace ["--"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [nil]
      Litestream::Commands.stub :status, fake do
        Rake.application.invoke_task "litestream:status"
      end
      fake.verify
    end

    def test_status_task_with_arguments
      ARGV.replace ["--", "--database=db/test.sqlite3", "--json"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, ["db/test.sqlite3"], "--json": nil
      Litestream::Commands.stub :status, fake do
        Rake.application.invoke_task "litestream:status"
      end
      fake.verify
    end

    def test_status_task_with_arguments_without_separator
      ARGV.replace ["--json"]
      fake = Minitest::Mock.new
      fake.expect :call, nil, [nil]
      Litestream::Commands.stub :status, fake do
        Rake.application.invoke_task "litestream:status"
      end
      fake.verify
    end
  end

  class TestRemovedTasks < TestLitestreamTasks
    %w[generations snapshots wal].each do |command|
      define_method(:"test_#{command}_task_aborts_with_migration_message") do
        _out, err = capture_io do
          error = assert_raises(SystemExit) do
            Rake.application.invoke_task "litestream:#{command}"
          end
          assert_equal 1, error.status
        end

        assert_equal "`#{command}` was removed in Litestream 0.5; use `ltx` (see README, Upgrading from 0.3)\n", err
      end
    end
  end
end
