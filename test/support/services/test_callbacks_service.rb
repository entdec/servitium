# frozen_string_literal: true

require_relative "test_callbacks_context"

class TestCallbacksService < Servitium::Service
  before_perform do
    context.result += "bp"
  end

  after_perform do
    context.result += "ap"
  end

  around_perform :op

  def perform
  end

  private

  def op
    context.result += "op"
    yield
    context.result += "op"
  end
end
