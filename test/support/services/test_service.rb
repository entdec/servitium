# frozen_string_literal: true

require_relative 'test_context'
require_relative 'test_context/my_subcontext'
require_relative 'test_context/my_subcontext/within'

class TestService < Servitium::Service
  def perform
    context.result = context.servitium.reverse
    context.fail!('Pizza time!') if ctx.result == 'azzip'
    context.fail!(:servitium, :invalid, message: 'Mouse!') if ctx.result == 'esuom'
  end
end
