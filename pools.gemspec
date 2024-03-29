Gem::Specification.new do |s|
  s.name              = "pools"
  s.version           = "2.0.1"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Generalized connection pooling"
  s.homepage          = "http://github.com/rykov/pools"
  s.email             = "mrykov@gmail"
  s.authors           = [ "Michael Rykov" ]
  s.license           = "MIT"

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")

  s.add_dependency    'activesupport', '>= 3.0.0'

  s.description = <<DESCRIPTION
Generalized connection pooling
DESCRIPTION
end
