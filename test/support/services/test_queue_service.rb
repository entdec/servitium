# frozen_string_literal: true

class TestQueueService < Servitium::Service
  context do
    attribute :servitium
  end

  def perform
    context.result = context.servitium.reverse
  end

  def self.queue_name
    'test_queue'
  end
end
