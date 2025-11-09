require "rack/attack"

# ---- cache store override (hotfix) ----
# Default is Rails.cache (Solid Cache). Point Rack::Attack at memory store
# while bootstrapping Solid Cache in prod.
if ENV["RACK_ATTACK_USE_MEMORY_CACHE"] == "true"
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
else
  # (Optional/explicit) fall back to Rails.cache
  Rack::Attack.cache.store = Rails.cache
end

# Easy on/off switch via env
Rack::Attack.enabled = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("RACK_ATTACK_ENABLED", "true")
)

class Rack::Attack
  # Throttle ALL requests per Client IP: 100 req/min
  throttle("req/ip", limit: 100, period: 60) { |req| req.ip }

  # Throttle login attempts specifically
  throttle("login/ip", limit: 10, period: 60) do |req|
    req.post? && req.path == "/api/v1/sessions" ? req.ip : nil
  end

  # Allow health checks
  safelist("health") { |req| req.path == "/up" }
end

# Register the middleware so it runs before Rails routing.
Rails.application.config.middleware.use Rack::Attack
