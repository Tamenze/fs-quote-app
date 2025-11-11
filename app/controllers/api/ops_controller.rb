module Api
  class OpsController < ApplicationController

    def sentry_ping
      Sentry.capture_message("Sentry prod ping #{Time.now.to_i}", level: :info)
      render json: { ok: true }
    end

    def sentry_boom
      # This will raise and be auto-captured by sentry-rails
      1 / 0
    end
  end
end
