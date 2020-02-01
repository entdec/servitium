# frozen_string_literal: true

namespace :servitium do
  desc 'Release a new version'
  task :release do
    version_file = './lib/servitium/version.rb'
    File.open(version_file, 'w') do |file|
      file.puts <<~EOVERSION
        # frozen_string_literal: true

        module Servitium
          VERSION = '#{Servitium::VERSION.split('.').map(&:to_i).tap { |parts| parts[2] += 1 }.join('.')}'
        end
      EOVERSION
    end
    module Servitium
      remove_const :VERSION
    end
    load version_file
    puts "Updated version to #{Servitium::VERSION}"

    # spec = Gem::Specification.find_by_name('servitium')
    # spec.version = Servitium::VERSION

    `git commit lib/servitium/version.rb -m "Version #{Servitium::VERSION}"`
    `git push`
    `git tag #{Servitium::VERSION}`
    `git push --tags`
  end
end
