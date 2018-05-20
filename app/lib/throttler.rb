class Throttler
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)

    return @app.(env) if self.class.whitelisted?(req)

    return [429, {}, "Rate limit exceeded. Try again in #{1.day} seconds"] if self.class.blacklisted?(req)

    throttled, expires = self.class.throttled?(req)
    if throttled
      [429, {}, "Rate limit exceeded. Try again in #{expires} seconds"]
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

    def throttled?(_req)
      [false, 0]
    end

    def blacklist(name, &block)
      blacklists[name] = Throttler::Matcher.new('blacklist', name, block)
    end

    def whitelist(name, &block)
      whitelists[name] = Throttler::Matcher.new('whitelist', name, block)
    end

    def throttle(name, &block)
    end

    def clear!
      @blacklists = {}
      @whitelists = {}
      @throttles = {}
    end

    def blacklists
      @blacklists ||= {}
    end

    def whitelists
      @whitelists ||= {}
    end

    def throttles
      @throttles ||= {}
    end
  end
end
