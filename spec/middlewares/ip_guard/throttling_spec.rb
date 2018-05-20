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
end
