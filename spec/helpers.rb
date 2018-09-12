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

require 'configurability/behavior'
require 'loggability/spechelpers'

require 'configurability'


RSpec.configure do |config|
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.order = 'random'
	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end
	config.warnings = true
	config.profile_examples = 5

	config.include( Loggability::SpecHelpers )
end

# vim: set nosta noet ts=4 sw=4:

