require 'bundler/gem_tasks'
require 'rubygems'
require 'bundler'
require 'rake'

Bundler::GemHelper.install_tasks

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  # no rspec available
end
