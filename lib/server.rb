require 'reel'
require_relative 'forwarder/http'
require_relative 'cache/local_memory'


module Proxy
  class Server < Reel::Server
    include Celluloid::Logger

    def initialize(host, port, backends)
      super(host, port, &method(:on_connection))
      @forwarder = Forwarder::Http.new backends
      @cache = Cache::LocalMemory.new
      @counter = 0
      info "Proxy listening on #{host}:#{port}"
      debug "Backends: #{backends}"
    end

    def on_connection(connection)
      connection.each_request do |request|
        handle_request(request)
      end
    end

    def handle_request(request)
      @counter += 1

      cached = @cache.get_response(request)
      unless cached.nil?
        return make_response(request, cached, cache_hit = true, cacheable = true)
      end

      begin
        response = @forwarder.forward(request)
      rescue Exception => e
        #puts "err #{connection}, #{e}"
        error "Request: #{request.method} #{request.url}, Error: #{e}"
        request.respond :internal_server_error, 'Error!'
      else
        cacheable = @cache.cacheable?(request, response)
        if cacheable
          @cache.cache_response(request, response)
        end

        make_response(request, response, cache_hit = false, cacheable = cacheable)
      end
    end

    def make_response(request, backend_response, cache_hit = false, cacheable = false)
      headers = {'X-Cache' => cache_hit ? 'HIT': 'MISS', 'X-Cacheable' => cacheable.to_s}
      request.respond backend_response.sym_status, headers, backend_response.body
      info "Request: #{request.method} #{request.url}, Response: #{backend_response.status}, Cache: #{cache_hit}, Cacheable: #{cacheable}"
    end

  end
end
