# frozen_string_literal: true

class <%= name %>Context < ApplicationContext
  attribute :some, type: String, default: 'new'

  validates :some, presence: true

  before_validation do
  end

  after_validation do
  end
end
