require 'redis'

module Servitium
  DATA_STORE_KEY = 'servitium_datastore'.freeze
  SECONDS_IN_DAY = 86_400
  MUTEX = Thread::Mutex.new
  module JobMetrics
    def initialize(*args)
      self.class.prepend(Servitium::JobClassMethods)
      super(*args)
    end

    def self.included(base)
      if base.ancestors.include?(ActiveJob::Base)
        base.include(ActiveJobClassMethods)
      elsif base.respond_to?(:sidekiq_options)
        base.class_eval do
          sidekiq_options client_class: SidekiqClient
        end
      end
    end

    ##
    # Wrapper that enables us to track ActiveJob jobs and pass the datastore to the job.
    module ActiveJobClassMethods
      def serialize
        result = super
        datastore = Servitium.datastore || HashWithIndifferentAccess.new
        result['arguments'].prepend(datastore.as_json)
        result
      end

      def deserialize(job_data)
        Servitium.datastore = job_data['arguments'].shift
        super(job_data)
      end

      def enqueue(*args)
        Servitium::Batch.add_member("job_#{job_id}")
        super(*args)
      end
    end

    ##
    # Wrapper that enables us to track Sidekiq jobs and pass the datastore to the job.
    class SidekiqClient < Sidekiq::Client
      def raw_push(payloads)
        payloads.each do |payload|
          Servitium::Batch.add_member("job_#{payload['jid']}")
          datastore = Servitium.datastore || HashWithIndifferentAccess.new
          if payload.key?('args')
            payload['args'].prepend(datastore.as_json)
          elsif payload.key?('arguments')
            payload['arguments'].prepend(datastore.as_json)
          end
        end

        super(payloads)
      end
    end

  end

  def self.datastore
    MUTEX.synchronize { Thread.current[Servitium::DATA_STORE_KEY] }
  end

  ##
  # Wrapper for batch processing. We use redis sets to keep track of the jobs that are part of a batch.
  # This allows us to check when a batch is complete.
  # We make sure we wrap the perform method so we can add the job to the batch and set the datastore before it is executed.
  module JobClassMethods

    def perform_sync(*args)
      Servitium.datastore ||= HashWithIndifferentAccess.new
      super(*args)
    end

    def perform_inline(*args)
      Servitium.datastore ||= HashWithIndifferentAccess.new
      super(*args)
    end

    def perform_now(*args)
      Servitium.datastore ||= HashWithIndifferentAccess.new
      super(*args)
    end

    def perform(*args)
      unless args.first.is_a?(Hash) && Servitium.datastore.nil?
        return super(*args)
      end

      job_id = if respond_to?(:job_id)
                 self.job_id
               elsif respond_to?(:jid)
                 jid
               end

      begin
        Servitium.datastore = args.shift
        super(*args)
      ensure
        batch_info = Servitium::Batch.info || {}
        datastore = Servitium.datastore || {}
        Servitium.clear_datastore

        redis_key = "servitium:batch:#{batch_info['id']}"
        if job_id.present?
          begin
            transaction = Servitium.redis.multi do |transaction|
              transaction.scard(redis_key)
              transaction.srem(redis_key, "job_#{job_id}")
            end
            job_count = transaction[0].to_i - transaction[1].to_i

            if job_count == 0
              Servitium.redis.del(redis_key)
              Servitium.run_batch_callbacks(batch_info, :complete, datastore)
            end
          rescue
          end

          Servitium.run_batch_callbacks(batch_info, :job_complete, job_id, datastore)
        end
      end

    end
  end

  class << self

    ##
    # Run the all the callbacks for the given batch.
    def run_batch_callbacks(batch_info, name, *args)
      if batch_info['callbacks'].present?
        batch_info['callbacks'].each do |klass|
          next unless Object.const_defined?(klass)

          klass = Object.const_get(klass).new
          if klass.respond_to?(name)
            if ActiveRecord::Base.connection.transaction_open?
              record = Servitium::TransactionCallback.new
                                                     .with(:after_commit, -> { klass.send(name, *args) })
              ActiveRecord::Base.connection.add_transaction_record(record)
            else
              klass.send(name, *args)
            end
          end
        end
      end
    end

    ##
    # Set the datastore for the current thread.
    def datastore=(value)
      MUTEX.synchronize do
        return nil unless value.nil? || value.is_a?(Hash)

        Thread.current[Servitium::DATA_STORE_KEY] = value&.with_indifferent_access
      end
    end

    ##
    # Generate a new unique batch id.
    def generate_batch_id
      MUTEX.synchronize { SecureRandom.urlsafe_base64(16) }
    end

    ##
    # Get the redis instance that is used for batch processing.
    def redis
      redis_url = if Servitium.config.redis_url.is_a?(Hash)
                    Servitium.config.redis_url[Rails.env.to_sym]
                  else
                    Servitium.config.redis_url&.to_s
                  end
      @redis ||= ConnectionPool::Wrapper.new do
        Redis.new(url: redis_url)
      end
    rescue StandardError

    end

    ##
    # Clears the datastore for the current thread.
    # If a transaction is open, the datastore will be cleared after the transaction is committed or rolled back.
    def clear_datastore
      if ActiveRecord::Base.connection.transaction_open?
        record = Servitium::Batch::TransactionCallback.new
                                                      .with(:after_commit, -> { Servitium.datastore = nil })
                                                      .with(:after_rollback, -> { Servitium.datastore = nil })
        ActiveRecord::Base.connection.add_transaction_record(record)
      else
        Servitium.datastore = nil
      end
    end
  end
end
