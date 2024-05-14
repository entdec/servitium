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
end
