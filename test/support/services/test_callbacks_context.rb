# frozen_string_literal: true

class TestCallbacksContext < Servitium::Context
  attribute :test1
  validates :test1, presence: true

  attribute :servitium
  attribute :result

  before_validation do
    self.result = 'bv'
  end

  after_validation do
    self.result += 'av'
  end
end
