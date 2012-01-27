#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'configurability'
require 'configurability/config'


class C < B
	extend Configurability
	config_key :caterpillar

	def self::configure( config )
		$stderr.puts "(C) Configuring %p with: %p" % [ self, config ]
	end

end

