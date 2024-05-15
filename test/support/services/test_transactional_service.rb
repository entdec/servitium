# frozen_string_literal: true

require_relative "test_service"
require_relative "test_transactional_context"

class TestTransactionalService < Servitium::Service
  transactional true

  after_commit :another_hook
  after_commit do
    context.after_commit_hook = "executed"
  end

  def perform
    context.result = Message.create(text: context.servitium)
    TestService.perform!(servitium: "pizza") if context.servitium == "pizza"
    if context.servitium == "hello"
      test_service_context = TestService.perform(servitium: "pizza")
      context.fail!(:base, "Oh noes") if test_service_context.failed?
    end
    raise "Kaboom" if context.servitium == "bomb"
  end

  def another_hook
    context.after_commit_hook += " it"
  end
end
