# frozen_string_literal: true

# Rails 8 compatibility: ActiveModel::Dirty expects attribute values to respond to
# +changed_in_place?+. Value types (Integer, Float, Symbol, etc.) can't get
# singleton methods in Ruby, so we add the method at the class level here.
# Servitium/ActiveAttr context attributes use these types; without this, validations
# (e.g. NumericalityValidator) raise NoMethodError.

require "bigdecimal"
require "date"

[
  String, Integer, Float, BigDecimal,
  TrueClass, FalseClass, NilClass, Symbol,
  Date, Time, Array, Hash
].each do |klass|
  next if klass.method_defined?(:changed_in_place?)

  klass.define_method(:changed_in_place?) { false }
end
