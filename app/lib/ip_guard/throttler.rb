class IpGuard
  class Throttler
    def initialize(name, limit, period, block)
      @name = name
      @limit = limit
      @period = period
      @block = block || Proc.new { |req| req.ip }
    end

    def call(req)
      matched = @block.(req)
      return false, 0 unless matched

      cnt, expires = incr(matched, period(req))
      if cnt > limit(req)
        req.env["ip_guard.throttled"] = @name
        req.env["ip_guard.client_ip"] = req.ip
        [true, expires]
      else
        [false, 0]
      end
    end

    def incr(client_id, period)
      function = <<-LUA
        local current, ttl
        current = redis.call("incr",KEYS[1])
        if tonumber(current) == 1 then
          redis.call("expire",KEYS[1],KEYS[2])
        end
        ttl = redis.call("ttl", KEYS[1])
        return {current, ttl}
      LUA
      _current, _ttl = redis_client.eval(function, [key(client_id), period])
    end

    def period(req)
      @period.respond_to?(:call) ? @period.(req) : @period
    end

    def limit(req)
      @limit.respond_to?(:call) ? @limit.(req) : @limit
    end

    def redis_client
      ::IpGuard.redis_client
    end

    def key(client_id)
      IpGuard::REDIS_KEY_PREFIX + @name + ':' + client_id
    end
  end
end
