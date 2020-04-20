# frozen_string_literal: true

module Servitium
  class Context
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    attr_reader :errors

    # alias_metod

    def initialize(*args)
      @success = true
      @called = false
      @errors = ActiveModel::Errors.new(self)

      create_subcontexts(args.first) if args.first.is_a?(Hash)

      super(*args)
    end

    def success?
      @called && @success
    end

    def failure?
      !success?
    end

    alias_method :fail?, :failure?
    alias_method :failed?, :failure?

    def fail!(attr, message = :invalid, options = {})
      @success = false
      merge_errors!(attr, message, options)
      raise ContextFailure, self
    end

    private

    def create_subcontexts(context_values)
      context_values.each do |key, value|
        klass = "#{self.class.name}::#{key.to_s.camelize}".safe_constantize
        klass ||= "#{self.class.name}::#{key.to_s.singularize.camelize}".safe_constantize

        if klass
          if value.is_a?(Array)
            value = value.map! { |v| klass.new(v) }
          else
            value = klass.new(value)
          end

          context_values[key] = value
        end
      end
    end

    def merge_errors!(attr, message = :invalid, options = {})
      return unless attr

      if attr.is_a? String
        self.errors.add(:base, attr)
      elsif attr.is_a? ActiveModel::Errors
        self.errors.merge!(attr)
      elsif attr.is_a? Symbol
        self.errors.add(attr, message, options)
      end
    end
  end
end
