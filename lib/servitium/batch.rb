module Servitium
  module Batch
    #
    # Start processing a batch of jobs with callbacks to be executed when all jobs are complete.
    # Any jobs that are performed within the block will be added to the batch. A hash of data can be passed that is shared between jobs.
    # This also includes any jobs that are performed within other jobs.
    # Supports
    #   Any class that inherits from ActiveJob::Base will be added to the batch.
    #   Any class that includes Sidekiq::Job will be added to the batch.
    #
    # @param datastore [Hash] A hash of data that is shared between jobs.
    # @yield The block of code to be executed within the batch.
    #
    # @example Starting a batch with a callback and a job
    #   Servitium::Batch.start(some_key: "some_value", metadata: {"current_time": Time.current}) do
    #     Servitium::Batch.add_callback(Callback)
    #     Job1.perform_later(1)
    #   end
    #
    # @example Defining a callback class
    #   class Callback
    #     def complete(_datastore)
    #       # Do something
    #     end
    #
    #     def job_complete(_job_id, _datastore)
    #       # Do something
    #     end
    #   end
    def self.start(**datastore, &block)
      if Servitium::Batch.info.nil? # TODO: Support nested batches
        batch_id = Servitium.generate_batch_id

        begin
          Thread.current['servitium_batch_job_count'] ||= 0
          Thread.current['servitium_batch_job_count'] = Thread.current['servitium_batch_job_count'] + 1

          datastore['batch_info'] = {
            'id': batch_id,
            'callbacks': [],
            'started_at': Time.current.to_s,
            'caller': [block.binding.receiver.class.name, eval('__method__', block.binding).to_s]
          }
          Servitium.datastore = datastore

          Servitium::Batch.add_member("batch_#{batch_id}")
          yield if block_given?
        ensure
          Thread.current['servitium_batch_job_count'] = Thread.current['servitium_batch_job_count'] - 1

          Servitium.clear_datastore

          redis_key = "servitium:batch:#{batch_id}"
          transaction = Servitium.redis.multi do |transaction|
            transaction.scard(redis_key)
            transaction.srem(redis_key, "batch_#{batch_id}")
          end
          job_count = transaction[0].to_i - transaction[1].to_i

          if job_count.zero?
            Servitium.redis.del(redis_key)
            Servitium.run_batch_callbacks(datastore['batch_info'], :complete, datastore)
          end
        end
      elsif block_given?
        yield
      end
    end

    ##
    # Add a callback class to the batch.
    # The callback class can implement the following methods:
    #  * complete(datastore)
    #  * job_complete(job_id, datastore)
    #
    # @param klass [Class] The callback class to be added.
    #
    def self.add_callback(klass)
      datastore = Servitium.datastore
      return if datastore.nil?

      klass = klass.name if klass.is_a?(Class)
      datastore['batch_info']['callbacks'] << klass.to_s
    end

    ##
    # Get a value from the datastore using one or more keys.
    #
    # @param keys [Array] One or more keys to retrieve the value.
    #
    # @return [Object] The value associated with the keys.
    #
    def self.get(*keys)
      datastore = Servitium.datastore
      return if datastore.nil?

      datastore.dig(*keys)
    end

    ##
    # Set a value in the datastore using one or more keys.
    #
    # @param keys [Array] One or more keys to set the value.
    # @param value [Object] The value to be set.
    #
    def self.set(*keys, value)
      datastore = Servitium.datastore
      return if datastore.nil?

      datastore.dig(*keys[0..-2])[keys[-1]] = value
    end

    ##
    # Merge a hash of values into the datastore.
    #
    # @param args [Hash] A hash of values to be merged.
    #
    def self.merge(**args)
      datastore = Servitium.datastore
      return if datastore.nil?

      datastore.merge!(**args)
    end

    ##
    # Get the batch information from the datastore.
    # @example Batch information
    #  {
    #   "id": "batch_1",
    #   "callbacks": ["Callback"],
    #   "started_at": "2021-03-04 15:00:00 +0000",
    #   "caller": ["SomeClass", "some_method"]
    #  }
    #
    # @return [Hash] The batch information.
    #
    def self.info
      get('batch_info')
    end

    def valid_batch_info?(hash)
      return false unless hash.is_a?(Hash) && hash['batch_info'].is_a?(Hash)

      hash['batch_info']['id'].present?
    end

    def self.add_member(id)
      return if Servitium.datastore.nil?

      batch_info = Servitium::Batch.info
      if batch_info.present? && batch_info['id'].present?
        redis_key = "servitium:batch:#{batch_info['id']}"
        Servitium.redis.multi do |transaction|
          transaction.sadd(redis_key, id)
          transaction.expire(redis_key, SECONDS_IN_DAY * 30)
        end
      end
    end

    def self.ignore_job?(klass)
      klass = klass.name if klass.is_a?(Class)
      return false if klass.blank?

      return false if Servitium::Batch.info.present? && Servitium::Batch.info['caller'][0] == klass

      Servitium.config.ignore_list.include?(klass)
    end

    class TransactionCallback
      def initialize(connection = ActiveRecord::Base.connection)
        @connection = connection
        @handlers = HashWithIndifferentAccess.new
      end

      def with(name, proc)
        @handlers[name] = proc
        self
      end

      def has_transactional_callbacks?
        true
      end

      def before_committed!(*)
        @handlers[:before_commit]&.call
      end

      def trigger_transactional_callbacks?
        true
      end

      def committed!(*)
        @handlers[:after_commit]&.call
      end

      def rolledback!(*)
        @handlers[:after_rollback]&.call
      end

      # Required for +transaction(requires_new: true)+
      def add_to_transaction(*)
        @connection.add_transaction_record(self)
      end
    end
  end
end
