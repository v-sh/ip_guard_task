require 'rails_helper'

describe IpGuard::Matcher do
  let(:ip) { "1.2.3.4" }
  let(:request_env) { Rack::MockRequest.env_for('example.com/', {'HTTP_X_FORWARDED_FOR' => ip}) }
  let(:request) { Rack::Request.new(request_env) }

  describe '#new' do
    context 'with wrong params' do
      it do
        expect do
          IpGuard::Matcher.new("whitelist", "name")
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#call' do
    context 'when configured with ip address' do
      let(:matcher_string) { '1.2.3.4' }
      let(:matcher) { IpGuard::Matcher.new("whitelist", matcher_string) }

      context 'called with matching ip' do
        it 'returns true' do
          expect(matcher.(request)).to eq(true)
          expect(request.env["ip_guard.whitelist"]).to eq('1.2.3.4')
        end
      end

      context 'called with not matching ip' do
        let(:ip) { '1.2.3.5' }
        it 'returns false' do
          expect(matcher.(request)).to eq(false)
          expect(request.env["ip_guard.whitelist"]).to be_nil
        end
      end
    end

    context 'when configured with ip subnet' do
      let(:matcher_string) { '1.2.3.0/24' }
      let(:matcher) { IpGuard::Matcher.new("whitelist", matcher_string) }

      context 'called with matching ip' do
        it 'returns true' do
          expect(matcher.(request)).to eq(true)
          expect(request.env["ip_guard.whitelist"]).to eq('1.2.3.0/24')
        end
      end

      context 'called with not matching ip' do
        let(:ip) { '1.2.4.0' }
        it 'returns false' do
          expect(matcher.(request)).to eq(false)
          expect(request.env["ip_guard.whitelist"]).to be_nil
        end
      end
    end

    context 'when configured with block' do
      let(:block) { Proc.new {true} }
      let(:matcher) { IpGuard::Matcher.new("whitelist", 'custom matcher', block) }

      it 'calls block' do
        expect(block).to receive(:call).with(request)
        matcher.(request)
      end

      context 'when block returns true' do
        it 'returns true' do
          expect(matcher.(request)).to eq(true)
        end
      end
      context 'when block returns false' do
        let(:block) { Proc.new {false} }
        it 'returns false' do
          expect(matcher.(request)).to eq(false)
        end
      end
    end
  end
end
