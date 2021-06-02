# frozen_string_literal: true

class TestContext < Servitium::Context
  attribute :servitium
  attribute :result
  attribute :other_hash

  sub_context :my_subcontext
  sub_context :my_subcontexts
end
