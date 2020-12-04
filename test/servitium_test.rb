# frozen_string_literal: true

require 'test_helper'

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

  def test_callbacks
    # Less interesting test now, validations are run twice so that breaks this test.
    context = TestCallbacksService.perform!(test1: true)
    assert_equal 'bvav', context.result
  end
end
