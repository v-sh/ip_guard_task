IpGuard.redis_client = Redis.new(url: (ENV['IP_GUARD_REDIS'] || 'redis://127.0.0.1:6379/10'))
IpGuard.logger = Rails.logger
