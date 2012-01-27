#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/helpers'

require 'configurability'
require 'configurability/config'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Configurability do
	include Configurability::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :each ) do
		Configurability.configurable_objects.clear
		Configurability.reset
	end


	it "adds a method for registering an including module's config key" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		klass.config_key.should == :testconfig
	end

	it "fetches config sections via a method with the config key name if the config " +
	   "responds_to? it" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :testconfig ).and_return( true )
		config.should_receive( :testconfig ).and_return( :a_config_section )

		klass.should_receive( :configure ).with( :a_config_section )
		Configurability.configure_objects( config )
	end

	it "extends including classes instead of appending features to them" do
		klass = Class.new do
			include Configurability
			config_key :testconfig
		end

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :testconfig ).and_return( true )
		config.should_receive( :testconfig ).and_return( :a_config_section )

		klass.should_receive( :configure ).with( :a_config_section )
		Configurability.configure_objects( config )
	end

	it "fetches config sections via the index operator if the config doesn't respond " +
	   "directly to the section name, but does to the index operator and #key?" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :testconfig ).and_return( false )
		config.should_receive( :respond_to? ).with( :key? ).and_return( true )
		config.should_receive( :respond_to? ).with( :[] ).and_return( true )
		config.should_receive( :key? ).with( :testconfig ).and_return( true )
		config.should_receive( :[] ).with( :testconfig ).and_return( :a_config_section )

		klass.should_receive( :configure ).with( :a_config_section )
		Configurability.configure_objects( config )
	end

	it "passes nil to the configure method if the config doesn't respond to the section " +
	   "name or the index operator" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :testconfig ).and_return( false )
		config.should_receive( :respond_to? ).with( :[] ).and_return( false )

		klass.should_receive( :configure ).with( nil )

		Configurability.configure_objects( config )
	end

	it "tries the config key as a String if calling it with the Symbol returns nil" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :testconfig ).and_return( false )
		config.should_receive( :respond_to? ).with( :key? ).and_return( true )
		config.should_receive( :respond_to? ).with( :[] ).and_return( true )
		config.should_receive( :key? ).with( :testconfig ).and_return( false )
		config.should_receive( :key? ).with( 'testconfig' ).and_return( true )
		config.should_receive( :[] ).with( :testconfig ).and_return( nil )
		config.should_receive( :[] ).with( 'testconfig' ).and_return( :a_config_section )

		klass.should_receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end

	it "can be used to configure plain objects, too" do
		object = Object.new
		object.extend( Configurability )
		object.config_key = :testobjconfig

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :testobjconfig ).and_return( true )
		config.should_receive( :testobjconfig ).and_return( :a_config_section )

		object.should_receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end

	it "uses the object's name for its config key if it has one and hasn't specified a key " +
	   "directly" do
		object = Object.new
		def object.name; "testobjconfig"; end
		object.extend( Configurability )

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :testobjconfig ).and_return( true )
		config.should_receive( :testobjconfig ).and_return( :a_config_section )

		object.should_receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end

	it "normalizes the object's name before using it" do
		object = Object.new
		def object.name; "Test Obj-Config"; end
		object.extend( Configurability )

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :test_obj_config ).and_return( true )
		config.should_receive( :test_obj_config ).and_return( :a_config_section )

		object.should_receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end

	it "uses the object's class's name for its config key if it doesn't have a name and " +
	   "hasn't specified a key directly" do
		object = Object.new
		object.extend( Configurability )

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :object ).and_return( true )
		config.should_receive( :object ).and_return( :a_config_section )

		object.should_receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end

	it "uses only the last part of a class's name if it is namespaced" do
		module My
			class DbObject
				extend Configurability
			end
		end

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :dbobject ).and_return( true )
		config.should_receive( :dbobject ).and_return( :a_config_section )

		My::DbObject.should_receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end

	it "uses the 'anonymous' key if the object doesn't have a name, and its class is " +
	   "anonymous, and it hasn't specified a key directly" do
		objectclass = Class.new
		object = objectclass.new
		object.extend( Configurability )

		config = mock( "configuration object" )
		config.should_receive( :respond_to? ).with( :anonymous ).and_return( true )
		config.should_receive( :anonymous ).and_return( :a_config_section )

		object.should_receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end


	context "after installation of a config object" do

		before( :each ) do
			@config = Configurability::Config.new
			@config.postconfig = :yes
			Configurability.configure_objects( @config )
		end

		after( :each ) do
			Configurability.reset
		end


		it "should know what the currently-installed configuration is" do
			Configurability.loaded_config.should equal( @config )
		end

		it "propagates the installed configuration to any objects which add Configurability" do
			objectclass = Class.new do
				def initialize; @config = nil; end
				attr_reader :config
				def name; "postconfig"; end
				def configure( config ); @config = config; end
			end

			object = objectclass.new
			object.extend( Configurability )
			object.config.should == :yes
		end

		it "defers configuration until after an object has defined a #configure method if " +
		   "it adds Configurability before declaring one" do
			objectclass = Class.new do
				extend Configurability
				config_key :postconfig
				def self::configure( config ); @config = config; end
				class << self; attr_reader :config; end
			end

			objectclass.config.should == :yes
		end

		it "doesn't reconfigure objects that have already been configured unless the config changes" do
			first_objectclass = Class.new do
				extend Configurability
				@configs = []
				config_key :postconfig
				def self::configure( config ); @configs << config; end
				def self::inherited( subclass ); subclass.instance_variable_set(:@configs, []); super; end
				class << self; attr_reader :configs; end
			end

			second_objectclass = Class.new( first_objectclass ) do
				extend Configurability
				config_key :postconfig
				def self::configure( config ); @configs << config; end
			end

			third_objectclass = Class.new( second_objectclass ) do
				extend Configurability
				config_key :postconfig
				def self::configure( config ); @configs << config; end
			end

			first_objectclass.configs.should == [ @config[:postconfig] ]
			second_objectclass.configs.should == [ nil, @config[:postconfig] ]
			third_objectclass.configs.should == [ nil, @config[:postconfig] ]
		end

	end

end

# vim: set nosta noet ts=4 sw=4:
