require 'optparse'
require 'ostruct'
require 'logger'
require_relative 'lib/server'


options = OpenStruct.new
options.host = '127.0.0.1'
options.port = 3000
options.backends = %w(127.0.0.1:3001)
options.loglevel = Logger::DEBUG

loglevels = {
  'DEBUG' => Logger::DEBUG,
  'INFO' => Logger::INFO,
  'WARN' => Logger::WARN,
}

OptionParser.new do |opts|
  opts.banner = 'Usage: proxy.rb [options]'

  opts.on('--host HOSTNAME', 'Host') do |h|
    options.host = h
  end

  opts.on('--port N', Integer, 'Port') do |p|
    options.port = p
  end

  opts.on('--backends x,y,z', Array, 'Comma separated list of backends') do |b|
    options.backends = b
  end

  opts.on('--loglevel DEBUG/INFO/WARN', 'Logging level') do |l|
    options.loglevel = loglevels[l] || options.loglevel
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

Celluloid.logger.level = options.loglevel

Proxy::Server.run options.host, options.port, options.backends
