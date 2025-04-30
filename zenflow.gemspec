lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'yaml'
require 'zenflow/helpers/version'
require 'zenflow/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 3.1.0'
  s.name        = "zenflow"
  s.version     = Zenflow::VERSION.to_s
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Kittelson", "Brandon Arbini", "Chris Warren"]
  s.email       = ["a@zencoder.com", "b@zencoder.com", "c@zencoder.com"]
  s.homepage    = "https://github.com/zencoder/zenflow"
  s.summary     = "Branch management and deployment tool."
  s.description = "Zenflow is a development workflow management tool."
  s.license     = 'MIT'
  s.executables << "zenflow"

  # s.add_development_dependency('guard-rspec', '~> 3.0.2')
  s.add_dependency "httparty", "~> 0.23.1"
  s.add_dependency "rainbow", "~> 3.1"
  s.add_dependency "terminal-table", "4.0.0"
  s.add_dependency "thor", "~> 1.3.2"
  s.add_development_dependency('byebug')
  s.add_development_dependency('fuubar', '~> 2.5.1')
  s.add_development_dependency('rspec', '~> 3.13')
  s.add_development_dependency('simplecov', '~> 0.22.0')
  s.add_development_dependency('vcr', '~> 6.3.1')
  s.add_development_dependency('webmock', '~> 3.25.1')
  s.files = `git ls-files`.split("\n")
  s.require_path = "lib"
end
