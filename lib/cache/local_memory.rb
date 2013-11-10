require 'celluloid'
require_relative 'http_cache'


module Cache
  class LocalMemory < Cache::HttpCache
    include Celluloid
    include Celluloid::Logger

    def initialize
      @cache = {}
      @cache_timers = {}
    end

    def cache_response(request, response)
      ttl = cache_ttl(response)
      req_hash = cache_hash(request)

      timer = @cache_timers.delete(req_hash)
      unless timer.nil?
        timer.cancel
      end

      timer = after(ttl) do
        debug "Cached for #{req_hash} expired after #{ttl}s"
        @cache.delete(req_hash)
        @cache_timers.delete(req_hash)
      end

      @cache[req_hash] = response
      @cache_timers[req_hash] = timer
      debug "Response cached for #{ttl}s as #{req_hash}"
    end

    def get_response(request)
      @cache[cache_hash(request)]
    end

  end
end