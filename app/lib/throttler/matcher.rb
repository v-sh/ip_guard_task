class Throttler
  class Matcher
    def initialize(type, name, block = nil)
      @type = type
      @name = name
      @block = block || self.class.from_ip(name)
    end

    def call(req)
      matched = @block.(req)
      if matched
        req.env["throttler.matched.#{@type}"] = @name
      end
      matched
    end

    class << self
      def from_ip(ip)
        ip = IPAddr.new(ip)
        Proc.new do |req|
          ip.include?(IPAddr.new(req.ip))
        end
      rescue IPAddr::InvalidAddressError
        msg =  "incorrect matcher #{ip},\n"\
               'possible options:\n'\
               '10.0.0.0/24\n'\
               '127.0.0.1\n'\
               "'my-custom-matcher' {|req| req.ip == '127.0.0.1'}"
        raise ArgumentError, msg
      end
    end
  end
end
