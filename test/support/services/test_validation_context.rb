# frozen_string_literal: true

class TestValidationContext < Servitium::Context
  attribute :servitium, default: ''
  attribute :result
  sub_context :my_subcontexts

  validates :servitium, absence: true
end

