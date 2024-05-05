require "test_helper"

class Litestream::TestProcessesController < ActionDispatch::IntegrationTest
  test "should show the process" do
    stubbed_process = {pid: "12345", status: "sleeping", started: DateTime.now}
    stubbed_databases = [
      {"path" => "[ROOT]/storage/test.sqlite3",
       "replicas" => "s3",
       "generations" => [
         {"generation" => SecureRandom.hex,
          "name" => "s3",
          "lag" => "23h59m59s",
          "start" => "2024-05-02T11:32:16Z",
          "end" => "2024-05-02T11:33:10Z",
          "snapshots" => [
            {"index" => "0", "size" => "4145735", "created" => "2024-05-02T11:32:16Z"}
          ]}
       ]}
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

        assert_select "#databases li", 1 do
          assert_select "h2 code", stubbed_databases[0]["path"]
          assert_select "details##{stubbed_databases[0]["generations"][0]["generation"]}"
        end
      end
    end
  end
end
