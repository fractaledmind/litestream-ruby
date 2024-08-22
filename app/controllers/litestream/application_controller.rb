module Litestream
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    around_action :force_english_locale!

    if Litestream.configuration.password
      http_basic_authenticate_with(
        name: Litestream.configuration.username,
        password: Litestream.configuration.password
      )
    end

    private

    def force_english_locale!(&action)
      I18n.with_locale(:en, &action)
    end
  end
end
