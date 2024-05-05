require "test_helper"

class Litestream::TestProcessesController < ActionDispatch::IntegrationTest
  test "should show the process" do
    stubbed_process = {pid: "12345", status: "sleeping", started: DateTime.now}
    Litestream.stub :replicate_process, stubbed_process do
      get litestream.process_url
      assert_response :success

      assert_select "#process_12345", 1 do
        assert_select "small", "sleeping"
        assert_select "code", "12345"
        assert_select "time", stubbed_process[:started].to_formatted_s(:db)
      end
    end
  end
end
