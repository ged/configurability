#!/usr/bin/env ruby

require 'yaml'

# A configuration mixin for Ruby classes.
# 
# @author Michael Granger <ged@FaerieMUD.org>
# 
module Configurability

	# Library version constant
	VERSION = '1.0.0'

	# Version-control revision constant
	REVISION = %q$Revision$

	require 'configurability/logformatter.rb'


	### The objects that have had Configurability added to them
	@configurable_objects = []

	### Logging
	@default_logger = Logger.new( $stderr )
	@default_logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN

	@default_log_formatter = Configurability::LogFormatter.new( @default_logger )
	@default_logger.formatter = @default_log_formatter

	@logger = @default_logger


	class << self

		# @return [Array] the Array of objects that have had Configurability 
		# added to them
		attr_accessor :configurable_objects

		# @return [Logger::Formatter] the log formatter that will be used when the logging 
		#    subsystem is reset
		attr_accessor :default_log_formatter

		# @return [Logger] the logger that will be used when the logging subsystem is reset
		attr_accessor :default_logger

		# @return [Logger] the logger that's currently in effect
		attr_accessor :logger
		alias_method :log, :logger
		alias_method :log=, :logger=
	end


	### Add configurability to the given +object+.
	def self::extend_object( object )
		self.log.debug "Adding Configurability to %p" % [ object ]
		super
		self.configurable_objects << object
	end


	### Mixin hook: extend including classes instead
	def self::included( mod )
		mod.extend( self )
	end


	### Try to generate a config key from the given object. If it responds_to #name,
	### the result will be stringified and stripped of non-word characters. If the
	### object itself doesn't have a name, the name of its class will be used instead.
	def self::make_key_from_object( object )
		if object.respond_to?( :name )
			return object.name.sub( /.*::/, '' ).gsub( /\W+/, '_' ).downcase.to_sym
		elsif object.class.name && !object.class.name.empty?
			return object.class.name.sub( /.*::/, '' ).gsub( /\W+/, '_' ).downcase.to_sym
		else
			return :anonymous
		end
	end


	### Configure objects that have had Configurability added to them with 
	### the sections of the specified +config+ that correspond to their 
	### +config_key+. If the +config+ doesn't #respond_to the object's
	### +config_key+, the object's #configure method is called with +nil+ 
	### instead.
	def self::configure_objects( config )
		self.configurable_objects.each do |obj|
			section = obj.config_key.to_sym
			self.log.debug "Configuring %p with the %p section of the config." %
				[ obj, section ]

			if config.respond_to?( section )
				self.log.debug "  config has a %p method; using that" % [ section ]
				obj.configure( config.send(section) )
			elsif config.respond_to?( :[] )
				self.log.debug "  config has a an index operator method; using that"
				obj.configure( config[section] )
			else
				self.log.warn "  don't know how to get the %p section of the config from %p" %
					[ section, config ]
				obj.configure( nil )
			end
		end
	end


	### Reset the global logger object to the default
	### @return [void]
	def self::reset_logger
		self.logger = self.default_logger
		self.logger.level = Logger::WARN
		self.logger.formatter = self.default_log_formatter
	end



	#############################################################
	### A P P E N D E D	  M E T H O D S
	#############################################################

	### The symbol which corresponds to the section of the configuration
	### used to configure the object.
	attr_writer :config_key

	### Get (and optionally set) the +config_key+.
	### @param [Symbol] sym  the config key
	### @return [Symbol] the config key
	def config_key( sym=nil )
		@config_key = sym unless sym.nil?
		@config_key ||= Configurability.make_key_from_object( self )
		@config_key
	end


	### Set the config key of the object.
	### @params [Symbol] sym  the config key
	def config_key=( sym )
		@config_key = sym
	end


	### Default configuration method.
	### @param [Object] configuration section object
	def configure( config )
		@config = config
	end


end # module Configurability

