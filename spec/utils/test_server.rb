require 'reel'
require 'celluloid'


class TestServer < Reel::Server
  include Celluloid::Logger

  def initialize(host, port, &request_handler)
    super(host, port, &method(:on_connection))
    if block_given?
      @request_handler = request_handler
    else
      @request_handler = method(:handle_request)
    end
    info "Test server listening on #{host}:#{port}"
  end

  def on_connection(connection)
    connection.each_request do |request|
      @request_handler.call(request)
    end
  end

  def handle_request(request)
    request.respond :ok, {'Cache-Control' => 'max-age=10'}, 'Hello, world!'
    info "Request: #{request.method} #{request.url}, Response: #{:ok}"
  end

end
