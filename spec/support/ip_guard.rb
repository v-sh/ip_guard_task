shared_context 'ip guard' do
  let(:app) { ->(env) { [200, env, "ok"] } }
  let(:ip) {'1.2.3.4'}
  let!(:throttler) { IpGuard.new(app) }
  def make_request(with_ip: nil)
    with_ip ||= ip
    request = Rack::MockRequest.env_for('example.com/', {'HTTP_X_FORWARDED_FOR' => with_ip})
    throttler.(request)
  end

  let(:response) do
    status, headers, body = make_request
    {status: status, headers: headers, body: body}
  end
  let(:status) { response[:status] }
  let(:headers) { response[:headers] }
  let(:body) { response[:body] }

  before do
    IpGuard.clear!
    IpGuard.clear_counters!
  end
end
