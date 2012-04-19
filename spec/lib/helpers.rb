#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'simplecov'
require 'rspec'

require 'logger'
require 'erb'
require 'yaml'

SimpleCov.start do
	add_filter '/spec/'
	add_filter '/textmate-command/'
end
require 'configurability'


# An alternate formatter for Logger instances that outputs +div+ HTML
# fragments.
class HtmlLogFormatter < Logger::Formatter
	include ERB::Util  # for html_escape()

	# The default HTML fragment that'll be used as the template for each log message.
	HTML_LOG_FORMAT = %q{
	<div class="log-message %5$s">
		<span class="log-time">%1$s.%2$06d</span>
		[
			<span class="log-pid">%3$d</span>
			/
			<span class="log-tid">%4$s</span>
		]
		<span class="log-level">%5$s</span>
		:
		<span class="log-name">%6$s</span>
		<span class="log-message-text">%7$s</span>
	</div>
	}

	### Override the logging formats with ones that generate HTML fragments
	def initialize( logger, format=HTML_LOG_FORMAT ) # :notnew:
		@logger = logger
		@format = format
		super()
	end


	######
	public
	######

	# The HTML fragment that will be used as a format() string for the log
	attr_accessor :format


	### Return a log message composed out of the arguments formatted using the
	### formatter's format string
	def call( severity, time, progname, msg )
		args = [
			time.strftime( '%Y-%m-%d %H:%M:%S' ),                         # %1$s
			time.usec,                                                    # %2$d
			Process.pid,                                                  # %3$d
			Thread.current == Thread.main ? 'main' : Thread.object_id,    # %4$s
			severity.downcase,                                                     # %5$s
			progname,                                                     # %6$s
			html_escape( msg ).gsub(/\n/, '<br />')                       # %7$s
		]

		return self.format % args
	end

end # class HtmlLogFormatter

### RSpec helper functions.
module Configurability::SpecHelpers

	LEVEL = {
		:debug => Logger::DEBUG,
		:info  => Logger::INFO,
		:warn  => Logger::WARN,
		:error => Logger::ERROR,
		:fatal => Logger::FATAL,
	  }

	class ArrayLogger
		### Create a new ArrayLogger that will append content to +array+.
		def initialize( array )
			@array = array
		end

		### Write the specified +message+ to the array.
		def write( message )
			@array << message
		end

		### No-op -- this is here just so Logger doesn't complain
		def close; end

	end # class ArrayLogger


	###############
	module_function
	###############

	### Reset the logging subsystem to its default state.
	def reset_logging
		Configurability.reset_logger
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=Logger::FATAL )

		# Turn symbol-style level config into Logger's expected Fixnum level
		level = LEVEL[ level ] if LEVEL.key?( level )

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			Thread.current['logger-output'] = []
			logdevice = ArrayLogger.new( Thread.current['logger-output'] )
			Configurability.logger = Logger.new( logdevice )
			Configurability.logger.formatter = HtmlLogFormatter.new( Configurability.logger )
		else
			logger = Logger.new( $stderr )
			Configurability.logger = logger
			Configurability.logger.level = level
		end
	end

end


RSpec.configure do |config|
	config.mock_with( :rspec )
	config.include( Configurability::SpecHelpers )
	config.treat_symbols_as_metadata_keys_with_true_values = true

	config.filter_run_excluding :only_ruby_19 if RUBY_VERSION < '1.9.2'

end

# vim: set nosta noet ts=4 sw=4:

