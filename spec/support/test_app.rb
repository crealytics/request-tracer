require 'json'
require 'faraday'
require 'request_tracer'
require 'request_tracer/trace'
require 'rest-client'

class TestApp
  RequestTracer.integrate_with(:rest_client)
  def call(env)
    store_current_trace_info # store so tests can look at historical data

    req = Rack::Request.new(env)
    if req.path == '/hello_world'
      [ 200, {'Content-Type' => 'application/json'}, ['Hello World'] ]
    elsif req.path == '/ouroboros' # this path will cause the TestApp to call the helloworld path of the app in certain port
      port = Rack::Utils.parse_query(env['QUERY_STRING'], "&")['out_port']
      response = RestClient.get("http://localhost:#{port}/hello_world")
      [ 200, {'Content-Type' => 'application/json'}, ["Ouroboros says #{response}"]]
    else
      [ 500, {'Content-Type' => "text/txt"}, ["Unrecognized path #{req.path}"]]
    end
  end

  def store_current_trace_info
    $stderr.puts "%%% #{(Time.now.to_f * 1000).to_i} #{RequestTracer.latest_trace_hash.to_json}"
  end
end
