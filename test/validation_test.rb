# frozen_string_literal: true

require 'test_helper'

class ValidationTest < ActiveSupport::TestCase
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

  def test_validation_fails_causes_failure
    context = TestValidationService.perform(servitium: 'mouse')
    assert context.failure?
  end

  def test_validation_fails_causes_exception
    assert_raises ActiveModel::ValidationError do
      TestValidationService.perform!(servitium: 'mouse')
    end
  end

  def test_validation_should_only_be_called_once
    FakeValidator.fake_validator_count = 0
    TestInlineSimpleContextService.perform!(test1: 'blah')
    assert_equal 1, FakeValidator.fake_validator_count
  end
end
