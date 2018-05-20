require 'rails_helper'
require 'support/ip_guard'

describe ::IpGuard::Throttler do
  include_context 'ip guard'
  let(:limit) { 2 }
  let(:period) { 1 }

  before do
    IpGuard.throttle('everything', limit: limit, period: period) do |req|
      req.ip
    end
  end

  it 'allows only limited count of requests' do
    expect(app).to receive(:call).exactly(limit).times.and_call_original
    (limit + 1).times { make_request }
  end

  it 'allows 2 times more within twice longer time' do
    expect(app).to receive(:call).exactly(2*limit).times.and_call_original
    (limit + 1).times { make_request }
    sleep(2) # sorry fot that, but there is not timecop for redis
    (limit + 2).times { make_request }
  end

  context 'for different clients' do
    it 'keeps different counters' do
      expect(app).to receive(:call).exactly(2).times.with(hash_including("HTTP_X_FORWARDED_FOR"=>"1.2.3.4"))
      expect(app).to receive(:call).exactly(2).times.with(hash_including("HTTP_X_FORWARDED_FOR"=>"1.2.3.5"))
      3.times{ make_request(with_ip: '1.2.3.5') }
      3.times{ make_request(with_ip: '1.2.3.4') }
    end
  end
end
