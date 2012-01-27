#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'logger'
require 'configurability'
require 'configurability/config'

config = Configurability::Config.new( <<"END_CONFIG" )
---
aardvark:
  a_value: 1

bat:
  b_value: 2

caterpillar:
  c_value: 3

END_CONFIG


class A
	extend Configurability
	config_key :aardvark

	def self::configure( config )
		$stderr.puts "(A) Configuring %p with: %p" % [ self, config ]
		require_relative 'staticcling-weirdness2'
	end

end


Configurability.logger.level = Logger::DEBUG
config.install

