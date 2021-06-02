# frozen_string_literal: true

class TestValidationContext::MySubcontext < TestContext::MySubcontext
  validates :name, presence: true
end
