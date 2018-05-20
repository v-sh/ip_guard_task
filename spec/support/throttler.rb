require_relative '../../app/lib/throttler'

shared_context 'throttler' do
  let(:app) { ->(env) { [200, env, "ok"] } }
  let(:ip) {'1.2.3.4'}
  let!(:throttler) { Throttler.new(app) }
  let(:request) { Rack::MockRequest.env_for('example.com/', {'HTTP_X_FORWARDED_FOR' => ip}) }
  let(:response) do
    status, headers, body = throttler.(request)
    {status: status, headers: headers, body: body}
  end
  let(:status) { response[:status] }
  let(:headers) { response[:headers] }
  let(:body) { response[:body] }

  after do
    Throttler.clear!
  end
end
