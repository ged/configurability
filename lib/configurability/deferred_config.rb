#!/usr/bin/env ruby -wKU

require 'configurability' unless defined?( Configurability )


# Mixin that can be applied to classes to cause them to configure themselves
# as soon as they are able to.
module Configurability::DeferredConfig

	### Extension hook: log when the mixin is used.
	def self::extended( mod )
		Configurability.log.debug "Adding deferred configuration hook to %p" % [ mod ]
		super
	end


	### Singleton method definition hook: configure the instance as soon as it
	### overrides the #configure method supplied by the Configurability mixin itself.
	def singleton_method_added( sym )
		super

		if sym == :configure
			Configurability.log.debug "Re-configuring %p via deferred config hook." % [ self ]
			config = Configurability.loaded_config
			Configurability.log.debug "Propagating config to %p" % [ self ]
			Configurability.install_config( config, self )
		end
	end

end # module Configurability::DeferredConfig
