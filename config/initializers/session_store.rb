Rails.application.config.session_store :cookie_store,
  key: "_aword_session",
  same_site: :lax,
  secure: Rails.env.production?, # HTTPS required when SameSite=None
  httponly: true,
  domain: (ENV["SESSION_DOMAIN"].presence if Rails.env.production?)
