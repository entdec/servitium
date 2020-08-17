# frozen_string_literal: true

module Servitium
  module ContextModel
    extend ActiveSupport::Concern

    included do
      include ActiveAttr::Model

      validate :validate_subcontexts

      def initialize(*args)
        @errors = ActiveModel::Errors.new(self)
        args = remap_args(args)
        @subcontexts = create_subcontexts(args.first)

        super(*args)
      end

      def inspect
        message = super
        message += " (success: #{success?}, valid: #{@errors.size.zero?}, errors: #{@errors.full_messages.join(', ')})"
        message
      end

      private

      def remap_args(args)
        return args if args.empty?

        args[0] = args.first.map do |key, value|
          if key.to_s.match?(/_attributes$/)
            try_key = key.to_s.sub(/_attributes$/, '')
            klass = "#{self.class.name}::#{try_key.camelize}".safe_constantize
            klass ||= "#{self.class.name}::#{try_key.singularize.camelize}".safe_constantize
            key = try_key.to_sym if klass
          end

          [key, value]
        end.to_h

        args
      end

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
