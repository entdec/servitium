# frozen_string_literal: true

require_relative 'test_validation_context'
require_relative 'test_validation_context/my_subcontext'
require_relative 'test_validation_context/my_subcontext/within'

class TestValidationService < Servitium::Service
  def perform
    context.result = context.servitium.reverse
  end
end
