#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'simplecov'
require 'rspec'

require 'logger'
require 'erb'
require 'yaml'

SimpleCov.start do
	add_filter '/spec/'
end
require 'configurability'


### RSpec helper functions.
module Configurability::SpecHelpers

	###############
	module_function
	###############

	### Reset the logging subsystem to its default state.
	def reset_logging
		Loggability.formatter = nil
		Loggability.output_to( $stderr )
		Loggability.level = :fatal
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=:fatal )

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			logarray = []
			Thread.current['logger-output'] = logarray
			Loggability.output_to( logarray )
			Loggability.format_as( :html )
			Loggability.level = :debug
		else
			Loggability.level = level
		end
	end

end


RSpec.configure do |config|
	config.mock_with( :rspec )
	config.include( Configurability::SpecHelpers )
	config.treat_symbols_as_metadata_keys_with_true_values = true

	config.filter_run_excluding :only_ruby_19 if RUBY_VERSION < '1.9.2'

end

# vim: set nosta noet ts=4 sw=4:

