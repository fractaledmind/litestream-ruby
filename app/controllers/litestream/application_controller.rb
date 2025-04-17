module Litestream
  class ApplicationController < Litestream.base_controller_class.constantize
    protect_from_forgery with: :exception
    around_action :force_english_locale!

    if Litestream.password
      http_basic_authenticate_with(
        name: Litestream.username,
        password: Litestream.password
      )
    end

    private

    def force_english_locale!(&action)
      I18n.with_locale(:en, &action)
    end
  end
end
