# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'servitium'

require 'minitest/autorun'
require 'pry'

require 'test_helpers/servitium_helpers'

# We don't want logs to be spewed out to STDOUT during tests
ActiveJob::Base.logger = Logger.new(nil)
