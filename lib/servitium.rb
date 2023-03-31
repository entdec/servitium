# frozen_string_literal: true

require 'active_model'
require 'active_attr'
require 'active_support'
require 'action_controller'
require 'active_job'

require 'servitium/error'
require 'servitium/context_failure'
require 'servitium/i18n'
require 'servitium/sub_contexts'
require 'servitium/scoped_attributes'
require 'servitium/context_model'
require 'servitium/context'
require 'servitium/service_active_job'
require 'servitium/service_sidekiq_job'
require 'servitium/service'
require 'servitium/version'
require 'servitium/configuration'

require 'servitium/rails' if defined?(::Rails)


module Servitium
  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end
  end
end