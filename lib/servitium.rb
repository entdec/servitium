# frozen_string_literal: true

require 'active_model'
require 'active_attr'
require 'active_support'

require 'servitium/i18n'
require 'servitium/context_model'
require 'servitium/context'
require 'servitium/service'
require 'servitium/version'

module Servitium
  class Error < StandardError; end
  class ContextFailure < Servitium::Error; end
end

require 'servitium/rails' if defined?(::Rails)
