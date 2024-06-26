# frozen_string_literal: true

module Servitium
  class ScopedAttributes
    attr_reader :context, :store, :validation_context

    def initialize(context, store, validation_context = nil)
      @context = context
      @store = store
      @validation_context = validation_context
    end

    def attribute(name, *)
      store << name.to_s
      context.send(:attribute, name, *)
    end

    def validates(name, options = {})
      options[:on] ||= validation_context if validation_context
      context.send(:validates, name, options)
    end

    def validate(name, options = {}, &)
      options[:on] ||= validation_context if validation_context
      context.send(:validate, name, options, &)
    end

    def call(block)
      instance_exec(&block)
    end
  end
end
