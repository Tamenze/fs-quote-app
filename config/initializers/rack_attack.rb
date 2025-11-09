# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle ALL requests per Client IP: 100 req/min
  throttle("req/ip", limit: 100, period: 60) { |req| req.ip }
  
  # Throttle login attempts specifically
  throttle("login/ip", limit: 10, period: 60) { |req| req.post? && req.path == "/api/v1/sessions" ? req.ip : nil }
  
  #Allow health checks
  safelist("health") { |req| req.path == "/up" }
end

# Register the middleware so it runs before Rails routing.
Rails.application.config.middleware.use Rack::Attack
