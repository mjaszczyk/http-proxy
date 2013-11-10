require 'celluloid-http'


module Forwarder
  class ProxyRequest < Celluloid::Http::Request

    def initialize(url, headers = {}, options = {})
      super(url, options)
      @headers = headers
    end

    def to_s
      "#{method.to_s.upcase} #{uri} HTTP/#{DEFAULT_HTTP_VERSION}\nHost: #{host}\n#{headers_to_s}\n\n#{body}"
    end

    def headers_to_s
      @headers.map { |header, value| "#{header.upcase.to_s.gsub(/_/, '-')}: #{value}" }.join("\n")
    end

  end
end