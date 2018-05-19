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
    def blacklisted?(_req)
      false
    end

    def whitelisted?(_req)
      false
    end

    def throttled?(_req)
      [false, 0]
    end
  end
end
