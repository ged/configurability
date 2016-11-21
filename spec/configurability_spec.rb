#!/usr/bin/env ruby

require 'helpers'

require 'rspec'

require 'configurability'
require 'configurability/config'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Configurability do

	before( :each ) do
		Configurability.configurable_objects.clear
		Configurability.reset
	end

	after( :all ) do
		Configurability.configurable_objects.clear
		Configurability.reset
	end


	it "adds a method for registering an including module's config key" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		expect( klass.config_key ).to be( :testconfig )
	end


	it "fetches config sections via a method with the config key name if the config " +
	   "responds_to? it" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testconfig ).and_return( true )
		expect( config ).to receive( :testconfig ).and_return( :a_config_section )

		expect( klass ).to receive( :configure ).with( :a_config_section )
		Configurability.configure_objects( config )
	end


	it "extends including classes instead of appending features to them" do
		klass = Class.new do
			include Configurability
			config_key :testconfig
		end

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testconfig ).and_return( true )
		expect( config ).to receive( :testconfig ).and_return( :a_config_section )

		expect( klass ).to receive( :configure ).with( :a_config_section )
		Configurability.configure_objects( config )
	end


	it "fetches config sections via the index operator if the config doesn't respond " +
	   "directly to the section name, but does to the index operator and #key?" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testconfig ).and_return( false )
		expect( config ).to receive( :respond_to? ).with( :key? ).and_return( true )
		expect( config ).to receive( :respond_to? ).with( :[] ).and_return( true )
		expect( config ).to receive( :key? ).with( :testconfig ).and_return( true )
		expect( config ).to receive( :[] ).with( :testconfig ).and_return( :a_config_section )

		expect( klass ).to receive( :configure ).with( :a_config_section )
		Configurability.configure_objects( config )
	end


	it "passes nil to the configure method if the config doesn't respond to the section " +
	   "name or the index operator" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testconfig ).and_return( false )
		expect( config ).to receive( :respond_to? ).with( :[] ).and_return( false )

		expect( klass ).to receive( :configure ).with( nil )

		Configurability.configure_objects( config )
	end


	it "tries the config key as a String if calling it with the Symbol returns nil" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testconfig ).and_return( false )
		expect( config ).to receive( :respond_to? ).with( :key? ).and_return( true )
		expect( config ).to receive( :respond_to? ).with( :[] ).and_return( true )
		expect( config ).to receive( :key? ).with( :testconfig ).and_return( false )
		expect( config ).to receive( :key? ).with( 'testconfig' ).and_return( true )
		expect( config ).to receive( :[] ).with( :testconfig ).and_return( nil )
		expect( config ).to receive( :[] ).with( 'testconfig' ).and_return( :a_config_section )

		expect( klass ).to receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end


	it "can be used to configure plain objects, too" do
		object = Object.new
		object.extend( Configurability )
		object.config_key = :testobjconfig

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testobjconfig ).and_return( true )
		expect( config ).to receive( :testobjconfig ).and_return( :a_config_section )

		expect( object ).to receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end


	it "configures classes that have inherited Configurability and set a different config_key" do
		klass = Class.new do
			extend Configurability
			config_key :testconfig
		end
		subclass = Class.new( klass ) do
			config_key :subconfig
		end

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testconfig ).and_return( true )
		expect( config ).to receive( :testconfig ).and_return( :a_config_section )
		expect( config ).to receive( :respond_to? ).with( :subconfig ).and_return( true )
		expect( config ).to receive( :subconfig ).and_return( :a_sub_config_section )

		expect( subclass ).to receive( :configure ).with( :a_sub_config_section )

		Configurability.configure_objects( config )
	end


	it "uses the object's name for its config key if it has one and hasn't specified a key " +
	   "directly" do
		object = Object.new
		def object.name; "testobjconfig"; end
		object.extend( Configurability )

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :testobjconfig ).and_return( true )
		expect( config ).to receive( :testobjconfig ).and_return( :a_config_section )

		expect( object ).to receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end


	it "normalizes the object's name before using it" do
		object = Object.new
		def object.name; "Test Obj-Config"; end
		object.extend( Configurability )

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :test_obj_config ).and_return( true )
		expect( config ).to receive( :test_obj_config ).and_return( :a_config_section )

		expect( object ).to receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end


	it "uses the object's class's name for its config key if it doesn't have a name and " +
	   "hasn't specified a key directly" do
		object = Object.new
		object.extend( Configurability )

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :object ).and_return( true )
		expect( config ).to receive( :object ).and_return( :a_config_section )

		expect( object ).to receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end


	it "uses only the last part of a class's name if it is namespaced" do
		module My
			class DbObject
				extend Configurability
			end
		end

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :dbobject ).and_return( true )
		expect( config ).to receive( :dbobject ).and_return( :a_config_section )

		expect( My::DbObject ).to receive( :configure ).with( :a_config_section )

		Configurability.configure_objects( config )
	end


	it "uses the 'anonymous' key if the object doesn't have a name, and its class is " +
	   "anonymous, and it hasn't specified a key directly" do
		objectclass = Class.new
		object = objectclass.new
		object.extend( Configurability )

		config = double( "configuration object" )
		expect( config ).to receive( :respond_to? ).with( :anonymous ).and_return( true )
		expect( config ).to receive( :anonymous ).and_return( :a_config_section )

		expect( object ).to receive( :configure ).with( :a_config_section )

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
			expect( Configurability.loaded_config ).to equal( @config )
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

			expect( object.config ).to eq( :yes )
		end


		it "defers configuration until after an object has defined a #configure method if " +
		   "it adds Configurability before declaring one" do
			objectclass = Class.new do
				extend Configurability
				config_key :postconfig
				def self::configure( config ); @config = config; end
				class << self; attr_reader :config; end
			end

			expect( objectclass.config ).to eq( :yes )
		end


		it "doesn't reconfigure objects that have already been configured unless the config changes" do
			first_objectclass = Class.new do
				extend Configurability
				config_key :postconfig
				def self::configure( config ); @configs ||= []; @configs << config; end
				def self::inherited( subclass ); subclass.instance_variable_set(:@configs, []); super; end
				class << self; attr_reader :configs; end
			end

			second_objectclass = Class.new( first_objectclass ) do
				extend Configurability
				config_key :postconfig
				def self::configure( config ); @configs ||= []; @configs << config; end
			end

			third_objectclass = Class.new( second_objectclass ) do
				extend Configurability
				config_key :postconfig
				def self::configure( config ); @configs ||= []; @configs << config; end
			end

			expect( first_objectclass.configs ).to eq([ @config[:postconfig] ])
			expect( second_objectclass.configs ).to eq([ nil, @config[:postconfig] ])
			expect( third_objectclass.configs ).to eq([ nil, @config[:postconfig] ])
		end

	end


	describe "defaults hash" do

		it "can generate a Hash of defaults for all objects with Configurability" do
			expect(Configurability.gather_defaults).to be_a( Hash )
		end


		it "fetches defaults from a CONFIG_DEFAULTS constant if the object defines one" do
			klass = Class.new do
				extend Configurability
				config_key :testconfig
				self::CONFIG_DEFAULTS = { :one => 1, :types => {:one => true} }
				Configurability.log.debug "Defaults: %p" % [ self.defaults ]
			end

			defaults = Configurability.gather_defaults

			expect( defaults ).to include( :testconfig )
			expect( defaults[:testconfig] ).to eq( klass.const_get(:CONFIG_DEFAULTS) )
			expect( defaults[:testconfig] ).to_not be( klass.const_get(:CONFIG_DEFAULTS) )
		end


		it "fetches defaults from a DEFAULT_CONFIG constant if the object defines one" do
			klass = Class.new do
				extend Configurability
				config_key :testconfig
				self::DEFAULT_CONFIG = { :two => 2, :types => {:two => true} }
			end

			defaults = Configurability.gather_defaults

			expect( defaults ).to include( :testconfig )
			expect( defaults[:testconfig] ).to eq( klass.const_get(:DEFAULT_CONFIG) )
			expect( defaults[:testconfig] ).to_not be( klass.const_get(:DEFAULT_CONFIG) )
		end


		it "fetches defaults from a #defaults method if the object implements one" do
			klass = Class.new do
				extend Configurability
				config_key :otherconfig
				def self::defaults; { :other => true }; end
			end

			defaults = Configurability.gather_defaults

			expect( defaults ).to include( :otherconfig )
			expect( defaults[:otherconfig] ).to eq( klass.defaults )
			expect( defaults[:otherconfig] ).to_not be( klass.defaults )
		end


		it "can return a Configurability::Config object with defaults, too" do
			klass1 = Class.new do
				extend Configurability
				config_key :testconfig
				self::CONFIG_DEFAULTS = { :one => 1, :types => {:one => true} }
			end
			klass2 = Class.new do
				extend Configurability
				config_key :testconfig
				self::DEFAULT_CONFIG = { :two => 2, :types => {:two => true} }
			end
			klass3 = Class.new do
				extend Configurability
				config_key :otherconfig
				def self::defaults; { :other => true }; end
			end

			config = Configurability.default_config

			expect( config ).to be_a( Configurability::Config )
			expect( config.testconfig.one ).to eq( 1 )
			expect( config.testconfig.two ).to eq( 2 )
			expect( config.testconfig.types.one ).to be_truthy()
			expect( config.testconfig.types.two ).to be_truthy()
			expect( config.otherconfig.other ).to be_truthy()
		end


		it "returns defaults for an object that inherits from a class with Configurability" do
			klass = Class.new do
				extend Configurability
				config_key :testconfig
				self::CONFIG_DEFAULTS = { :one => 1, :types => {:one => true} }
				Configurability.log.debug "Defaults: %p" % [ self.defaults ]
			end
			subclass = Class.new( klass ) do
				config_key :spanishconfig
				self::CONFIG_DEFAULTS = { :uno => 1 }
			end

			config = Configurability.default_config

			expect( config ).to respond_to( :spanishconfig )
			expect( config.spanishconfig.uno ).to eq( 1 )
		end

	end

end

# vim: set nosta noet ts=4 sw=4:
