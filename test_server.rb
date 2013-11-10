require 'optparse'
require 'ostruct'
require_relative 'spec/utils/test_server'


options = OpenStruct.new
options.host = '127.0.0.1'
options.port = 3001

OptionParser.new do |opts|
  opts.banner = 'Usage: test_server.rb [options]'

  opts.on('--host HOSTNAME', 'Host [127.0.0.1]') do |h|
    options.host = h
  end

  opts.on('--port N', Integer, 'Port [3001]') do |p|
    options.port = p
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

Celluloid.logger.level = Logger::DEBUG

TestServer.run options.host, options.port
