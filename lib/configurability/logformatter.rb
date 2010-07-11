#!/usr/bin/env ruby

require 'logger'

require 'configurability'

# A custom log-formatter class for 
class Configurability::LogFormatter < Logger::Formatter

	# The format to output unless debugging is turned on
	DEFAULT_FORMAT = "[%1$s.%2$06d %3$d/%4$s] %5$5s -- %7$s\n"

	# The format to output if debugging is turned on
	DEFAULT_DEBUG_FORMAT = "[%1$s.%2$06d %3$d/%4$s] %5$5s {%6$s} -- %7$s\n"


	### Initialize the formatter with a reference to the logger so it can check for log level.
	def initialize( logger, format=DEFAULT_FORMAT, debug=DEFAULT_DEBUG_FORMAT ) # :notnew:
		@logger       = logger
		@format       = format
		@debug_format = debug

		super()
	end

	######
	public
	######

	# The Logger object associated with the formatter
	attr_accessor :logger

	# The logging format string
	attr_accessor :format

	# The logging format string that's used when outputting in debug mode
	attr_accessor :debug_format


	### Log using either the DEBUG_FORMAT if the associated logger is at ::DEBUG level or
	### using FORMAT if it's anything less verbose.
	def call( severity, time, progname, msg )
		args = [
			time.strftime( '%Y-%m-%d %H:%M:%S' ),                         # %1$s
			time.usec,                                                    # %2$d
			Process.pid,                                                  # %3$d
			Thread.current == Thread.main ? 'main' : Thread.object_id,    # %4$s
			severity,                                                     # %5$s
			progname,                                                     # %6$s
			msg                                                           # %7$s
		]

		if @logger.level == Logger::DEBUG
			return self.debug_format % args
		else
			return self.format % args
		end
	end

end # class Configurability::LogFormatter
