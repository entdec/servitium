# frozen_string_literal: true

require 'test_helper'

class TestContext < Servitium::Context
  attribute :servitium
  attribute :result
end

class TestService < Servitium::Service
  def perform
    context.result = context.servitium.reverse

    context.fail!('Pizza time!') if ctx.result == 'azzip'

    context.fail!(:servitium, :invalid, message: 'Mouse!') if ctx.result == 'esuom'
  end
end

class TestValidationContext < Servitium::Context
  attribute :servitium
  attribute :result

  validates :servitium, absence: true
end

class TestValidationService < Servitium::Service
  def perform
    context.result = context.servitium.reverse
  end
end

class TestCallbacksContext < Servitium::Context
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


class ServitiumTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Servitium::VERSION
  end

  def test_sets_context
    context = TestService.perform(servitium: 'hello')
    assert context.success?

    assert_equal 'olleh', context.result
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

  def test_validation_fails_causes_exception
    assert_raises ActiveModel::ValidationError do
      TestValidationService.perform!(servitium: 'mouse')
    end
  end

  def test_callbacks
    context = TestCallbacksService.perform!
    assert_equal 'bvavbpopopap', context.result
  end
end
