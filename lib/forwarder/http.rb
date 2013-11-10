require 'socket'
require 'enumerator'
require 'celluloid'
require 'celluloid-http'
require_relative 'proxy_request'


module Forwarder
  class Http
    include Celluloid
    include Celluloid::Logger

    DEFAULT_TIMEOUT = 10

    def initialize(backends)
      @backends = Enumerator.new backends
      @server_addr = Socket::getaddrinfo(Socket.gethostname, 'echo', Socket::AF_INET)[0][3]
    end

    def backend
      if @backends.one?
        @backends.first
      end

      begin
        @backends.next
      rescue StopIteration
        @backends.rewind
        @backends.next
      end
    end

    def forward(request)
      full_url = "http://#{backend}#{request.url}"

      options = {
        method: request.method,
        raw_body: request.read,
      }

      headers = {
        x_forwarded_for: [request.remote_addr, @server_addr].join(','),
      }

      proxied_request = Forwarder::ProxyRequest.new full_url, headers, options
      future = Celluloid::Future.new { Celluloid::Http.send_request(proxied_request) }

      debug "Forwarding request to the backend #{full_url}"

      begin
        future.value DEFAULT_TIMEOUT
      rescue Resolv::ResolvError, Errno::ECONNREFUSED => e
        error "Backend connection error: #{e}"
        Celluloid::Http::Response.new status = 503, body = 'Service unavailable'
      rescue Celluloid::TimeoutError => e
        error "Backend request timeout: #{e}"
        Celluloid::Http::Response.new status = 504, body = 'Request timeout'
      end
    end

  end
end