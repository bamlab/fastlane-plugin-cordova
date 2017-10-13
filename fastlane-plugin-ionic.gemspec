
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/ionic/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-ionic'
  spec.version       = Fastlane::Ionic::VERSION
  spec.author        = 'Jan Piotrowski'
  spec.email         = 'piotrowski+rubygems@gmail.com'

  spec.summary       = 'Build your Ionic app'
  spec.homepage      = "https://github.com/ionic-zone/fastlane-plugin-ionic"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w[README.md LICENSE]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'fastlane', '>= 1.111.0'
end
