# frozen_string_literal: true

module Servitium
  class Configuration
    attr_writer :redis_url
    attr_reader :ignore_list
    attr_accessor :bg_jobs_platform
    attr_writer :logger

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO

      @bg_jobs_platform = :active_job
      @redis_url = ENV.fetch("RAILS_REDIS_URL") { "redis://localhost:6379/1" }
      @ignore_list = Set.new
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    # The redis_url can be a String or a Hash.
    # A hash is used to configure the redis connection pool per environment.
    # Example: { development: "redis://localhost:6379/1", test: "redis://localhost:6379/2", production: "redis://localhost:6379/3" }
    #
    # redis_url [String, Hash].
    def redis_url
      url = if @redis_url.is_a?(Hash)
              @redis_url[::Rails.env.to_sym].to_s
            else
              @redis_url.to_s
            end
      url || ENV.fetch("RAILS_REDIS_URL") { "redis://localhost:6379/1" }
    end

    def ignore_list=(value)
      @ignore_list = if value.is_a?(Array)
                       Set.new(value.map(&:to_s))
                     else
                       Set.new([value.to_s])
                     end
    end

  end
end
