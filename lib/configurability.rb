#!/usr/bin/env ruby

require 'yaml'

# A configuration mixin for Ruby classes.
# 
# == Author/s
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
module Configurability

	# Library version constant
	VERSION = '1.0.7'

	# Version-control revision constant
	REVISION = %q$Revision$

	require 'configurability/logformatter'
	require 'configurability/deferredconfig'


	### The objects that have had Configurability added to them
	@configurable_objects = []

	### The loaded config (if there is one)
	@loaded_config = nil

	### Logging
	@default_logger = Logger.new( $stderr )
	@default_logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN

	@default_log_formatter = Configurability::LogFormatter.new( @default_logger )
	@default_logger.formatter = @default_log_formatter

	@logger = @default_logger


	class << self

		# the Array of objects that have had Configurability added to them
		attr_accessor :configurable_objects

		# the loaded configuration (after ::configure_objects has been called at least once)
		attr_accessor :loaded_config

		# the log formatter that will be used when the logging subsystem is
		# reset
		attr_accessor :default_log_formatter

		# the logger that will be used when the logging subsystem is reset
		attr_accessor :default_logger

		# the logger that's currently in effect
		attr_accessor :logger
		alias_method :log, :logger
		alias_method :log=, :logger=
	end


	### Add configurability to the given +object+.
	def self::extend_object( object )
		self.log.debug "Adding Configurability to %p" % [ object ]
		super
		self.configurable_objects << object

		# If the config has already been propagated, add deferred configuration to the extending
		# object in case it overrides #configure later.
		if (( config = self.loaded_config ))
			self.install_config( config, object )
			object.extend( Configurability::DeferredConfig )
		end
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
			name = object.name
			name = 'anonymous' if name.nil? || name.empty?
			return name.sub( /.*::/, '' ).gsub( /\W+/, '_' ).downcase.to_sym
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
		self.log.debug "Splitting up config %p between %d objects with configurability." %
			[ config, self.configurable_objects.length ]

		self.loaded_config = config

		self.configurable_objects.each do |obj|
			self.install_config( config, obj )
		end
	end


	### If a configuration has been loaded (via {#configure_objects}), clear it.
	def self::reset
		self.loaded_config = nil
	end


	### Reset the global logger object to the default
	def self::reset_logger
		self.logger = self.default_logger
		self.logger.level = Logger::WARN
		self.logger.formatter = self.default_log_formatter
	end


	### Install the appropriate section of the +config+ into the given +object+.
	def self::install_config( config, object )
		section = object.config_key.to_sym
		self.log.debug "Configuring %p with the %p section of the config." %
			[ object, section ]

		if config.respond_to?( section )
			self.log.debug "  config has a %p method; using that" % [ section ]
			object.configure( config.send(section) )
		elsif config.respond_to?( :[] )
			self.log.debug "  config has a an index operator method; using that"
			object.configure( config[section] || config[section.to_s] )
		else
			self.log.warn "  don't know how to get the %p section of the config from %p" %
				[ section, config ]
			object.configure( nil )
		end
	end


	#############################################################
	### A P P E N D E D	  M E T H O D S
	#############################################################

	### The symbol which corresponds to the section of the configuration
	### used to configure the object.
	attr_writer :config_key

	### Get (and optionally set) the +config_key+ (a Symbol).
	def config_key( sym=nil )
		@config_key = sym unless sym.nil?
		@config_key ||= Configurability.make_key_from_object( self )
		@config_key
	end


	### Set the config key of the object.
	def config_key=( sym )
		@config_key = sym
	end


	### Default configuration method.
	def configure( config )
		@config = config
	end


end # module Configurability

