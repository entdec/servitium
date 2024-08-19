# frozen_string_literal: true

module Servitium
  class ContextFailure < Servitium::Error
    attr_reader :context

    def initialize(context)
      @context = context
      super(context.errors.full_messages.join(", "))
    end
  end
end
