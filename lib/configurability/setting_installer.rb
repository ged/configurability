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
	def setting( name, **options, &block )
		self.log.debug "  adding %s setting to %p" % [ name, self.target ]
		self.add_setting_accessors( name, options, &block )
		self.add_default( name, options )
	end


	#########
	protected
	#########

	### Add accessors with the specified +name+ to the target.
	def add_setting_accessors( name, options, &writer_hook )
		if options[:use_class_vars]
			self.target.class_variable_set( "@@#{name}", nil )
		else
			self.target.instance_variable_set( "@#{name}", nil )
		end

		reader = self.make_setting_reader( name, options )
		writer = self.make_setting_writer( name, options, &writer_hook )

		self.target.define_singleton_method( "#{name}", &reader )
		self.target.define_singleton_method( "#{name}=", &writer )
	end


	### Create the body of the setting reader method with the specified +name+ and +options+.
	def make_setting_reader( name, options )
		if options[:use_class_vars]
			return lambda do
				Loggability[ Configurability ].debug "Using class variables for %s of %p" %
					[ name, self ]
				self.class_variable_get("@@#{name}")
			end
		else
			return lambda {
				self.instance_variable_get("@#{name}")
			}
		end
	end


	### Create the body of the setting writer method with the specified +name+ and +options+.
	def make_setting_writer( name, options, &writer_hook )
		if options[:use_class_vars]
			return lambda do |value|
				Loggability[ Configurability ].debug "Using class variables for %s of %p" %
					[ name, self ]
				value = writer_hook[ value ] if writer_hook
				self.class_variable_set( "@@#{name}", value )
			end
		else
			return lambda do |value|
				value = writer_hook[ value ] if writer_hook
				self.instance_variable_set( "@#{name}", value )
			end
		end
	end


	### Add a default for +name+ to the CONFIG_DEFAULTS constant of the target, creating
	### it if necessary.
	def add_default( name, options )
		default_value = options[ :default ]

		self.target.send( "#{name}=", default_value )
		if self.target.respond_to?( :const_defined? )
			defaults = if self.target.const_defined?( :CONFIG_DEFAULTS, false )
					self.target.const_get( :CONFIG_DEFAULTS, false )
				else
					self.target.const_set( :CONFIG_DEFAULTS, {} )
				end

			defaults.store( name, default_value )
		end
	end

end # module Configurability::SettingInstaller

