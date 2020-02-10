# frozen_string_literal: true

class <%= name %>Context < ApplicationContext
  attribute :some, type: :string, default: 'new'

  validates :some, presence: true

  before_validation do
  end

  after_validation do
  end

  before_perform do
  end

  after_perform do
  end
end
