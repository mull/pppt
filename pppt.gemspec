# frozen_string_literal: true

SEQUEL_GEMSPEC = Gem::Specification.new do |s|
  s.name = 'pppt'
  s.version = '0.3.0'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Pretty Please Perform This'
  s.description = 'Easily generatable service objects with Sequel models and Dry::Monads'
  s.homepage = 'https://github.com/weissmalerde/pppt'
  s.author = 'Emil Ahlbäck'
  s.email = 'e.ahlback@gmail.com'
  s.license = 'MIT'
  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/weissmalerde/pppt/issues',
    'source_code_uri'   => 'https://github.com/weissmalerde/pppt',
  }
  s.required_ruby_version = '>= 2.5.0'
  s.files = %w[LICENSE README.md] + Dir['{spec,lib}/**/*.{rb,RB}']
  s.require_path = 'lib'

  s.add_runtime_dependency 'dry-monads', '~> 1.0'
  s.add_runtime_dependency 'sequel', '~> 5'

  s.add_development_dependency 'pg', '~> 1.1'
  s.add_development_dependency 'pry', '~> 0.11.3'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 0.58'
  s.add_development_dependency 'rubocop-rspec', '~> 1.27'
end
