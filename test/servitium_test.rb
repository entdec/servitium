# frozen_string_literal: true

require 'test_helper'

class ServitiumTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    Message.destroy_all
  end

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

  def test_saving_data_in_a_transaction
    context = TransactionalTestService.perform(servitium: 'hello')
    assert context.success?
    assert_instance_of Message, context.result
    assert_equal 'hello', context.result.text

    assert_equal 1, Message.count
  end

  def test_an_exception_ensures_a_rollback
    begin
      TransactionalTestService.perform(servitium: 'bomb')
    rescue StandardError => e
      assert_equal 'Kaboom', e.message
    end

    assert_equal 0, Message.count
  end

  def test_perform_later_enqueues_a_job
    assert_enqueued_jobs 1, only: Servitium::ServiceJob do
      context = TestService.perform_later(servitium: 'pancakes')
      assert context.success?

      assert_enqueued_with(job: Servitium::ServiceJob,
                           args: ['TestService',
                                  { 'servitium' => 'pancakes', 'result' => nil, 'other_hash' => nil,
                                    'my_subcontext' => nil, 'my_subcontexts' => [] }])
    end
  end

  def test_perform_later_does_not_enqueue_for_invalid_context
    assert_enqueued_jobs 0 do
      context = TestValidationService.perform(servitium: 'mouse')
      assert context.failure?
    end
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
    context = TestCallbacksService.perform!(test1: true)
    assert_equal 'bvavbpopopap', context.result
  end
end
