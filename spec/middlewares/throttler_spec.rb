require 'spec_helper'
require 'support/throttler'

describe ::Throttler do
  include_context 'throttler'

  context 'without any setup' do
    it 'calls app' do
      expect(app).to receive(:call).and_call_original
      expect(status).to eq(200)
      expect(body).to eq('ok')
    end
  end

  shared_context 'request whitelisted' do
    before do
      allow(Throttler).to receive(:whitelisted?).and_return(true)
    end
  end

  context 'when request is blacklisted' do
    before do
      allow(Throttler).to receive(:blacklisted?).and_return(true)
    end

    it 'asks you to retry' do
      expect(status).to eq(429)
      expect(body).to include('Rate limit exceeded')
    end

    context 'but also whitelisted' do
      include_context 'request whitelisted'
      it 'succeds' do
        expect(status).to eq(200)
        expect(body).to eq('ok')
      end
    end
  end

  context 'when request is throttled' do
    before do
      allow(Throttler).to receive(:throttled?).and_return(true, 10)
      expect(status).to eq(429)
      expect(body).to eq('Rate limit exceeded. Try again in 10 seconds')
    end
  end
end
