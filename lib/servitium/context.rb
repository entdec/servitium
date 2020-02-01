# frozen_string_literal: true

module Servitium
  class Context
    include ActiveSupport::Callbacks
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attr_reader :errors

    def initialize(*args)
      @success = true
      @errors = ActiveModel::Errors.new(self)
      super(*args)
    end

    def success?
      @success
    end

    def failure?
      !success?
    end

    alias fail? failure?

    def fail!(errors)
      @success = false
      merge_errors!(errors)
      raise ContextFailure, self
    end

    private

    def merge_errors!(errors)
      return unless errors

      if errors.is_a? String
        self.errors.add(:context, errors)
      else
        self.errors.merge!(errors)
      end
    end
  end
end
