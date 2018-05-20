class IpGuard
  REDIS_KEY_PREFIX = "ip_guard:throttles:"

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)

    return @app.(env) if self.class.whitelisted?(req)

    if self.class.blacklisted?(req)
      log(req)
      return throttled_response(1.day)
    end

    throttled, expires = self.class.throttled?(req)
    if throttled
      log(req)
      throttled_response(expires)
    else
      @app.(env)
    end
  end

  def log(req)
    client_ip = req.env["ip_guard.client_ip"]
    if (name = req.env['ip_guard.blacklist'])
      self.class.logger.info("IpGuard: #{client_ip} is blocked by '#{name}'")
    end
    if (name = req.env['ip_guard.throttled'])
      self.class.logger.info("IpGuard: #{client_ip} was throttled by '#{name}'")
    end
  end

  def throttled_response(expires)
    [429, {'Content-Type' => 'text/plain'}, ["Rate limit exceeded. Try again in #{expires} seconds"]]
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
    attr_writer :logger

    def logger
      @logger ||= Logger.new(IO::NULL)
    end

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
