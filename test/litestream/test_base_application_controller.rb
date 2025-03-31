require "test_helper"

class Litestream::BaseApplicationControllerTest < ActiveSupport::TestCase
  test "engine's ApplicationController inherits from host's ApplicationController by default" do
    assert Litestream::ApplicationController < ApplicationController
  end

  test "engine's ApplicationController inherits from configured base_controller_class" do
    assert Litestream::ApplicationController < MyApplicationController
  end
end
