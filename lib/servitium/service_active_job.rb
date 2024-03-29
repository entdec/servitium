# frozen_string_literal: true

module Servitium
  class ServiceActiveJob < ActiveJob::Base
    def perform(class_name, *args)
      service = class_name.constantize.call(*args)

      if service.context.success?
        service.send(:async_success)
      else
        service.send(:async_failure)
      end
    end
  end
end
