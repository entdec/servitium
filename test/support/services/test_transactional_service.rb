# frozen_string_literal: true

require_relative 'test_service'
require_relative 'test_transactional_context'

class TestTransactionalService < Servitium::Service
  transactional true

  def perform
    context.result = Message.create(text: context.servitium)
    TestService.perform!(servitium: 'pizza') if context.servitium == 'pizza'
    raise 'Kaboom' if context.servitium == 'bomb'
  end
end
