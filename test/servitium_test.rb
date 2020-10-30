# frozen_string_literal: true

require 'test_helper'

class TestContext < Servitium::Context
  attribute :servitium
  attribute :result
  attribute :my_subcontext
  attribute :my_subcontexts
  attribute :other_hash
end

class TestContext::MySubcontext
  include Servitium::ContextModel

  attribute :name
  attribute :withins
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

class TestValidationContext < Servitium::Context
  attribute :servitium, default: ''
  attribute :result
  attribute :my_subcontexts

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

  def perform
  end

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

class ServitiumTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Servitium::VERSION
  end

  def test_inline_context_init
    assert_equal TestInlineContextContext, TestInlineContextService.context_class
    ctx = TestInlineContextService.context(test1: 1)
    assert_equal 1, ctx.test1
    assert_equal 2, ctx.test2
  end

  def test_context_input_validation
    ctx = TestInlineContextService.context(test1: 1)
    assert_equal true, ctx.valid?

    ctx = TestInlineContextService.context(test1: 1)
    assert_equal false, ctx.valid?(:in)

    ctx = TestInlineContextService.context(test1: 1, in: 1)
    assert_equal true, ctx.valid?, ctx.errors.full_messages

    ctx = TestInlineContextService.context(test1: 1, in: 1)
    assert_equal false, ctx.valid?(:out)

    ctx = TestInlineContextService.context(test1: 1, out: 1)
    assert_equal true, ctx.valid?(:out), ctx.errors.full_messages
  end

  def test_sets_context
    context = TestService.perform(servitium: 'hello')
    assert context.success?

    assert_equal 'olleh', context.result
  end

  def test_sets_subcontexts
    context = TestService.perform(servitium: 'hello', my_subcontext: { name: 'Tom' }, my_subcontexts: [ { name: 'Ivo' }, { name: 'Andre', withins: [ { colour: 'Orange' }, { colour: 'Cyan' } ] } ], other_hash: { name: 'Sander', withins: [ { colour: 'Blue' }, { colour: 'Green' } ] })
    assert context.success?

    assert_instance_of TestContext::MySubcontext, context.my_subcontext
    assert_equal context, context.my_subcontext.supercontext
    assert_equal 'Tom', context.my_subcontext.name
    assert_nil context.my_subcontext.withins

    assert_equal 2, context.my_subcontexts.size

    subcontext = context.my_subcontexts.first
    assert_equal context, subcontext.supercontext
    assert_instance_of TestContext::MySubcontext, subcontext
    assert_equal 'Ivo', subcontext.name
    assert_nil subcontext.withins

    subcontext = context.my_subcontexts.last
    assert_equal context, subcontext.supercontext
    assert_instance_of TestContext::MySubcontext, subcontext
    assert_equal 'Andre', subcontext.name
    assert_equal 2, subcontext.withins.size

    within = subcontext.withins.first
    assert_equal subcontext, within.supercontext
    assert_instance_of TestContext::MySubcontext::Within, within
    assert_equal 'Orange', within.colour
    within = subcontext.withins.last
    assert_equal subcontext, within.supercontext
    assert_instance_of TestContext::MySubcontext::Within, within
    assert_equal 'Cyan', within.colour

    assert_instance_of Hash, context.other_hash
  end

  def test_sets_subcontexts_attributes
    context = TestService.perform(servitium: 'hello', my_subcontext_attributes: { name: 'Tom' }, my_subcontexts_attributes: [ { name: 'Ivo' }, { name: 'Andre', withins: [ { colour: 'Orange' }, { colour: 'Cyan' } ] } ], other_hash: { name: 'Sander', withins: [ { colour: 'Blue' }, { colour: 'Green' } ] })
    assert context.success?

    assert_instance_of TestContext::MySubcontext, context.my_subcontext
    assert_equal context, context.my_subcontext.supercontext
    assert_equal 'Tom', context.my_subcontext.name
    assert_nil context.my_subcontext.withins

    assert_equal 2, context.my_subcontexts.size

    subcontext = context.my_subcontexts.first
    assert_equal context, subcontext.supercontext
    assert_instance_of TestContext::MySubcontext, subcontext
    assert_equal 'Ivo', subcontext.name
    assert_nil subcontext.withins

    subcontext = context.my_subcontexts.last
    assert_equal context, subcontext.supercontext
    assert_instance_of TestContext::MySubcontext, subcontext
    assert_equal 'Andre', subcontext.name
    assert_equal 2, subcontext.withins.size

    within = subcontext.withins.first
    assert_equal subcontext, within.supercontext
    assert_instance_of TestContext::MySubcontext::Within, within
    assert_equal 'Orange', within.colour
    within = subcontext.withins.last
    assert_equal subcontext, within.supercontext
    assert_instance_of TestContext::MySubcontext::Within, within
    assert_equal 'Cyan', within.colour

    assert_instance_of Hash, context.other_hash
  end

  def test_sets_error_when_failing_context
    context = TestService.perform(servitium: 'pizza')

    assert context.failure?
    assert_equal ['Pizza time!'], context.errors.messages[:base]
    assert_equal 'azzip', context.result
  end

  def test_sets_error_when_failing_context_with_attr
    context = TestService.perform(servitium: 'mouse')

    assert context.failure?
    assert_equal ['Mouse!'], context.errors.messages[:servitium]
    assert_equal 'esuom', context.result
  end

  def test_sets_errors_when_failing_context_should_raise
    assert_raises StandardError do
      TestService.perform!(servitium: 'pizza')
    end
  end

  def test_validation_fails_causes_failure
    context = TestValidationService.perform(servitium: 'mouse')
    assert context.failure?
  end

  def test_validation_validates_subcontexts
    context = TestValidationService.perform(my_subcontexts: [ { name: 'Tom' }, {}, { name: 'Andre', withins: [ { colour: 'Purple' }, { colour: 'Blue' } ] } ])
    assert context.failure?

    refute context.valid?
    assert_equal ['invalid'], context.errors[:my_subcontexts]

    subcontext = context.my_subcontexts.first
    assert_empty subcontext.errors

    subcontext = context.my_subcontexts[1]
    assert_equal ['can\'t be blank'], subcontext.errors[:name]
    assert_empty subcontext.errors[:withins]

    subcontext = context.my_subcontexts.last
    assert_empty subcontext.errors[:name]
    assert_equal ['invalid'], subcontext.errors[:withins]

    within = subcontext.withins.first
    assert_equal ['is not included in the list'], within.errors[:colour]

    within = subcontext.withins.last
    assert_empty within.errors
  end

  def test_validation_fails_causes_exception
    assert_raises ActiveModel::ValidationError do
      TestValidationService.perform!(servitium: 'mouse')
    end
  end

  def test_callbacks
    # Less interesting test now, validations are run twice so that breaks this test.
    context = TestCallbacksService.perform!(test1: true)
    assert_equal 'bvav', context.result
  end
end
