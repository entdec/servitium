# frozen_string_literal: true

module Servitium
  module ContextModel
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
    end
  end
end

