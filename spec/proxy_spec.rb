require 'socket'
require 'celluloid-http'
require_relative '../lib/server'
require_relative 'utils/test_server'


describe 'Proxy' do
  Celluloid.logger = nil

  PROXY_PORT = 8001
  PROXY_BACKENDS = ['127.0.0.1:8002', '127.0.0.1:8003']

  before(:each) do
    @proxy_server = Proxy::Server.new('127.0.0.1', PROXY_PORT, PROXY_BACKENDS)
    @backends = []
    @backends_mock = double('backends_mock', :used_backend => true)
    @backends = PROXY_BACKENDS.map do |backend|
      host, port = backend.split(':')
      TestServer.new(host, port,) do |r|
        @backends_mock.used_backend(backend)
        @backends_mock.handle_request(r)
      end
    end
  end

  after(:each) do
    @proxy_server.terminate
    @backends.each { |b| b.terminate }
  end

  it 'forwards backend response' do
    backend_response = 'Hello'
    backend_status = :ok

    expect(@backends_mock).to receive(:handle_request).exactly(:once) do |r|
      r.respond backend_status, {}, backend_response
    end

    r = Celluloid::Http.get("http://127.0.0.1:#{PROXY_PORT}/test")
    expect(r.body).to eq(backend_response)
    expect(r.sym_status).to eq(backend_status)
  end

  it 'forwards X-Forwarded-For header to the backend' do
    backend_response = 'Hello'
    backend_status = :ok

    proxy_ip = Socket::getaddrinfo(Socket.gethostname, 'echo', Socket::AF_INET)[0][3]

    backend_request = nil
    expect(@backends_mock).to receive(:handle_request).exactly(:once) do |r|
      r.respond backend_status, {}, backend_response
      backend_request = r
    end

    r = Celluloid::Http.get("http://127.0.0.1:#{PROXY_PORT}/test")

    expect(backend_request.headers['X-FORWARDED-FOR']).to be_a_kind_of(String)
    ips = backend_request.headers['X-FORWARDED-FOR'].split(',')
    expect(ips).to include('127.0.0.1')
    expect(ips).to include(proxy_ip)

    expect(r.body).to eq(backend_response)
    expect(r.sym_status).to eq(backend_status)
  end

  it 'caches backend responses' do
    backend_response = 'Hello'
    backend_status = :ok
    backend_response_max_age = 2

    expect(@backends_mock).to receive(:handle_request).exactly(:twice) do |r|
      r.respond backend_status, {'Cache-Control' => "max-age=#{backend_response_max_age}"}, backend_response
    end

    make_req = lambda { Celluloid::Http.get("http://127.0.0.1:#{PROXY_PORT}/test") }

    r = make_req.call
    expect(r.body).to eq(backend_response)
    expect(r.sym_status).to eq(backend_status)
    expect(r.headers['X-Cache']).to eq('MISS')
    expect(r.headers['X-Cacheable']).to eq('true')

    r = make_req.call
    expect(r.body).to eq(backend_response)
    expect(r.sym_status).to eq(backend_status)
    expect(r.headers['X-Cache']).to eq('HIT')
    expect(r.headers['X-Cacheable']).to eq('true')

    sleep backend_response_max_age

    r = make_req.call
    expect(r.body).to eq(backend_response)
    expect(r.sym_status).to eq(backend_status)
    expect(r.headers['X-Cache']).to eq('MISS')
    expect(r.headers['X-Cacheable']).to eq('true')
  end

  it 'handles backend timeouts' do
    backend_response = 'Hello'
    backend_status = :ok
    timeout = 2
    stub_const('Forwarder::Http::DEFAULT_TIMEOUT', timeout)

    expect(@backends_mock).to receive(:handle_request).exactly(:once) do |r|
      sleep timeout + 1
      r.respond backend_status, {}, backend_response
    end

    r = Celluloid::Http.get("http://127.0.0.1:#{PROXY_PORT}/test")
    expect(r.sym_status).to eq(:request_timeout)
  end

  it 'forwards requests to the backends with round robin' do
    backend_response = 'Hello'
    backend_status = :ok
    proxy_calls = PROXY_BACKENDS.size * 2

    expect(@backends_mock).to receive(:handle_request).exactly(proxy_calls) do |r|
      r.respond backend_status, {}, backend_response
    end

    make_req = lambda { Celluloid::Http.get("http://127.0.0.1:#{PROXY_PORT}/test") }

    PROXY_BACKENDS.each do |backend|
      expect(@backends_mock).to receive(:used_backend).with(backend).exactly(:twice)
    end

    proxy_calls.times do
      make_req.call
    end
  end

  it 'handles GET,POST,PUT,DELETE,HEAD requests' do
    backend_status = :ok

    backend_req_method = nil
    expect(@backends_mock).to(receive(:handle_request).at_least(:once)) do |r|
      r.respond backend_status, {}, ''
      backend_req_method = r.method
    end

    make_req = Proc.new do |meth|
      req = Celluloid::Http::Request.new "http://127.0.0.1:#{PROXY_PORT}/test", {:method => meth}
      Celluloid::Http.send_request(req)
    end

    make_req.call 'GET'
    expect(backend_req_method).to eq('GET')

    make_req.call 'POST'
    expect(backend_req_method).to eq('POST')

    make_req.call 'PUT'
    expect(backend_req_method).to eq('PUT')

    make_req.call 'DELETE'
    expect(backend_req_method).to eq('DELETE')

    make_req.call 'HEAD'
    expect(backend_req_method).to eq('HEAD')
  end

end