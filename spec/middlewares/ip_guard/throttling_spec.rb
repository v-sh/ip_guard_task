require 'rails_helper'
require 'support/ip_guard'

describe ::IpGuard::Throttler do
  include_context 'ip guard'
  let(:limit) { 2 }
  let(:period) { 1 }

  before do
    IpGuard.throttle('everything', limit: limit, period: period)
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
      expect(app).to receive(:call).exactly(2).times.with(hash_including("HTTP_X_FORWARDED_FOR"=>"1.2.3.4")).and_call_original
      expect(app).to receive(:call).exactly(2).times.with(hash_including("HTTP_X_FORWARDED_FOR"=>"1.2.3.5")).and_call_original
      3.times{ make_request(with_ip: '1.2.3.5') }
      3.times{ make_request(with_ip: '1.2.3.4') }
    end
  end

  context 'with proc for limit' do
    let(:limit) do
      Proc.new do |req|
        req.ip == '1.2.3.5' ? 3 : 1
      end
    end

    it 'use different limits' do
      expect(app).to receive(:call).exactly(1).times.with(hash_including("HTTP_X_FORWARDED_FOR"=>"1.2.3.4")).and_call_original
      expect(app).to receive(:call).exactly(3).times.with(hash_including("HTTP_X_FORWARDED_FOR"=>"1.2.3.5")).and_call_original
      5.times{ make_request(with_ip: '1.2.3.5') }
      5.times{ make_request(with_ip: '1.2.3.4') }
    end
  end

  context 'with proc for period' do
    let(:period) do
      Proc.new do |req|
        req.ip == '1.2.3.5' ? 3 : 1
      end
    end
    let(:limit) { 1 }

    it 'use different periods' do
      expect(make_request(with_ip: '1.2.3.4').first).to eq(200)
      expect(make_request(with_ip: '1.2.3.4').first).to eq(429)
      expect(make_request(with_ip: '1.2.3.5').first).to eq(200)
      expect(make_request(with_ip: '1.2.3.5').first).to eq(429)
      sleep(2)
      expect(make_request(with_ip: '1.2.3.4').first).to eq(200)
      expect(make_request(with_ip: '1.2.3.5').first).to eq(429)
    end
  end

  context 'when redis is unavailable' do
    let(:logger) { Logger.new(IO::NULL)  }
    before do
      allow(IpGuard).to receive(:redis_client).and_return( Redis.new(url: "redis://127.0.0.1:1234/10"))
      IpGuard.logger = logger
    end
    after do
      IpGuard.logger = nil
    end

    it 'allows everything and log fails' do
      expect(logger).to receive(:error).twice.with(/IpGuard: cannot connect to redis/)
      expect(make_request.first).to eq(200)
      expect(make_request.first).to eq(200)
    end
  end

  context 'with user defined proc' do
    before do
      IpGuard.clear!
      IpGuard.throttle 'nothing', limit: 2, period: 1 do |req|
        token = req.params["access_token"]
        token == 'CEO token' ? false : token
      end
    end
    context 'block returning false' do
      it 'allows everything' do
        expect(make_request(params: {access_token: '123'}).first).to eq(200)
        expect(make_request(params: {access_token: '123'}).first).to eq(200)
        expect(make_request(params: {access_token: '123'}).first).to eq(429)
        expect(make_request(params: {access_token: '321'}).first).to eq(200)
        expect(make_request(params: {access_token: '321'}).first).to eq(200)
        expect(make_request(params: {access_token: '321'}).first).to eq(429)
        expect(make_request(params: {access_token: 'CEO token'}).first).to eq(200)
        expect(make_request(params: {access_token: 'CEO token'}).first).to eq(200)
        expect(make_request(params: {access_token: 'CEO token'}).first).to eq(200)
      end
    end
  end

end
