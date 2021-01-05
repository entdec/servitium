# frozen_string_literal: true

module Servitium
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
end
