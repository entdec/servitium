# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'servitium'

require 'active_record'
require 'minitest/autorun'
require 'pry'
require 'support/validators/fake_validator'
require 'support/models/message'
require 'support/services/test_callbacks_service'
require 'support/services/test_inline_context_service'
require 'support/services/test_inline_simple_context_service'
require 'support/services/test_service'
require 'support/services/test_validation_service'
require 'support/services/test_transactional_service'

# We don't want logs to be spewed out to STDOUT during tests
ActiveJob::Base.logger = Logger.new(nil)

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
ActiveRecord::Schema.define do
  self.verbose = false

  create_table :messages do |t|
    t.string :text
    t.timestamps
  end
end

