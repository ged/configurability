#!/usr/bin/env ruby

require 'set'
require 'loggability'
require 'yaml'

# A unified, unintrusive, assume-nothing configuration system for Ruby
module Configurability
	extend Loggability


	# Loggability API -- set up a Loggability logger for the library
	log_as :configurability


	# Library version constant
	VERSION = '4.2.0'

	# Version-control revision constant
	REVISION = %q$Revision$

	require 'configurability/deferred_config'

	autoload :Config, 'configurability/config'
	autoload :SettingInstaller, 'configurability/setting_installer'


	### The objects that have had Configurability added to them
	##
	# the Array of objects that have had Configurability added to them
	singleton_class.attr_accessor :configurable_objects
	@configurable_objects = []

	##
	# the loaded configuration (after ::configure_objects has been called at least once)
	singleton_class.attr_accessor :loaded_config
	@loaded_config = nil

	##
	# An Array of callbacks to be run after the config is loaded
	@after_configure_hooks = Set.new
	singleton_class.attr_reader :after_configure_hooks


	@after_configure_hooks_run = false

	### Returns +true+ if the after-configuration hooks have run at least once.
	def self::after_configure_hooks_run?
		return @after_configure_hooks_run ? true : false
	end


	### Set the flag that indicates that the after-configure hooks have run at least
	### once.
	def self::after_configure_hooks_run=( new_value )
		@after_configure_hooks_run = new_value ? true : false
	end


	### Register a callback to be run after the config is loaded.
	def self::after_configure( &block )
		raise LocalJumpError, "no block given" unless block
		self.after_configure_hooks << block

		# Call the block immediately if the hooks have already been called or are in
		# the process of being called.
		block.call if self.after_configure_hooks_run?
	end
	singleton_class.alias_method :after_configuration, :after_configure


	### Call the post-configuration callbacks.
	def self::call_after_configure_hooks
		self.log.debug "  calling %d post-config hooks" % [ self.after_configure_hooks.length ]
		@after_configure_hooks_run = true

		self.after_configure_hooks.to_a.each do |hook|
			# self.log.debug "    %s line %s..." % hook.source_location
			hook.call
		end
	end


	### Get the library version. If +include_buildnum+ is true, the version string will
	### include the VCS rev ID.
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
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

		self.reset
		self.loaded_config = config

		self.configurable_objects.each do |obj|
			self.install_config( config, obj )
		end

		self.call_after_configure_hooks
	end


	### If a configuration has been loaded (via {#configure_objects}), clear it.
	def self::reset
		self.loaded_config = nil
		self.after_configure_hooks_run = false
	end


	### Install the appropriate section of the +config+ into the given +object+.
	def self::install_config( config, object )
		self.log.debug "Configuring %p with the %s section of the config." %
			[ object, object.config_key ]

		section = self.find_config_section( config, object.config_key )
		configure_method = object.method( :configure )

		self.log.debug "  calling %p" % [ configure_method ]
		configure_method.call( section )
	end


	### Find the section of the specified +config+ object that corresponds to the
	### given +key+.
	def self::find_config_section( config, key )
		return key.to_s.split( '__' ).inject( config ) do |section, subkey|
			next nil if section.nil?
			self.get_config_subsection( section, subkey.to_sym )
		end
	end


	### Return the subsection of the specified +config+ that corresponds to +key+, trying
	### both struct-like and hash-like interfaces.
	def self::get_config_subsection( config, key )
		if config.respond_to?( key )
			self.log.debug "  config has a #%s method; using that" % [ key ]
			return config.send( key )
		elsif config.respond_to?( :[] ) && config.respond_to?( :key? )
			self.log.debug "  config has a hash-ish interface..."
			if config.key?( key.to_sym ) || config.key?( key.to_s )
				self.log.debug "    and has a %s member; using that" % [ key ]
				return config[ key.to_sym ] || config[ key.to_s ]
			else
				self.log.debug "    but no `%s` member." % [ key ]
				return nil
			end
		else
			self.log.debug "  no %p section in %p; configuring with nil" % [ key, config ]
			return nil
		end
	end


	### Nest the specified +hash+ inside subhashes for each subsection of the given +key+ and
	### return the result.
	def self::expand_config_hash( key, hash )
		return key.to_s.split( '__' ).reverse.inject( hash ) do |inner_hash, subkey|
			{ subkey.to_sym => inner_hash }
		end
	end


	### Gather defaults from objects with Configurability in the given +collection+
	### object. Objects that wish to add a section to the defaults should implement
	### a #defaults method in the same scope as #configure that returns the Hash of
	### default, or set one of the constants in the default implementation of
	### #defaults. The hash for each object will be merged into the +collection+
	### via #merge!.
	def self::gather_defaults( collection={} )
		mergefunc = Configurability::Config.method( :merge_complex_hashes )

		self.configurable_objects.each do |obj|
			next unless obj.respond_to?( :defaults )
			if defaults_hash = obj.defaults
				nested_hash = self.expand_config_hash( obj.config_key, defaults_hash )
				Configurability.log.debug "Defaults for %p (%p): %p" %
					[ obj, obj.config_key, nested_hash ]

				collection.merge!( nested_hash, &mergefunc )
			else
				Configurability.log.warn "No defaults for %p; skipping" % [ obj ]
			end
		end

		return collection
	end


	### Return the specified +key+ normalized into a valid Symbol config key.
	def self::normalize_config_key( key )
		return key.to_s.gsub( /\./, '__' ).to_sym
	end


	### Gather the default configuration in a Configurability::Config object and return it.
	def self::default_config
		return self.gather_defaults( Configurability::Config.new )
	end


	#############################################################
	### A P P E N D E D	  M E T H O D S
	#############################################################

	#
	# :section: Configuration API
	#

	### Get (and optionally set) the +config_key+ (a Symbol).
	def config_key( sym=nil )
		self.config_key = sym unless sym.nil?
		@config_key ||= Configurability.make_key_from_object( self )
		@config_key
	end


	### Set the config key of the object.
	def config_key=( sym )
		Configurability.configurable_objects |= [ self ]
		@config_key = Configurability.normalize_config_key( sym )
	end


	### Default configuration method. This will merge the provided +config+ with the defaults
	### if there are any and the +config+ responds to <tt>#to_h</tt>. If the +config+ responds to
	### <tt>#each_pair</tt>, any writable attributes of the calling object with the same name
	### as a key of the +config+ will be called with the corresponding value. E.g.,
	###
	###   class MyClass
	###       extend Configurability
	###       CONFIG_DEFAULTS = { environment: 'develop', apikey: 'testing-key' }
	###       config_key :my_class
	###       class << self
	###           attr_accessor :environment, :apikey
	###       end
	###   end
	###
	###   config = { my_class: {apikey: 'demo-key'} }
	###   Configurability.configure_objects( config )
	###
	###   MyClass.apikey
	###   # => 'demo-key'
	###   MyClass.environment
	###   # => 'develop'
	###
	def configure( config=nil )
		config = self.defaults( {} ).merge( config.to_h || {} ) if
			config.nil? || config.respond_to?( :to_h )

		@config = config

		if @config.respond_to?( :each_pair )
			@config.each_pair do |key, value|
				Configurability.log.debug "Looking for %p config attribute" % [ key ]
				next unless self.respond_to?( "#{key}=" )
				Configurability.log.debug "  setting %p to %p" % [ key, value ]
				self.public_send( "#{key}=", value )
			end
		else
			Configurability.log.
				debug "config object (%p) isn't iterable; skipping config attributes" % [ @config ]
		end

		return @config
	end


	#
	# :section: Configuration settings block
	#

	### Declare configuration settings and defaults. In the provided +block+, you can create
	### a configuration setting using the following syntax:
	###
	###   configurability( :my_config_key ) do
	###       # Declare a setting with a `nil` default
	###       setting :a_config_key
	###       # Declare one with a default value
	###       setting :another_config_key, default: 18
	###   end
	###
	def configurability( config_key=nil, &block )
		self.config_key = config_key if config_key

		if block
			Configurability.log.debug "Applying config declaration block using a SettingInstaller"
			installer = Configurability::SettingInstaller.new( self )
			installer.instance_eval( &block )
		end

		if (( config = Configurability.loaded_config ))
			Configurability.install_config( config, self )
		end

	end


	#
	# :section: Configuration Defaults API
	#

	### The default implementation of the method called by ::gather_defaults when
	### gathering configuration defaults. This method expects either a
	### +DEFAULT_CONFIG+ or a +CONFIG_DEFAULTS+ constant to contain the configuration
	### defaults, and will just return the +fallback+ value if neither exists.
	def defaults( fallback=nil )

		return fallback unless respond_to?( :const_defined? )

		Configurability.log.debug "Looking for defaults in %p's constants." % [ self ]
		if self.const_defined?( :DEFAULT_CONFIG, false )
			Configurability.log.debug "  found DEFAULT_CONFIG"
			return self.const_get( :DEFAULT_CONFIG, false ).dup
		elsif self.const_defined?( :CONFIG_DEFAULTS, false )
			Configurability.log.debug "  found CONFIG_DEFAULTS"
			return self.const_get( :CONFIG_DEFAULTS, false ).dup
		else
			Configurability.log.debug "  no default constants."
			return fallback
		end
	end


	### Return a Configurability::Config object that contains the configuration
	### defaults for the receiver.
	def default_config
		default_values = self.defaults or return Configurability::Config::Struct.new( {} )
		return Configurability::Config::Struct.new( default_values )
	end


	### Inject Configurability support into Loggability to avoid circular dependency
	### load issues.
	Loggability.extend( self )
	Loggability.config_key( :logging )

end # module Configurability

