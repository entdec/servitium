# frozen_string_literal: true

class TestValidationContext::MySubcontext::Within < TestContext::MySubcontext::Within
  validates :colour, inclusion: {in: %w[Blue Orange]}
end
