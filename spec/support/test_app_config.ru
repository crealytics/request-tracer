require 'request_tracer'
require 'request_tracer/integration/rack_handler'
require 'base64'
require File.join(`pwd`.chomp, 'spec', 'support', 'test_app')

request_tracer_config = {
  service_name: 'your service name here'
}
puts "Starting service"

use RequestTracer::Integration::RackHandler, request_tracer_config
run TestApp.new
