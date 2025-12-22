# frozen_string_literal: true

require 'rack/attack'
require 'active_support/cache'
require 'active_support/notifications'

# Configuration for Rack::Attack rate limiting
# See https://github.com/rack/rack-attack for documentation

class Rack::Attack
  # Use in-memory cache store for rate limiting
  # For production with multiple servers, consider using Redis or Memcached
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Throttle all requests by IP address
  # Allow 100 requests per minute per IP for general browsing
  throttle('req/ip', limit: 100, period: 60, &:ip)

  # Throttle API verification endpoint
  # Allow 100 requests per minute per IP for onboarding flows
  throttle('api/verify/ip', limit: 100, period: 60) do |req|
    req.ip if req.path.start_with?('/api/v1/verify')
  end

  # Throttle login attempts to prevent brute force attacks
  # Allow 5 login attempts per minute per IP
  throttle('logins/ip', limit: 5, period: 60) do |req|
    req.ip if req.path.start_with?('/admin/login', '/super-admin/login') && req.post?
  end

  # Throttle CSV uploads to prevent resource exhaustion
  # Allow 10 uploads per hour per IP
  throttle('uploads/ip', limit: 10, period: 3600) do |req|
    req.ip if req.path == '/admin/upload' && req.post?
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: 'Rate limit exceeded. Please try again later.' }.to_json]
    ]
  end
end
