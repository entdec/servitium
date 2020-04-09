# frozen_string_literal: true

require 'test_helper'

class <%= name %>ServiceTest < ActiveSupport::TestCase
  test 'service context result is success' do
    context = <%=name%>Service.perform(some: 'some')
    assert context.success?
    assert_equal 'emos', context.some
  end
end
