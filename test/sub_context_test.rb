# frozen_string_literal: true

require 'test_helper'

class ServitiumTest < ActiveSupport::TestCase
  def test_initializes_contexts_correctly
    context = TestContext.new
    assert context.my_subcontexts.is_a?(Array)
  end

  def test_sets_subcontexts
    context = TestService.perform(servitium: 'hello', my_subcontext: { name: 'Tom' },
                                  my_subcontexts: [{ name: 'Ivo' }, { name: 'Andre', withins: [{ colour: 'Orange' }, { colour: 'Cyan' }] }], other_hash: { name: 'Sander', withins: [{ colour: 'Blue' }, { colour: 'Green' }] })
    assert context.success?

    assert_instance_of TestContext::MySubcontext, context.my_subcontext
    assert_equal context, context.my_subcontext.supercontext
    assert_equal 'Tom', context.my_subcontext.name
    assert_equal [], context.my_subcontext.withins

    assert_equal 2, context.my_subcontexts.size

    subcontext = context.my_subcontexts.first
    assert_equal context, subcontext.supercontext
    assert_instance_of TestContext::MySubcontext, subcontext
    assert_equal 'Ivo', subcontext.name
    assert_equal [], subcontext.withins

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
    context = TestService.perform(servitium: 'hello', my_subcontext_attributes: { name: 'Tom' },
                                  my_subcontexts_attributes: [{ name: 'Ivo' }, { name: 'Andre', withins: [{ colour: 'Orange' }, { colour: 'Cyan' }] }], other_hash: { name: 'Sander', withins: [{ colour: 'Blue' }, { colour: 'Green' }] })
    assert context.success?

    assert_instance_of TestContext::MySubcontext, context.my_subcontext
    assert_equal context, context.my_subcontext.supercontext
    assert_equal 'Tom', context.my_subcontext.name
    assert_equal [], context.my_subcontext.withins

    assert_equal 2, context.my_subcontexts.size

    subcontext = context.my_subcontexts.first
    assert_equal context, subcontext.supercontext
    assert_instance_of TestContext::MySubcontext, subcontext
    assert_equal 'Ivo', subcontext.name
    assert_equal [], subcontext.withins

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

  def test_sets_subcontexts_attributes_nested_attributes
    context = TestService.perform(servitium: 'hello',
                                  my_subcontext_attributes: { name: 'Tom' },
                                  my_subcontexts_attributes: { '0' => { name: 'Ivo' },
                                                               '1' => { name: 'Andre',
                                                                        withins_attributes: [{ colour: 'Orange' },
                                                                                             { colour: 'Cyan' }] } },
                                  other_hash: { name: 'Sander', withins: [{ colour: 'Blue' }, { colour: 'Green' }] })
    assert context.success?

    assert_instance_of TestContext::MySubcontext, context.my_subcontext
    assert_equal context, context.my_subcontext.supercontext
    assert_equal 'Tom', context.my_subcontext.name
    assert_equal [], context.my_subcontext.withins

    assert_equal 2, context.my_subcontexts.size

    subcontext = context.my_subcontexts.first
    assert_equal context, subcontext.supercontext
    assert_instance_of TestContext::MySubcontext, subcontext
    assert_equal 'Ivo', subcontext.name
    assert_equal [], subcontext.withins

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

  def test_validation_validates_subcontexts
    context = TestValidationService.perform(my_subcontexts: [{ name: 'Tom' }, {},
                                                             { name: 'Andre', withins: [{ colour: 'Purple' }, { colour: 'Blue' }] }])
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
end
