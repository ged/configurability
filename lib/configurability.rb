#!/usr/bin/env ruby

require 'loggability'
require 'yaml'

# A configuration mixin for Ruby classes.
#
# == Author/s
#
# * Michael Granger <ged@FaerieMUD.org>
#
module Configurability
	extend Loggability


	# Loggability API -- set up a Loggability logger for the library
	log_as :configurability


	# Library version constant
	VERSION = '2.2.2'

	# Version-control revision constant
	REVISION = %q$Revision$

	require 'configurability/deferredconfig'

	autoload :Config, 'configurability/config'


	### The objects that have had Configurability added to them
	@configurable_objects = []

	### The loaded config (if there is one)
	@loaded_config = nil

	### The hash of configuration calls that have already taken place -- the keys are
	### Method objects for the configure methods of the configured objects, and the values
	### are the config section it was called with
	@configured = Hash.new( false )

	class << self

		# the Array of objects that have had Configurability added to them
		attr_accessor :configurable_objects

		# the loaded configuration (after ::configure_objects has been called at least once)
		attr_accessor :loaded_config

		# the hash of configure methods => config sections which have already been installed
		attr_reader :configured

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
	end


	### If a configuration has been loaded (via {#configure_objects}), clear it.
	def self::reset
		self.loaded_config = nil
		self.configured.clear
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


	### Nest the specified +hash+ inside subhashes for each subsection of the given +key+ and
	### return the result.
	def self::expand_config_hash( key, hash )
		return key.to_s.split( '__' ).reverse.inject( hash ) do |inner_hash, subkey|
			{ subkey.to_sym => inner_hash }
		end
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
		@config_key = normalize_config_key( sym )
	end


	### Default configuration method.
	def configure( config )
		@config = config
	end


	### Return the specified +key+ normalized into a valid Symbol config key.
	def normalize_config_key( key )
		return key.to_s.gsub( /\./, '__' ).to_sym
	end


	#
	# :section: Configuration Defaults API
	#

	### The default implementation of the method called by ::gather_defaults when
	### gathering configuration defaults. This method expects either a
	### +DEFAULT_CONFIG+ or a +CONFIG_DEFAULTS+ constant to contain the configuration
	### defaults, and will just return +nil+ if neither exists.
	def defaults

		return nil unless respond_to?( :const_defined? )

		Configurability.log.debug "Looking for defaults in %p's constants." % [ self ]
		if self.const_defined?( :DEFAULT_CONFIG, false )
			Configurability.log.debug "  found DEFAULT_CONFIG"
			return self.const_get( :DEFAULT_CONFIG, false ).dup
		elsif self.const_defined?( :CONFIG_DEFAULTS, false )
			Configurability.log.debug "  found CONFIG_DEFAULTS"
			return self.const_get( :CONFIG_DEFAULTS, false ).dup
		else
			Configurability.log.debug "  no default constants."
			return nil
		end
	end


	### Return a Configurability::Config object that contains the configuration
	### defaults for the receiver.
	def default_config
		default_values = self.defaults or return Configurability::Config.new( {} )
		return Configurability::Config::Struct.new( default_values )
	end


	### Inject Configurability support into Loggability to avoid circular dependency
	### load issues.
	Loggability.extend( self )
	Loggability.config_key( :logging )

end # module Configurability

