class IpGuard
  class Throttler
    def initialize(name, limit, period, block)
      @name = name
      @limit = limit
      @period = period
      @block = block || self.class.from_ip(name)
    end

    def call(req)
      matched = @block.(req)
      return false, 0 unless matched

      cnt, expires = incr(matched, period(req))
      if cnt > limit(req)
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

    class << self
      def from_ip(ip)
        ip = IPAddr.new(ip)
        Proc.new do |req|
          ip.include?(IPAddr.new(req.ip)) && req.ip
        end
      rescue IPAddr::InvalidAddressError
        msg =  "incorrect throttler #{ip},\n"\
               "possible options:\n"\
               "10.0.0.0/24, limit: 100, period: 5.minutes\n"\
               "127.0.0.1, limit: 100, period: 5.minutes\n"\
               "'my-custom-throttler', limit: 100, period: 5.minutes {|req| req.ip == '127.0.0.1' && req.ip }"
        raise ArgumentError, msg
      end
    end
  end
end
