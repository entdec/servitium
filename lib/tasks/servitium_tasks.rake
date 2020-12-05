# frozen_string_literal: true

require 'yaml'
require 'active_support/inflector'

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

  desc 'Convert localization keys'
  task :convert_keys do
    locs = YAML.load(File.read('./config/locales/en.yml'))
    locs['en']['services'].each_key do |service|
      locs['en'][service[0..-9].pluralize] = { 'service' => locs['en']['services'][service].dup }
    end

    File.open('./config/locales/en.yml', 'w') do |f|
      f.write YAML.dump(locs)
    end
  end
end
