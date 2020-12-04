# frozen_string_literal: true

module Servitium
  class Context
    extend ActiveModel::Callbacks

    include Servitium::ContextModel

    define_model_callbacks :initialize

    attr_reader :errors

    define_callbacks :perform

    def initialize(*args)
      @success     = true
      @called      = false
      @errors      = ActiveModel::Errors.new(self)
      args = remap_args(args)
      @subcontexts = create_subcontexts(args.first)

      run_callbacks :initialize do
        super(*args)
      end
    end

    def success?
      @called && @success
    end

    def failure?
      !success?
    end

    alias fail? failure?
    alias failed? failure?

    def fail!(attr, message = :invalid, options = {})
      @success = false
      merge_errors!(attr, message, options)
      raise ContextFailure, self
    end

    private

    def merge_errors!(attr, message = :invalid, options = {})
      return unless attr

      if attr.is_a? String
        errors.add(:base, attr)
      elsif attr.is_a? ActiveModel::Errors
        errors.merge!(attr)
      elsif attr.is_a? Symbol
        errors.add(attr, message, options)
      end
    end

    class << self
      include Servitium::I18n

      def human_attribute_name(attribute, options = {})
        t(".#{attribute}", default: super)
      end
    end
  end
end
