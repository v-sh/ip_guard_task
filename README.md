# IpGuard
test task
* one controller returns 'ok'
* throttle requests(100 requests per 1 hour)

# run in development mode

```
docker-compose up
# in the new tab
docker-compose exec backend bash
bundle install
bundle exec rails db:create
bundle exec rspec
bundle exec rails s
```

# features
* whitelists
* blacklists
* throttling
* dynamic period and limit
* dynamic client_ids
* redis a storage
* logging
* tolerant to rails unavailability

# Usage
```ruby
IpGuard.whitelist '1.2.3.4'
IpGuard.whitelist '1.2.3.0/24'
IpGuard.whitelist do |req|
  req.ip == '1.2.3.4' # any other mather
end
#same for blacklists
IpGuard.blacklist '1.2.3.4'

# throttling
IpGuard.throttle 'name', limit: 10, period: 5.seconds
IpGuard.throttle 'name', limit: 10, period: 5.seconds do |req|
  req.ip # client id for throttling
end
IpGuard.throttle 'name', limit: 10, period: Proc.new{|req| req.ip == '1.2.3.4' ? 10 : 60}
IpGuard.throttle 'name', period: 10, limit: Proc.new{|req| req.ip == '1.2.3.4' ? 10 : 60}
```

# Inspired by
* https://redis.io/commands/incr
* Rack::Attack
