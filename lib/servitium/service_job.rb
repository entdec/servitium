# frozen_string_literal: true

module Servitium
  class ServiceJob < ActiveJob::Base
    def perform(class_name, *args)
      class_name.constantize.perform!(*args)
    end
  end
end
