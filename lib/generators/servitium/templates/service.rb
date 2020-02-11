# frozen_string_literal: true

class <%= name %>Service < ApplicationService
  def perform
    context.some.reverse!
  end
end
