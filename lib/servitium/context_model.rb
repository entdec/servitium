# frozen_string_literal: true

module Servitium
  module ContextModel
    extend ActiveSupport::Concern

    class_methods do
      include Servitium::SubContexts
    end

    included do
      include ActiveAttr::Model
      include Servitium::I18n

      delegate :input_attributes, :output_attributes, :other_attributes, to: :class

      validate :validate_subcontexts
      attr_accessor :supercontext

      def initialize(*args)
        @errors = ActiveModel::Errors.new(self)
        @subcontexts = {}
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

      def id
        SecureRandom.uuid
      end

      def _destroy; end

      private

      def validate_subcontexts
        @subcontexts.each do |key, value|
          errors.add(key, 'invalid') unless [*value].find_all { |v| v.respond_to?(:invalid?) && v.invalid? }.empty?
        end
      end

      class << self
        attr_reader :inbound_scope_used, :outbound_scope_used

        def input(&block)
          @inbound_scope_used = true
          Servitium::ScopedAttributes.new(self, input_attributes, :in).call(block)
        end

        def output(&block)
          @outbound_scope_used = true
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
