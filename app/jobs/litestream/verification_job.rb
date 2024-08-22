require "active_job"

module Litestream
  class VerificationJob < ActiveJob::Base
    queue_as Litestream.queue

    def perform
      Litestream::Commands.databases.each do |db_hash|
        Litestream.verify!(db_hash["path"])
      end
    end
  end
end
