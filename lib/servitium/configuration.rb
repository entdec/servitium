# frozen_string_literal: true

module Servitium
  class Configuration
    attr_accessor :bg_jobs_platform
    attr_writer :logger
    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO

      @bg_jobs_platform = :active_job
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end
  end
end
