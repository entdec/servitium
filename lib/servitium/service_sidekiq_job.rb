# frozen_string_literal: true

module Servitium
  class ServiceSidekiqJob
    include Sidekiq::Job
    def perform(class_name, *)
      service = class_name.constantize.call(*)

      if service.context.success?
        service.send(:async_success)
      else
        service.send(:async_failure)
      end
    end
  end
end
