# -*- ruby -*-
#encoding: utf-8

require 'loggability'
require 'configurability' unless defined?( Configurability )


# Methods for declaring config methods and constants inside a `configurability`
# block.
class Configurability::SettingInstaller
	extend Loggability

	log_to :configurability


	### Create a new Generator that can be used to add configuration methods and
	### constants to the specified +target+ object.
	def initialize( target )
		@target = target
	end


	##
	# The target object
	attr_reader :target


	### Declare a config setting with the specified +name+.
	def setting( name, **options )
		self.log.debug "  adding %s setting to %p" % [ name, self.target ]
		self.add_setting_accessors( name, options )
		self.add_default( name, options )
	end


	#########
	protected
	#########

	### Add accessors with the specified +name+ to the target.
	def add_setting_accessors( name, options )
		reader = lambda { self.instance_variable_get("@#{name}") }
		writer = lambda {|value| self.instance_variable_set("@#{name}", value) }

		self.target.define_singleton_method( "#{name}", &reader )
		self.target.define_singleton_method( "#{name}=", &writer )
	end


	### Add a default for +name+ to the CONFIG_DEFAULTS constant of the target, creating
	### it if necessary.
	def add_default( name, options )
		default_value = options[ :default ]

		self.target.instance_variable_set( "@#{name}", default_value )
		if self.target.respond_to?( :const_defined? )
			defaults = if self.target.const_defined?( :CONFIG_DEFAULTS )
					self.target.const_get( :CONFIG_DEFAULTS )
				else
					self.target.const_set( :CONFIG_DEFAULTS, {} )
				end

			defaults.store( name, default_value )
		end
	end

end # module Configurability::SettingInstaller

