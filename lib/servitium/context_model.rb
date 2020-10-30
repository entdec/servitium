# frozen_string_literal: true

module Servitium
  module ContextModel
    extend ActiveSupport::Concern
    included do
      include ActiveAttr::Model
      include Servitium::I18n

      delegate :input_attributes, :output_attributes, :other_attributes, to: :class

      validate :validate_subcontexts
      attr_accessor :supercontext

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

      def model_name
        @model_name ||= ActiveModel::Name.new(self.class, nil, self.class.name.gsub('Context', ''))
      end

      private

      def remap_args(args)
        return args if args.empty?

        args[0] = args.first.to_h.map do |key, value|
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

          [*value].each { |v| v.supercontext = self }
          subcontexts[key]    = value
          context_values[key] = value
        end

        subcontexts
      end

      class << self
        def input(&block)
          Servitium::ScopedAttributes.new(self, input_attributes, :in).call(block)
        end

        def output(&block)
          Servitium::ScopedAttributes.new(self, output_attributes, :out).call(block)
        end

        def input_attributes
          @input_attributes ||= []
        end

        def output_attributes
          @output_attributes ||= []
        end

        def other_attributes
          @other_attributes ||= attributes.keys - (input_attributes + output_attributes)
        end
      end
    end
  end
end
