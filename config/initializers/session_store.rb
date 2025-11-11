Rails.application.config.session_store :cookie_store,
  key: "_aword_session",
  same_site: Rails.env.production? ? :none : :lax, # cross-site in prod, same-site in dev
  secure: Rails.env.production?, # HTTPS required when SameSite=None
  httponly: true
