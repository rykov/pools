require 'rspec/core'
require 'rspec/core/rake_task'

task :default => :spec
task :test    => :spec

task :noop do; end

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec => :noop)