#!/usr/bin/env ruby

require 'configurability'
require 'rspec'

share_examples_for "an object with Configurability" do

	let( :config ) do
		described_class
	end


	it "is extended with Configurability" do
		Configurability.configurable_objects.should include( self.config )
	end

	it "has a Symbol config key" do
		self.config.config_key.should be_a( Symbol )
	end

	it "has a config key that is a reasonable section name" do
		self.config.config_key.to_s.should =~ /^[a-z][a-z0-9]*$/i
	end

end

