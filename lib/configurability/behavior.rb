#!/usr/bin/env ruby

require 'configurability'
require 'spec'

share_examples_for "an object with Configurability" do

	before( :each ) do
		fail "this behavior expects the object under test to be in the @object " +
		     "instance variable" unless defined?( @object )
	end

	it "is extended with Configurability" do
		Configurability.configurable_objects.should include( @object )
	end

	it "has a Symbol config key" do
		@object.config_key.should be_a( Symbol )
	end

	it "has a config key that is a reasonable section name" do
		@object.config_key.to_s.should =~ /^[a-z][a-z0-9]*$/i
	end

end

