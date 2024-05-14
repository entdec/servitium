# frozen_string_literal: true

class TestInlineSimpleContextService < Servitium::Service
  context do
    attribute :test1

    validates :test1, fake: true
  end

  def perform
  end
end
