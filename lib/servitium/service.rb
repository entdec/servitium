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

    define_callbacks :commit
    define_callbacks :perform
    define_callbacks :failure
    define_callbacks :async_success
    define_callbacks :async_failure
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

        begin
          context.fail!(:base, e.message)
        rescue Servitium::ContextFailure => e
          # Eat this as well, we don't want to raise here, capture exceptions is true.
        end
      end
      raise_if_needed
      context
    end

    def raise_on_error?
      @raise_on_error
    end

    def raise_if_needed(e = nil)
      raise e if e.present? && e.context.object_id != context.object_id
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

    def after_commit
      run_callbacks :commit do
      end
    end

    def failure
      run_callbacks :failure do
      end
    end

    def async_success
      run_callbacks :async_success do
      end
    end

    def async_failure
      run_callbacks :async_failure do
      end
    end

    class << self
      # Main point of entry for services, will raise in case of errors
      def perform!(*args)
        inst = new(*args)

        begin
          inst.context.validate!(:in) if inst.context.class.inbound_scope_used
          inst.context.validate!
          inst.context.instance_variable_set(:@called, true)
          inst.send(:call!)
          inst.context.validate!(:out) if inst.context.errors.blank? && inst.context.class.inbound_scope_used
          inst.send(:after_commit) unless inst.context.failed?
        ensure
          inst.send(:failure) if inst.context.failed?
        end

        inst.context
      end

      # Main point of entry for services
      def perform(*args)
        call(*args).context
      end

      # Call the service returning the service instance
      def call(*args)
        inst = new(*args)

        valid_in = inst.context.valid?
        valid_in &&= inst.context.valid?(:in) if inst.context.class.inbound_scope_used

        if valid_in
          inst.context.instance_variable_set(:@called, true)
          inst.send(:call)
          inst.context.valid?(:out) if inst.context.errors.blank? && inst.context.class.inbound_scope_used
          inst.send(:after_commit) unless inst.context.failed?
        end

        inst.send(:failure) if inst.context.failed?

        inst
      end

      # Perform this service async
      def perform_later(*args)
        inst = new(*args)

        valid_in = inst.context.valid?
        valid_in &&= inst.context.valid?(:in) if inst.context.class.inbound_scope_used

        if valid_in
          inst.context.instance_variable_set(:@called, true)
          Servitium::ServiceJob.perform_later(name, inst.context.attributes_hash)
        end

        inst.context
      end

      def queue_name
        'default'
      end

      # Callbacks
      def after_commit(*filters, &block)
        set_callback(:commit, :after, *filters, &block)
      end

      def before_perform(*filters, &block)
        set_callback(:perform, :before, *filters, &block)
      end

      def around_perform(*filters, &block)
        set_callback(:perform, :around, *filters, &block)
      end

      def after_perform(*filters, &block)
        set_callback(:perform, :after, *filters, &block)
      end

      def after_failure(*filters, &block)
        set_callback(:failure, :after, *filters, &block)
      end

      def around_async_success(*filters, &block)
        set_callback(:async_success, :around, *filters, &block)
      end

      def around_async_failure(*filters, &block)
        set_callback(:async_failure, :around, *filters, &block)
      end

      def after_async_success(*filters, &block)
        set_callback(:async_success, :after, *filters, &block)
      end

      def after_async_failure(*filters, &block)
        set_callback(:async_failure, :after, *filters, &block)
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

        context_module.const_set(context_class_name_part, Class.new(context_base_class_name.constantize))
        context_class
      end

      # Get the base class for new contexts defined using context blocks
      # Defaults to Servitium::Context
      def context_base_class_name
        @@_context_base_class_name ||= 'Servitium::Context'
      end

      # Override the base class for contexts defined using context blocks, you can use this to
      # change the base class to your own ApplicationContext
      def context_base_class_name=(base_class)
        @@_context_base_class_name = base_class
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
