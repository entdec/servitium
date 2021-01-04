# frozen_string_literal: true

require 'active_model'
require 'active_attr'
require 'active_support'
require 'active_job'

require 'servitium/i18n'
require 'servitium/sub_contexts'
require 'servitium/scoped_attributes'
require 'servitium/context_model'
require 'servitium/context'
require 'servitium/service_job'
require 'servitium/service'
require 'servitium/version'

module Servitium
  class Error < StandardError; end
  class ContextFailure < Servitium::Error; end
end

require 'servitium/rails' if defined?(::Rails)
