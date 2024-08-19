# frozen_string_literal: true

require "rails"

module Servitium
  module Rails
    class Railtie < ::Rails::Railtie
      # config.eager_load_namespaces << Servitium
    end
  end
end
