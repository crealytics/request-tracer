Request Tracer
==============
[![Build Status](https://travis-ci.org/crealytics/request-tracer.svg)](https://travis-ci.org/crealytics/request-tracer)

Request Tracer is a Ruby gem that helps tracing requests through a chain of services.
It is based on [ZipkinTracer](https://github.com/openzipkin/zipkin-tracer) but doesn't force you to use Zipkin.

One possible use case is to use your logger to log traces and spans and reuse your
existing log aggregation tool of choice (e.g. ELK) to get all logs across all services
that were involved in a client's service call.

How it works
------------
Request Tracer integrates with various other gems in order to transparently
read incoming trace headers and add trace headers to outgoing service calls.
A good introduction into Zipkin terminology [can be found here](http://www.slideshare.net/johanoskarsson/zipkin-strangeloop/25).

Reading trace headers
---------------------
In your `config.ru` add the RackHandler middleware like this:
```ruby
require 'request_tracer'
require 'request_tracer/integration/rack_handler'

use RequestTracer::Integration::RackHandler
run MyApp.new
```

Writing trace headers
---------------------
Somewhere in your code (e.g. in an initializer under `config/initializers/request-tracing.rb`)
add the following call:
```ruby
RequestTracer.integrate_with(:rest_client)
```
