# frozen_string_literal: true

module Servitium
  class ServiceSidekiqJob
    include Sidekiq::Job

    def perform(class_name, *args)
      Current.user = User.find(args[0]['current_user_id'])
      Current.location = Location.find(args[0]['current_location_id'])
      Current.account = Account.find(args[0]['current_account_id'])
      service = class_name.constantize.call(*args)

      if service.context.success?
        service.send(:async_success)
      else
        service.send(:async_failure)
      end
    end
  end
end
