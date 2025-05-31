module Litestream
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    if Litestream.password
      http_basic_authenticate_with(
        name: Litestream.username,
        password: Litestream.password
      )
    end
  end
end
