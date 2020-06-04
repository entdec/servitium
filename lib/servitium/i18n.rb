# frozen_string_literal: true

module Servitium
  module I18n
    def t(key, options = {})
      options = { scope: "services.#{self.class.to_s.underscore.gsub('/', '.')}", default: ::I18n.t(key) }.merge(options)
      ::I18n.t(key, options)
    end
  end
end
