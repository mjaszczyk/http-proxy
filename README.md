http-proxy
==========

Non-blocking HTTP proxy build on top of [Celluloid](https://github.com/celluloid/celluloid-io/).

## Usage

Install dependencies:

    $ bundle

Run proxy process:

    $ ruby proxy.rb -h

    Usage: proxy.rb [options]
            --host HOSTNAME              Host [127.0.0.1]
            --port N                     Port [3000]
            --backends host:3001,...     Comma separated list of backends [127.0.0.1:3001]
            --loglevel DEBUG/INFO/WARN   Logging level [DEBUG]
        -h, --help                       Show this message

and test http server(s) if needed:

    $ ruby test_server.rb -h

    Usage: test_server.rb [options]
            --host HOSTNAME              Host [127.0.0.1]
            --port N                     Port [3001]
        -h, --help                       Show this message


### Example usage

Proxy:

    $ ruby proxy.rb --backends 127.0.0.1:3001,127.0.0.1:3002

Backend 1:

    $ ruby test_server.rb --port 3001

Backend 2:

    $ ruby test_server.rb --port 3002

Test request:

    $ curl -v http://localhost:3000/test


## Tests

Tests can be performed with following command:

    $ rspec spec/proxy_spec.rb -fd
