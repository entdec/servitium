# frozen_string_literal: true

module Servitium
  module TransactionalMixin
    class << self
      def included(base)
        base.extend ClassMethods
      end
    end

    module ClassMethods
      def transactional(value = nil)
        @transactional = value if value
        @transactional = nil unless defined?(@transactional)
        if @transactional.nil?
          @transactional = if superclass < Servitium::Service
                             superclass.transactional
                           else
                             false
                           end
        end
        @transactional
      end
    end
  end

  class Service
    include ActiveSupport::Callbacks
    include TransactionalMixin
    attr_reader :context

    alias ctx context

    define_callbacks :perform
    private_class_method :new
    attr_reader :raise_on_error

    delegate :transactional, to: :class

    def initialize(*args)
      @raise_on_error = false
      @context = context_class.new(*args)
      super()
    end

    private

    def call
      if transactional && defined?(ActiveRecord::Base)
        ActiveRecord::Base.transaction do
          context = exec
          raise ActiveRecord::Rollback if context.failed?
        end

        context
      else
        exec
      end
    end

    def call!
      @raise_on_error = true
      call
    end

    def context_class
      self.class.name.gsub('Service', 'Context').safe_constantize || Servitium::Context
    end

    def exec
      run_callbacks :perform do
        perform
      rescue Servitium::ContextFailure => e
        raise_if_needed(e)
      end
      raise_if_needed
      context
    end

    def raise_on_error?
      @raise_on_error
    end

    def raise_if_needed(e = nil)
      return unless raise_on_error?

      if e
        raise e
      elsif context.errors.present?
        errors = context.errors.full_messages.join(', ')
        log :error, "raising: #{errors}"
        raise StandardError, errors
      end
    end

    def log(level, message)
      return unless defined? Rails.logger

      Rails.logger.send level, "#{self.class.name}: #{message}"
    end

    class << self
      # Main point of entry for services, will raise in case of errors
      def perform!(*args)
        inst = new(*args)
        inst.context.validate!
        inst.context.instance_variable_set(:@called, true)
        inst.send(:call!)
        inst.context
      end

      # Main point of entry for services
      def perform(*args)
        inst = new(*args)
        if inst.context.valid?
          inst.send(:call)
          inst.context.instance_variable_set(:@called, true)
        end
        inst.context
      end

      # Callbacks
      def before_perform(*filters, &block)
        set_callback(:perform, :before, *filters, &block)
      end

      def around_perform(*filters, &block)
        set_callback(:perform, :around, *filters, &block)
      end

      def after_perform(*filters, &block)
        set_callback(:perform, :after, *filters, &block)
      end
    end
  end
end
