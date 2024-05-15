# frozen_string_literal: true

require "rails/generators"

module Servitium
  class ServiceGenerator < ::Rails::Generators::NamedBase
    desc "Generates a service and context"

    source_root File.expand_path("templates", __dir__)

    def copy_initializer_file
      template "service.rb", "app/services/#{file_name}_service.rb"
      template "context.rb", "app/services/#{file_name}_context.rb"
      template "service_test.rb", "test/services/#{file_name}_service_test.rb"
    end
  end
end
