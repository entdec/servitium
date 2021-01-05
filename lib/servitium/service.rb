# frozen_string_literal: true

require_relative 'transactional_mixin'
require_relative 'capture_exceptions_mixin'

module Servitium
  class Service
    include ActiveSupport::Callbacks
    include TransactionalMixin
    include CaptureExceptionsMixin
    include I18n

    attr_reader :context, :raise_on_error

    alias ctx context

    define_callbacks :perform
    private_class_method :new

    delegate :transactional, to: :class
    delegate :capture_exceptions, to: :class
    delegate :model_name, to: :context

    def initialize(*args)
      @raise_on_error = false
      @command = args.first.is_a?(Symbol) ? args.shift : :perform
      @context = context_class.new(*args)
      super()
    end

    private

    def call
      if transactional && defined?(ActiveRecord::Base)
        ActiveRecord::Base.transaction(requires_new: true) do
          exec
          # This will only rollback the changes of the service, SILENTLY, however the context will be failed? already.
          # This is the most close to expected behaviour this can get.
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
      rescue StandardError => e
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
        inst.context.validate!(:in) if inst.context.class.inbound_scope_used
        inst.context.validate!
        inst.context.instance_variable_set(:@called, true)
        inst.send(:call!)
        inst.context.validate!(:out) if inst.context.errors.blank? && inst.context.class.inbound_scope_used
        inst.context
      end

      # Main point of entry for services
      def perform(*args)
        inst = new(*args)

        valid_in = inst.context.valid?
        valid_in &&= inst.context.valid?(:in) if inst.context.class.inbound_scope_used

        if valid_in
          inst.context.instance_variable_set(:@called, true)
          inst.send(:call)
          inst.context.valid?(:out) if inst.context.errors.blank? && inst.context.class.inbound_scope_used
        end
        inst.context
      end

      # Perform this service async
      def perform_later(*args)
        inst = new(*args)

        valid_in = inst.context.valid?
        valid_in &&= inst.context.valid?(:in) if inst.context.class.inbound_scope_used

        if valid_in
          inst.context.instance_variable_set(:@called, true)
          Servitium::ServiceJob.perform_later(name, *[inst.context.attributes_hash])
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

      def context(*args, &block)
        return initialized_context(*args) unless block_given?

        begin
          context_class!.new
        rescue StandardError
          nil
        end
        context_class!.class_eval(&block)
      end

      def initialized_context(*args)
        context_class.new(*args)
      end
    end
  end
end
