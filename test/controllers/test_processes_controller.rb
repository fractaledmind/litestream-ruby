require "test_helper"

class Litestream::TestProcessesController < ActionDispatch::IntegrationTest
  test "should show the process" do
    stubbed_process = {pid: "12345", status: "sleeping", started: DateTime.now}
    stubbed_databases = [
      {"path" => "[ROOT]/storage/test.sqlite3",
       "replica" => "s3",
       "status" => {"database" => "storage/test.sqlite3", "status" => "ok", "local_txid" => "000000000000000a", "wal_size" => 131072},
       "ltx" => [
         {"level" => 0, "min_txid" => "0000000000000008", "max_txid" => "000000000000000a", "size" => 1013, "timestamp" => "2026-09-08T03:16:43Z"}
       ]},
      {"path" => "[ROOT]/storage/error.sqlite3", "replica" => "s3", "error" => "replica unavailable"}
    ]
    Litestream.stub :replicate_process, stubbed_process do
      Litestream.stub :databases, stubbed_databases do
        get litestream.process_url
        assert_response :success

        assert_select "#process_12345", 1 do
          assert_select "small", "sleeping"
          assert_select "code", "12345"
          assert_select "time", stubbed_process[:started].to_formatted_s(:db)
        end

        assert_select "#databases li", 2
        assert_select "#databases li:first-child" do
          assert_select "h2 code", stubbed_databases[0]["path"]
          assert_select "tbody tr", 1
          assert_select "td", text: "000000000000000a"
        end
        assert_select "#databases li:last-child .text-red-600", "replica unavailable"
      end
    end
  end
end
