require 'request_tracer'
require 'pry'

RSpec.configure do |config|
  config.order = :random
  config.run_all_when_everything_filtered = true
end
