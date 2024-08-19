# frozen_string_literal: true

class TestInlineContextService < Servitium::Service
  context do
    attribute :test1
    attribute :test2

    input do
      attribute :in_attr
      validates :in_attr, presence: true
    end

    output do
      attribute :out_attr
      validates :out_attr, presence: true
    end

    after_initialize :init_vars

    def init_vars
      self.test2 ||= test1 * 2
    end
  end
end
