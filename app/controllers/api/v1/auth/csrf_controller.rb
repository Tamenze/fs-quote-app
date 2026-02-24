module Api
  module V1
    module Auth
      class CsrfController < ApplicationController
        # As set with includes in the Application Controller:
        # For non-GET requests, Rails expects:
        #   - a valid authenticity token (e.g., X-CSRF-Token)
        #   - the session cookie that token is tied to


        # Purpose of this endpoint:
        # 1) Ensure the browser receives a session cookie (_aword_session)
        # 2) Provide a CSRF token that is tied to that session
        #
        # Why? On cross-site setups (FE domain != API domain), the first POST from iOS often
        # has no session cookie yet. Rails needs both the session cookie and the CSRF token
        # to validate. Touching the session here forces Set-Cookie, fixing that.

        def show
          # Force a write so Rack emits Set-Cookie: _aword_session=...
          # The key name is arbitrary and never read, just marks the session "dirty".
          session[:_csrf_seed] ||= SecureRandom.hex(8)
          response.set_header("Cache-Control", "no-store")
          response.set_header("Vary", "Origin, Cookie")

          # Ask Rails for the authenticity token tied to THIS session.
          token = form_authenticity_token

          # sends token in JSON also that client then uses to send X-CSRF-Token in header for non-gets
          render json: { csrfToken: token }
        end
      end
    end
  end
end
