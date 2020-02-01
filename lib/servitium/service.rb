# frozen_string_literal: true

module Servitium
  class Service
    include ActiveSupport::Callbacks
    attr_reader :context

    alias_method :ctx, :context

    define_callbacks :perform
    private_class_method :new
    attr_reader :raise_on_error

    def initialize(*args)
      @raise_on_error = false
      @context = context_class.new(*args)
      super()
    end

    private

    def call
      if self.class.transactional && defined? ActiveRecord::Base
        ActiveRecord::Base.transaction { exec }
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
      rescue Servitium::ContextFailure
        raise_if_needed
      end
      raise_if_needed
      context
    end

    def raise_on_error?
      @raise_on_error
    end

    def raise_if_needed
      return unless raise_on_error?

      errors = context.errors.full_messages.join(', ')
      log :error, "raising: #{errors}"
      raise StandardError, errors
    end

    def log(level, message)
      return unless defined? Rails.logger

      Rails.logger.send level, "#{self.class.name}: #{message}"
    end

    class << self
      def transactional(value = nil)
        @transactional = value unless value.nil?
        @transactional = false unless defined? @transactional
        @transactional
      end

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
    end
  end
end
