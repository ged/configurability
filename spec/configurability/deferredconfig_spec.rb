#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'tempfile'
require 'logger'
require 'fileutils'
require 'rspec'

require 'spec/lib/helpers'

require 'configurability'
require 'configurability/deferredconfig'


#####################################################################
###	C O N T E X T S
#####################################################################
describe Configurability::DeferredConfig do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :each ) do
		Configurability.configurable_objects.clear
		Configurability.reset
	end

	it "calls Configurability.install_config with itself when a 'configure' method is defined" do
		config = double( "config object", :testing => :testing_config )
		Configurability.configure_objects( config )

		a_class = Class.new do
			extend Configurability::DeferredConfig
			class << self; attr_accessor :config_object; end
			def self::config_key; "testing"; end
			def self::configure( config )
				self.config_object = config
			end
		end

		a_class.config_object.should == :testing_config
	end

end

# vim: set nosta noet ts=4 sw=4:
