# frozen_string_literal: true

module Servitium
	class Configuration
		attr_accessor :redis_url
		attr_accessor :bg_jobs_platform
		attr_writer :logger

		def initialize
			@logger = Logger.new(STDOUT)
			@logger.level = Logger::INFO

			@bg_jobs_platform = :active_job
			@redis_url = ENV.fetch("RAILS_REDIS_URL") { "redis://localhost:6379/1" }
		end

		# logger [Object].
		def logger
			@logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
		end

	end
end
