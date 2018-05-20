require 'rails_helper'

describe "home controller" do
  before do
    IpGuard.clear!
    IpGuard.clear_counters!
  end

  it 'renders ok' do
    get '/'
    expect(response).to be_successful
    expect(response.body).to eq("ok")
  end

  context 'when ip is blocked' do
    before do
      IpGuard.blacklist('127.0.0.1')
    end

    it 'returns 429' do
      get '/'
      expect(response.status).to eq(429)
      expect(response.body).to match("Rate limit exceeded")
    end
  end

  context 'when ip is blocked by subnetwork' do
    before do
      IpGuard.blacklist('127.0.0.0/24')
    end

    it 'returns 429' do
      get '/'
      expect(response.status).to eq(429)
      expect(response.body).to match("Rate limit exceeded")
    end
  end

  context 'when throttling is enabled' do
    before do
      IpGuard.throttle 'throttle everything', limit: 1, period: 1
    end

    it 'pass first request and stop second' do
      get '/'
      expect(response).to be_successful
      expect(response.body).to eq("ok")
      get '/'
      expect(response.status).to eq(429)
      expect(response.body).to match("Rate limit exceeded")
    end
  end
end
