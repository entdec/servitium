# frozen_string_literal: true

require "yaml"
require "active_support/inflector"

namespace :servitium do
  desc "Convert localization keys"
  task :convert_keys do
    locs = YAML.load_file("./config/locales/en.yml")
    locs["en"]["services"].each_key do |service|
      locs["en"][service[0..-9].pluralize] = {"service" => locs["en"]["services"][service].dup}
    end

    File.write("./config/locales/en.yml", YAML.dump(locs))
  end
end
