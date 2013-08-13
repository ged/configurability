#!/usr/bin/env ruby

require 'configurability'
require 'rspec'

share_examples_for "an object with Configurability" do

	it "is extended with Configurability" do
		expect( Configurability.configurable_objects ).to include( described_class )
	end

	it "has a Symbol config key" do
		expect( described_class.config_key ).to be_a( Symbol )
	end

	it "has a config key that is a reasonable section name" do
		expect( described_class.config_key.to_s ).to match( /^[a-z][a-z0-9]*$/i )
	end

end

