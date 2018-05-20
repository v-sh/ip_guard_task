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
      @store ||= {}
      data = @store[client_id]
      if data
        data = {counter: 0, expires: period.seconds.from_now} if data[:expires] <= Time.current
        @store[client_id] = {counter: data[:counter] + 1, expires: data[:expires]}
      else
        @store[client_id] = {counter: 1, expires: period.seconds.from_now}
      end
      data = @store[client_id]
      [data[:counter], data[:expires] - Time.current]
    end

    def period(req)
      @period.respond_to?(:call) ? @period.(req) : @period
    end

    def limit(req)
      @limit.respond_to?(:call) ? @limit.(req) : @limit
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
