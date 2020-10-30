# frozen_string_literal: true

module Servitium
  module I18n
    def t(key, passed_options = {})
      unless @service_scope
        parts = (self.is_a?(Class) ? self : self.class).to_s.underscore.gsub('/', '.').split('.')
        parts[-1] = "#{parts.last.gsub('_service', '').pluralize}.service" if parts.last.end_with?('_service')
        parts[-1] = "#{parts.last.gsub('_context', '').pluralize}.context" if parts.last.end_with?('_context')
        @service_scope = parts.compact.join('.')
      end

      options = { scope: @service_scope }
      options[:default] = ::I18n.t(key) unless key.start_with?('.')

      ::I18n.t(key, options.merge(passed_options))
    end
  end
end
