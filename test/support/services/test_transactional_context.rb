# frozen_string_literal: true

class TestTransactionalContext < Servitium::Context
  attribute :servitium
  attribute :result
  attribute :after_commit_hook
end
