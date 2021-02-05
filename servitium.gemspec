# frozen_string_literal: true

require_relative 'lib/servitium/version'

Gem::Specification.new do |spec|
  spec.name          = 'servitium'
  spec.version       = Servitium::VERSION
  spec.authors       = ['Tom de Grunt']
  spec.email         = ['tom@degrunt.nl']

  spec.summary       = 'Service objects'
  spec.description   = 'An implementation of the command pattern for Ruby'
  spec.homepage      = 'https://entropydecelerator.com/components/servitium'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.5')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://code.entropydecelerator.com/components/servitium'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'active_attr', '>= 0.15'
  spec.add_dependency 'activejob', '> 5.1'
  spec.add_dependency 'activemodel', '> 5.1'
  spec.add_dependency 'activerecord', '> 5.1'
  spec.add_dependency 'activesupport', '> 5.1'
  spec.add_dependency 'i18n', '>= 0.7'

  spec.add_development_dependency 'auxilium', '~> 0.2'
  spec.add_development_dependency 'minitest', '~> 5.11'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-rails', '~> 0.3'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.79'
end
