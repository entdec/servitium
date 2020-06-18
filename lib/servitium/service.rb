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

  module CaptureExceptionsMixin
    class << self
      def included(base)
        base.extend ClassMethods
      end
    end

    module ClassMethods
      def capture_exceptions(value = nil)
        @capture_exceptions = value if value
        @capture_exceptions = nil unless defined?(@capture_exceptions)
        if @capture_exceptions.nil?
          @capture_exceptions = if superclass < Servitium::Service
                             superclass.capture_exceptions
                           else
                             false
                           end
        end
        @capture_exceptions
      end
    end
  end

  class Service
    include ActiveSupport::Callbacks
    include TransactionalMixin
    include CaptureExceptionsMixin
    include Servitium::I18n

    attr_reader :context

    alias ctx context

    define_callbacks :perform
    private_class_method :new
    attr_reader :raise_on_error

    delegate :transactional, to: :class
    delegate :capture_exceptions, to: :class

    def initialize(*args)
      @raise_on_error = false
      @context = context_class.new(*args)
      @command = args.first.is_a?(Symbol) ? args.shift : :perform
      super()
    end

    private

    def call
      if transactional && defined?(ActiveRecord::Base)
        ActiveRecord::Base.transaction do
          exec
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
      self.class.context_class || Servitium::Context
    end

    def exec
      run_callbacks :perform do
        send(@command)
      rescue Servitium::ContextFailure => e
        raise_if_needed(e)
      rescue => e
        # If capture exceptions is true, eat the exception and set the context errors.
        raise unless capture_exceptions
        context.errors.add(:base, e.message)
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
          inst.context.instance_variable_set(:@called, true)
          inst.send(:call)
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

      def context_class
        context_class_name.safe_constantize
      end

      def context_class_name
        name.gsub('Service', 'Context')
      end

      def context_class!
        return context_class if context_class

        context_class_parts = context_class_name.split('::')
        context_class_name_part = context_class_parts.pop
        context_module_name = context_class_parts.join('::')
        context_module = context_module_name.present? ? context_module_name.constantize : Object

        context_module.const_set(context_class_name_part, Class.new(Servitium::Context))
        context_class
      end

      def context(&block)
        context_class!.instance_eval(&block)
      end
    end
  end
end
