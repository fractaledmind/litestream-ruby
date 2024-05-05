module Litestream
  class ProcessesController < ApplicationController
    # GET /process
    def show
      @process = Litestream.replicate_process
      @databases = Litestream.databases
    end
  end
end
