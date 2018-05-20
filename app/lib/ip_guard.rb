class IpGuard
  REDIS_KEY_PREFIX = "ip_guard:throttles:"

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)

    return @app.(env) if self.class.whitelisted?(req)

    return [429, {'Content-Type' => 'text/plain'}, ["Rate limit exceeded. Try again in #{1.day} seconds"]] if self.class.blacklisted?(req)

    throttled, expires = self.class.throttled?(req)
    if throttled
      [429, {'Content-Type' => 'text/plain'}, ["Rate limit exceeded. Try again in #{expires} seconds"]]
    else
      @app.(env)
    end
  end

  class << self
    def blacklisted?(req)
      blacklists.any?{ |_, matcher| matcher.(req) }
    end

    def whitelisted?(req)
      whitelists.any?{ |_, matcher| matcher.(req) }
    end

    def throttled?(req)
      throttlers.each do |_, th|
        throttled, expires = th.(req)
        return [throttled, expires] if throttled
      end
      [false, 0]
    end

    def blacklist(name, &block)
      blacklists[name] = IpGuard::Matcher.new('blacklist', name, block)
    end

    def whitelist(name, &block)
      whitelists[name] = IpGuard::Matcher.new('whitelist', name, block)
    end

    def throttle(name, limit:, period:, &block)
      raise ArgumentError, 'set redis client before using throttle' unless redis_client
      throttlers[name] = IpGuard::Throttler.new(name, limit, period, block)
    end

    def clear!
      @blacklists = {}
      @whitelists = {}
      @throttles = {}
    end

    def clear_counters!
      redis_client.keys(REDIS_KEY_PREFIX + "*").each do |key|
        redis_client.del(key)
      end
    end

    attr_accessor :redis_client

    def blacklists
      @blacklists ||= {}
    end

    def whitelists
      @whitelists ||= {}
    end

    def throttlers
      @throttles ||= {}
    end
  end
end
