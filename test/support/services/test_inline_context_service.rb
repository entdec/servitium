# frozen_string_literal: true

class TestInlineContextService < Servitium::Service
  context do
    attribute :test1
    attribute :test2

    input do
      attribute :in
      validates :in, presence: true
    end

    output do
      attribute :out
      validates :out, presence: true
    end

    after_initialize :init_vars

    def init_vars
      self.test2 ||= test1 * 2
    end
  end
end
