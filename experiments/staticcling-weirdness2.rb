#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'configurability'
require 'configurability/config'


class B < A
	extend Configurability
	config_key :bat

	def self::configure( config )
		$stderr.puts "(B) Configuring %p with: %p" % [ self, config ]
	end

	require_relative 'staticcling-weirdness3'

end

