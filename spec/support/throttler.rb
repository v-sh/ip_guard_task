require_relative '../../app/lib/throttler'

shared_context 'throttler' do
  let(:app) { ->(env) { [200, env, "ok"] } }
  let!(:throttler) { Throttler.new(app) }
  let(:request) { Rack::MockRequest.env_for('example.com/', {}) }
  let(:response) do
    status, headers, body = throttler.(request)
    {status: status, headers: headers, body: body}
  end
  let(:status) { response[:status] }
  let(:headers) { response[:headers] }
  let(:body) { response[:body] }
end
