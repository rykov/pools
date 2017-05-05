source "https://rubygems.org"

# Gemspec only lists command-line tool dependencies
gemspec

# Not-required for execution
group :development, :test do
  gem 'rspec', '~> 2.6.0'
  gem 'redis'

  # http://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
  gem 'rake', '< 11.0'
end