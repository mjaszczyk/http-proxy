module Cache
  class HttpCache
    CACHED_RESPONSES = [:ok, :not_found]
    CACHED_METHODS = [:GET, :HEAD]
    MIN_CACHE_TTL = 1

    def cacheable?(request, response)
      CACHED_METHODS.include? request.method.upcase.to_sym and CACHED_RESPONSES.include? response.sym_status and
          cache_ttl(response) > MIN_CACHE_TTL
    end

    def cache_ttl(response)
      cache_control = lambda { |cache_control| return cache_control.nil? ? nil : /^max-age=(?<ttl>\d+)$/.match(cache_control) }.
          call(response.headers['Cache-Control'])
      cache_control.nil? ? 0 : cache_control[:ttl].to_i
    end

    def cache_hash(request)
      "#{request.method}#{request.url}#{request.query_string}"
    end
  end
end