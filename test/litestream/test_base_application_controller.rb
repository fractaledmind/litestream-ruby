require "test_helper"

class Litestream::BaseApplicationControllerTest < ActiveSupport::TestCase
  test "engine's ApplicationController inherits from host's ApplicationController by default" do
    assert Litestream::ApplicationController < ApplicationController
  end

  test "engine's ApplicationController inherits from configured base_controller_class" do
    assert Litestream::ApplicationController < MyApplicationController
  end

  test "engine's ApplicationController uses its own layout regardless of base controller layout" do
    assert_equal "litestream/application", Litestream::ApplicationController._layout
  end
end
