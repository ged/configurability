#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

if ENV['COVERAGE']
	warn "Coverage doesn't work so great under non-MRI interpreters." if RUBY_ENGINE != "ruby"
	require 'simplecov'
	SimpleCov.start { add_filter '/spec/' }
end

require 'rspec'

require 'logger'
require 'erb'
require 'yaml'

require 'loggability/spechelpers'

require 'configurability'


RSpec.configure do |config|
	config.mock_with( :rspec )
	config.include( Loggability::SpecHelpers )
	config.treat_symbols_as_metadata_keys_with_true_values = true

	config.filter_run_excluding :only_ruby_19 if RUBY_VERSION < '1.9.2'

end

# vim: set nosta noet ts=4 sw=4:

