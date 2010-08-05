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

	it "merges values loaded from the config with any defaults given" do
		config = Configurability::Config.new( TEST_CONFIG, :defaultkey => "Oh yeah." )
		config.defaultkey.should == "Oh yeah."
	end

	it "yields itself if a block is given at creation" do
		yielded_self = nil
		config = Configurability::Config.new { yielded_self = self }
		yielded_self.should equal( config )
	end

	it "passes itself as the block argument if a block of arity 1 is given at creation" do
		arg_self = nil
		yielded_self = nil
		config = Configurability::Config.new do |arg|
			yielded_self = self
			arg_self = arg
		end
		yielded_self.should_not equal( config )
		arg_self.should equal( config )
	end

	it "supports both Symbols and Strings for Hash-like access" do
		config = Configurability::Config.new( TEST_CONFIG )
		config[:section]['subsection'][:subsubsection].should == 'value'
	end


	describe "created with in-memory YAML source" do

		before(:each) do
			@config = Configurability::Config.new( TEST_CONFIG )
		end

		it "responds to methods which are the same as struct members" do
			@config.should respond_to( :section )
			@config.section.should respond_to( :subsection )
			@config.should_not respond_to( :pork_sausage )
		end

		it "contains values specified in the source" do
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

		it "returns struct members as an Array of Symbols" do
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

		it "dumps values specified in the source" do
			@config.dump.should =~ /^section:/
			@config.dump.should =~ /^\s+subsection:/
			@config.dump.should =~ /^\s+subsubsection:/
			@config.dump.should =~ /^- list/
		end

		it "provides a human-readable description of itself when inspected" do
			@config.inspect.should =~ /4 sections/i
			@config.inspect.should =~ /mergekey/
			@config.inspect.should =~ /textsection/
			@config.inspect.should =~ /from memory/i
		end

		it "raises an exception when reloaded" do
			expect {
				@config.reload
			}.to raise_exception( RuntimeError, /can't reload from an in-memory source/i )
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
		it "remembers which file it was loaded from" do
			@config.path.should == Pathname( @tmpfile.path ).expand_path
		end

		it "writes itself back to the same file by default" do
			@config.port = 114411
			@config.write
			otherconfig = Configurability::Config.load( @tmpfile.path )

			otherconfig.port.should == 114411
		end

		it "includes the name of the file in its inspect output" do
			@config.inspect.should include( File.basename(@tmpfile.path) )
		end

		it "yields itself if a block is given at load-time" do
			yielded_self = nil
			config = Configurability::Config.load( @tmpfile.path ) do
				yielded_self = self
			end
			yielded_self.should equal( config )
		end

		it "passes itself as the block argument if a block of arity 1 is given at load-time" do
			arg_self = nil
			yielded_self = nil
			config = Configurability::Config.load( @tmpfile.path ) do |arg|
				yielded_self = self
				arg_self = arg
			end
			yielded_self.should_not equal( config )
			arg_self.should equal( config )
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
			old_date = Time.now - 3600
			File.utime( old_date, old_date, @tmpfile.path )
			@config = Configurability::Config.load( @tmpfile.path )
			now = Time.now + 10
			File.utime( now, now, @tmpfile.path )
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

		it "reapplies its defaults when reloading" do
			config = Configurability::Config.load( @tmpfile.path, :defaultskey => 8 )
			config.reload
			config.defaultskey.should == 8
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