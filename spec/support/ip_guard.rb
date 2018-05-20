shared_context 'ip guard' do
  let(:app) do
    lambda { |_env| [200, {'Content-Type' => 'text/plain'}, ['ok']] }
  end
  let(:wrapper_app) do
    application = app
    Rack::Builder.app do
      use Rack::CommonLogger
      use Rack::Lint
      use IpGuard
      use Rack::Lint
      run application
    end
  end

  let(:ip) {'1.2.3.4'}
  let!(:throttler) { IpGuard.new(app) }
  def make_request(with_ip: nil, params: {})
    with_ip ||= ip
    request = Rack::MockRequest.env_for('example.com/', {'HTTP_X_FORWARDED_FOR' => with_ip, params: params})
    wrapper_app.(request)
  end

  let(:response) do
    status, headers, body = make_request
    {status: status, headers: headers, body: body}
  end
  let(:status) { response[:status] }
  let(:headers) { response[:headers] }
  let(:body) do
    s = ""
    response[:body].each{|part| s += part }
    s
  end

  before do
    IpGuard.clear!
    IpGuard.clear_counters!
  end
end
