allowed = ENV.fetch("CORS_ALLOWED_ORIGINS", "").split(",").map(&:strip)
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed) #React dev URL
    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options],
      credentials: true  # allow cookies to be sent
  end
end
