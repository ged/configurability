# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'logger'
require 'date'

require 'configurability' unless defined?( Configurability )


# A mixin that provides a top-level logging subsystem based on Logger.
module Configurability::Logging

	### Logging
	# Log levels
	LOG_LEVELS = {
		'debug' => Logger::DEBUG,
		'info'  => Logger::INFO,
		'warn'  => Logger::WARN,
		'error' => Logger::ERROR,
		'fatal' => Logger::FATAL,
	}.freeze
	LOG_LEVEL_NAMES = LOG_LEVELS.invert.freeze


	### Inclusion hook
	def self::extended( mod )
		super

		class << mod
			# the log formatter that will be used when the logging subsystem is reset
			attr_accessor :default_log_formatter

			# the logger that will be used when the logging subsystem is reset
			attr_accessor :default_logger

			# the logger that's currently in effect
			attr_accessor :logger
			alias_method :log, :logger
			alias_method :log=, :logger=
		end

		mod.default_logger = mod.logger = Logger.new( $stderr )
		mod.default_logger.level = case
			when $DEBUG then Logger::DEBUG
			when $VERBOSE then Logger::INFO
			else Logger::WARN end
		mod.default_log_formatter = Configurability::Logging::Formatter.new( mod.default_logger )
	end


	### Reset the global logger object to the default
	def reset_logger
		self.logger = self.default_logger
		self.logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN
		self.logger.formatter = self.default_log_formatter
	end


	### Returns +true+ if the global logger has not been set to something other than
	### the default one.
	def using_default_logger?
		return self.logger == self.default_logger
	end


	# A alternate formatter for Logger instances.
	class Formatter < Logger::Formatter

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
	end # class Formatter


	# A ANSI-colorized formatter for Logger instances.
	class ColorFormatter < Logger::Formatter

		# Set some ANSI escape code constants (Shamelessly stolen from Perl's
		# Term::ANSIColor by Russ Allbery <rra@stanford.edu> and Zenin <zenin@best.com>
		ANSI_ATTRIBUTES = {
			'clear'      => 0,
			'reset'      => 0,
			'bold'       => 1,
			'dark'       => 2,
			'underline'  => 4,
			'underscore' => 4,
			'blink'      => 5,
			'reverse'    => 7,
			'concealed'  => 8,

			'black'      => 30,   'on_black'   => 40,
			'red'        => 31,   'on_red'     => 41,
			'green'      => 32,   'on_green'   => 42,
			'yellow'     => 33,   'on_yellow'  => 43,
			'blue'       => 34,   'on_blue'    => 44,
			'magenta'    => 35,   'on_magenta' => 45,
			'cyan'       => 36,   'on_cyan'    => 46,
			'white'      => 37,   'on_white'   => 47
		}


		### Create a string that contains the ANSI codes specified and return it
		def self::ansi_code( *attributes )
			attributes.flatten!
			attributes.collect! {|at| at.to_s }
			return '' unless /(?:vt10[03]|xterm(?:-color)?|linux|screen)/i =~ ENV['TERM']
			attributes = ANSI_ATTRIBUTES.values_at( *attributes ).compact.join(';')

			if attributes.empty?
				return ''
			else
				return "\e[%sm" % attributes
			end
		end


		### Colorize the given +string+ with the specified +attributes+ and
		### return it, handling line-endings, color reset, etc.
		def self::colorize( *args )
			string = ''

			if block_given?
				string = yield
			else
				string = args.shift
			end

			ending = string[/(\s)$/] || ''
			string = string.rstrip

			return self.ansi_code( args.flatten ) + string + self.ansi_code( 'reset' ) + ending
		end


		# Color settings
		LEVEL_FORMATS = {
			:debug => colorize( :bold, :black ) {"[%1$s.%2$06d %3$d/%4$s] %5$5s {%6$s} -- %7$s\n"},
			:info  => colorize( :normal ) {"[%1$s.%2$06d %3$d/%4$s] %5$5s -- %7$s\n"},
			:warn  => colorize( :bold, :yellow ) {"[%1$s.%2$06d %3$d/%4$s] %5$5s -- %7$s\n"},
			:error => colorize( :red ) {"[%1$s.%2$06d %3$d/%4$s] %5$5s -- %7$s\n"},
			:fatal => colorize( :bold, :red, :on_white ) {"[%1$s.%2$06d %3$d/%4$s] %5$5s -- %7$s\n"},
		}


		### Initialize the formatter with a reference to the logger so it can check for log level.
		def initialize( logger, settings={} ) # :notnew:
			settings = LEVEL_FORMATS.merge( settings )

			@logger   = logger
			@settings = settings

			super()
		end

		######
		public
		######

		# The Logger object associated with the formatter
		attr_accessor :logger

		# The formats, by level
		attr_accessor :settings


		### Log using the format associated with the severity
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

			return self.settings[ severity.downcase.to_sym ] % args
		end

	end # class Formatter


	# An alternate formatter for Logger instances that outputs +div+ HTML
	# fragments.
	class HtmlFormatter < Logger::Formatter

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
				escape_html( msg ).gsub(/\n/, '<br />')                       # %7$s
			]

			return self.format % args
		end


		#######
		private
		#######

		### Escape any HTML special characters in +string+.
		def escape_html( string )
			return string.
				gsub( '&', '&amp;' ).
				gsub( '<', '&lt;'  ).
				gsub( '>', '&gt;'  )
		end

	end # class HtmlFormatter


end # module Configurability

