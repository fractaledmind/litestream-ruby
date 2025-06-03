module Litestream
  class ApplicationController < Litestream.base_controller_class.constantize
    protect_from_forgery with: :exception

    if Litestream.password
      http_basic_authenticate_with(
        name: Litestream.username,
        password: Litestream.password
      )
    end
  end
end
