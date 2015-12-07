# coding: utf-8
require_relative 'lib/request_tracer/version'

Gem::Specification.new do |spec|
  spec.name          = "request-tracer"
  spec.version       = RequestTracer::VERSION
  spec.authors       = ["Martin Mauch"]
  spec.email         = ["martin.mauch@crealytics.com"]
  spec.summary       = %q{Traces requests using the Zipkin HTTP headers}
  spec.description   = %q{This is a tracer that hooks into several components to allow tracing requests across services.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'rest-client'
  spec.add_development_dependency 'bundler',     '~> 1.7'
  spec.add_development_dependency 'rake',        '~> 10.0'
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "rack-test", "~> 0.6"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "guard", "~> 2.13"
  spec.add_development_dependency "guard-rspec", "~> 4.6"
  spec.add_development_dependency "guard-bundler", "~> 2.1"
  spec.add_development_dependency 'geminabox'
  spec.add_development_dependency 'pry'
end
