# frozen_string_literal: true

module Servitium
  module ContextModel
    extend ActiveSupport::Concern

    included do
      include ActiveAttr::Model

      validate :validate_subcontexts

      def initialize(*args)
        @errors      = ActiveModel::Errors.new(self)
        @subcontexts = create_subcontexts(args.first)

        super(*args)
      end

      private

      def validate_subcontexts
        @subcontexts.each do |key, value|
          errors.add(key, 'invalid') unless [*value].find_all { |v| v.respond_to?(:invalid?) && v.invalid? }.empty?
        end
      end

      def create_subcontexts(context_values)
        subcontexts = {}
        return subcontexts unless context_values.is_a?(Hash)

        context_values.each do |key, value|
          klass = "#{self.class.name}::#{key.to_s.camelize}".safe_constantize
          klass ||= "#{self.class.name}::#{key.to_s.singularize.camelize}".safe_constantize

          next unless klass

          value = if value.is_a?(Array)
                    value.map! { |v| klass.new(v) }
                  else
                    klass.new(value)
                  end

          subcontexts[key]    = value
          context_values[key] = value
        end

        subcontexts
      end
    end
  end
end
