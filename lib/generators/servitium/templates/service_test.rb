# frozen_string_literal: true

require 'test_helper'

class <%= name %>ServiceTest < ActiveSupport::TestCase
  test 'service context result is success' do
    context = <%name%>.perform()
    assert context.success?
  end
end
