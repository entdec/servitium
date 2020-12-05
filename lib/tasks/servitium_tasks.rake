# frozen_string_literal: true

require 'yaml'
require 'active_support/inflector'

namespace :servitium do
  desc 'Release a new version'
  task :release do |_task, _args|
    gemspec = Dir.glob(File.expand_path(File.join(__dir__, '../../')) + '/*.gemspec').first
    version_file = Dir.glob(File.expand_path(File.join(__dir__, '../../')) + '/**/version.rb').first
    spec = Gem::Specification.load(gemspec)

    versions = spec.version.to_s.split('.').map(&:to_i)

    what = %w[ma mi pa].index(ARGV[1].to_s[0, 2])
    what ||= 2

    new_version = versions.tap { |parts| parts[what] += 1 }
    new_version = new_version.map.with_index { |v, i| i > what ? 0 : v }.join('.')

    version_file_content = File.read(version_file)
    File.open(version_file, 'w') do |file|
      file.puts version_file_content.gsub(/VERSION\s=\s'(.*)'/, "VERSION = '#{new_version}'")
    end

    puts "Updated version to #{new_version}"

    relative_version_path = Pathname.new(version_file).relative_path_from(Dir.pwd)

    `git commit #{relative_version_path} -m "Version #{new_version}"`
    `git push`
    `git tag #{new_version}`
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
