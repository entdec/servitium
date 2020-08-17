# frozen_string_literal: true

module Servitium
  class Context
    extend ActiveModel::Callbacks

    include Servitium::I18n
    include Servitium::ContextModel

    define_model_callbacks :initialize

    attr_reader :errors
    define_callbacks :perform
    # alias_metod

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

    alias_method :fail?, :failure?
    alias_method :failed?, :failure?

    def fail!(attr, message = :invalid, options = {})
      @success = false
      merge_errors!(attr, message, options)
      raise ContextFailure, self
    end

    private

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
