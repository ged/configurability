#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'tempfile'
require 'logger'
require 'fileutils'

require 'spec'
require 'spec/lib/helpers'

require 'configurability/config'



#####################################################################
###	C O N T E X T S
#####################################################################
describe Configurability::Config do
	include Configurability::SpecHelpers

	TEST_CONFIG = %{
	---
	section:
	  subsection:
	    subsubsection: value
	listsection:
	  - list
	  - values
	  - are
	  - neat
	mergekey: Yep.
	textsection: |-
	  With some text as the value
	  ...and another line.
	}.gsub(/^\t/, '')


	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	it "can dump itself as YAML" do
		Configurability::Config.new.dump.should == "--- {}\n\n"
	end

	it "returns nil as its change description" do
		Configurability::Config.new.changed_reason.should be_nil()
	end

	it "autogenerates accessors for non-existant struct members" do
		config = Configurability::Config.new
		config.plugins.filestore.maxsize = 1024
		config.plugins.filestore.maxsize.should == 1024
	end


	describe "created with a source" do

		before(:each) do
			@config = Configurability::Config.new( TEST_CONFIG )
		end

		it "responds to methods which are the same as struct members" do
			@config.should respond_to( :section )
			@config.section.should respond_to( :subsection )
			@config.should_not respond_to( :pork_sausage )
		end

		it "should contain values specified in the source" do
			# section:
			#   subsection:
			#     subsubsection: value
			@config.section.subsection.subsubsection.should == 'value'

			# listsection:
			#   - list
			#   - values
			#   - are
			#   - neat
			@config.listsection.should == %w[list values are neat]

			# mergekey: Yep.
			@config.mergekey.should == 'Yep.'

			# textsection: |-
			#   With some text as the value
			#   ...and another line.
			@config.textsection.should == "With some text as the value\n...and another line."
		end

		it "can return struct members as an Array of Symbols" do
			@config.members.should be_an_instance_of( Array )
			@config.members.should have_at_least( 4 ).things
			@config.members.each do |member|
				member.should be_an_instance_of( Symbol)
			end
		end

		it "is able to iterate over sections" do
			@config.each do |key, struct|
				key.should be_an_instance_of( Symbol)
			end
		end

		it "should dump values specified in the source" do
			@config.dump.should =~ /^section:/
			@config.dump.should =~ /^\s+subsection:/
			@config.dump.should =~ /^\s+subsubsection:/
			@config.dump.should =~ /^- list/
		end

	end


	# saving if changed since loaded
	describe " whose internal values have been changed since loaded" do
		before(:each) do
			@config = Configurability::Config.new( TEST_CONFIG )
			@config.section.subsection.anothersection = 11451
		end


		### Specifications
		it "should report that it is changed" do
			@config.changed?.should == true
		end

		it "should report that its internal struct was modified as the reason for the change" do
			@config.changed_reason.should =~ /struct was modified/i
		end

	end


	# loading from a file
	describe " loaded from a file" do
		before(:all) do
			@tmpfile = Tempfile.new( 'test.conf', '.' )
			@tmpfile.print( TEST_CONFIG )
			@tmpfile.close
		end

		after(:all) do
			@tmpfile.delete
		end


		before(:each) do
			@config = Configurability::Config.load( @tmpfile.path )
		end


		### Specifications
		it "should know which file it was loaded from" do
			@config.name.should == File.expand_path( @tmpfile.path )
		end

		it "should write itself back to the same file by default" do
			@config.port = 114411
			@config.write
			otherconfig = Configurability::Config.load( @tmpfile.path )

			otherconfig.port.should == 114411
		end
	end


	# reload if file changes
	describe " whose file changes after loading" do
		before(:all) do
			@tmpfile = Tempfile.new( 'test.conf', '.' )
			@tmpfile.print( TEST_CONFIG )
			@tmpfile.close
		end

		after(:all) do
			@tmpfile.delete
		end


		before(:each) do
			@config = Configurability::Config.load( @tmpfile.path )
			newdate = Time.now + 3600
			File.utime( newdate, newdate, @tmpfile.path )
		end


		### Specifications
		it "should report that it is changed" do
			@config.should be_changed
		end

		it "should report that its source was updated as the reason for the change" do
			@config.changed_reason.should =~ /source.*updated/i
		end

		it "should be able to be reloaded" do
			Configurability.should_receive( :configure_objects ).with( @config )
			@config.reload
		end

	end


	# merging
	describe " created by merging two other configs" do
		before(:each) do
			@config1 = Configurability::Config.new
			@config2 = Configurability::Config.new( TEST_CONFIG )
			@merged = @config1.merge( @config2 )
		end


		### Specifications
		it "should contain values from both" do
			@merged.mergekey.should == @config2.mergekey
		end
	end

end

# vim: set nosta noet ts=4 sw=4:
