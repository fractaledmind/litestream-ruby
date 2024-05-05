module Litestream
  class RestorationsController < ApplicationController
    # POST /restorations
    def create
      database = params[:database].remove("[ROOT]/")
      dir, file = File.split(database)
      ext = File.extname(file)
      base = File.basename(file, ext)
      now = Time.now.utc.strftime("%Y%m%d%H%M%S")
      backup = File.join(dir, "#{base}-#{now}#{ext}")

      Litestream::Commands.restore(database, async: false, **{"-o" => backup})

      redirect_to root_path, notice: "Restored to <code>#{backup}</code>."
    end
  end
end
