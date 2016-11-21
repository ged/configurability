#!/usr/bin/env ruby

require 'helpers'

require 'tempfile'
require 'logger'
require 'fileutils'
require 'rspec'

require 'configurability'
require 'configurability/deferredconfig'


#####################################################################
###	C O N T E X T S
#####################################################################
describe Configurability::DeferredConfig do

	after( :each ) do
		Configurability.configurable_objects.clear
		Configurability.reset
	end


	it "calls Configurability.install_config with itself when a 'configure' method is defined" do
		config = { :testing => :testing_config }
		Configurability.configure_objects( config )

		a_class = Class.new do
			extend Configurability::DeferredConfig
			class << self; attr_accessor :config_object; end
			def self::config_key; "testing"; end
			def self::configure( config )
				self.config_object = config
			end
		end

		expect( a_class.config_object ).to be( :testing_config )
	end


	it "includes defaults when configuring" do
		config = { :testing => :testing_config }
		Configurability.configure_objects( config )

		a_class = Class.new do
			extend Configurability::DeferredConfig
			class << self; attr_accessor :config_object; end
			def self::config_key; "testing"; end
			def self::configure( config )
				self.config_object = config
			end
		end

		expect( a_class.config_object ).to be( :testing_config )
	end

end

# vim: set nosta noet ts=4 sw=4:
