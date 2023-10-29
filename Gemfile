source "https://rubygems.org"

REDIS_VERSION = ENV.fetch("REDIS_VERSION", '5.0').freeze

# Gemspec only lists command-line tool dependencies
gemspec

# Not-required for execution
group :development, :test do
  gem 'redis', "~> #{REDIS_VERSION}"
  gem 'rake', '>= 12.3.3'
  gem 'rspec', '~> 3.0'
end
