# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'servitium'

require 'active_record'
require 'minitest/autorun'
require 'pry'
require 'test_helpers/servitium_helpers'

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

class Message < ActiveRecord::Base
end
