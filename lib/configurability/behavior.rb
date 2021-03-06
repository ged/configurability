#!/usr/bin/env ruby

require 'configurability'
require 'rspec'

RSpec.shared_examples "an object with Configurability" do

	it "is extended with Configurability" do
		expect( Configurability.configurable_objects ).to include( described_class )
	end

	it "has a Symbol config key" do
		expect( described_class.config_key ).to be_a( Symbol )
	end

	it "has a config key that is a reasonable section name" do
		expect( described_class.config_key.to_s ).to match( /^[a-z]\w*$/i )
	end

end

