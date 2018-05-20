require 'rails_helper'
require 'support/ip_guard'

describe ::IpGuard::Throttler do
  include_context 'ip guard'
  let(:limit) { 1 }
  let(:period) { 1 }
  let(:logger) { Logger.new(IO::NULL)  }
  before do
    IpGuard.logger = logger
  end
  after do
    IpGuard.logger = nil
  end

  it 'writes nothing on succesful request' do
    expect(logger).not_to receive(:info)
    make_request
  end

  it 'write to log when block client by blacklist' do
    IpGuard.blacklist '1.2.3.4'
    expect(logger).to receive(:info).with("IpGuard: 1.2.3.4 is blocked by '1.2.3.4'")
    make_request
  end
  it 'write to log when block client by blacklist' do
    IpGuard.throttle('everything', limit: limit, period: period)
    expect(logger).to receive(:info).once.with("IpGuard: 1.2.3.4 was throttled by 'everything'")
    make_request
    make_request
  end
end
