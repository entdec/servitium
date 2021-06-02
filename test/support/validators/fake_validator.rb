# frozen_string_literal: true

class FakeValidator < ActiveModel::EachValidator
  class << self
    attr_writer :fake_validator_count
  end

  class << self
    attr_reader :fake_validator_count
  end

  def validate_each(_record, _attribute, _value)
    self.class.fake_validator_count ||= 0
    self.class.fake_validator_count += 1
  end
end
