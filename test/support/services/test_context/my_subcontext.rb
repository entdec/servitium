# frozen_string_literal: true

class TestContext::MySubcontext
  include Servitium::ContextModel

  attribute :name

  sub_context :withins
end
