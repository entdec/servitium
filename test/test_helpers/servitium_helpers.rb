# frozen_string_literal: true

class TestContext < Servitium::Context
  attribute :servitium
  attribute :result
  attribute :other_hash

  sub_context :my_subcontext
  sub_context :my_subcontexts
end

class TransactionalTestContext < TestContext
end

class TestContext::MySubcontext
  include Servitium::ContextModel

  attribute :name

  sub_context :withins
end

class TestContext::MySubcontext::Within
  include Servitium::ContextModel

  attribute :colour
end

class TestService < Servitium::Service
  def perform
    context.result = context.servitium.reverse
    context.fail!('Pizza time!') if ctx.result == 'azzip'
    context.fail!(:servitium, :invalid, message: 'Mouse!') if ctx.result == 'esuom'
  end
end

class TransactionalTestService < TestService
  transactional true

  def perform
    context.result = Message.create(text: context.servitium)
    raise 'Kaboom' if context.servitium == 'bomb'
  end
end

class TestValidationContext < Servitium::Context
  attribute :servitium, default: ''
  attribute :result
  sub_context :my_subcontexts

  validates :servitium, absence: true
end

class TestValidationContext::MySubcontext < TestContext::MySubcontext
  validates :name, presence: true
end

class TestValidationContext::MySubcontext::Within < TestContext::MySubcontext::Within
  validates :colour, inclusion: { in: %w[Blue Orange] }
end

class TestValidationService < Servitium::Service
  def perform
    context.result = context.servitium.reverse
  end
end

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

class TestCallbacksService < Servitium::Service
  before_perform do
    context.result += 'bp'
  end

  after_perform do
    context.result += 'ap'
  end

  around_perform :op

  def perform; end

  private

  def op
    context.result += 'op'
    yield
    context.result += 'op'
  end
end

class TestInlineContextService < Servitium::Service
  context do
    attribute :test1
    attribute :test2

    input do
      attribute :in
      validates :in, presence: true
    end

    output do
      attribute :out
      validates :out, presence: true
    end

    after_initialize :init_vars

    def init_vars
      self.test2 ||= test1 * 2
    end
  end
end

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

class TestInlineSimpleContextService < Servitium::Service
  context do
    attribute :test1

    validates :test1, fake: true
  end

  def perform; end
end
