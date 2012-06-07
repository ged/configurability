#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'logger'
require 'fileutils'
require 'rspec'

require 'spec/lib/helpers'

require 'configurability/config'



#####################################################################
###	C O N T E X T S
#####################################################################
describe Configurability::Config do

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

	after( :each ) do
		Configurability.configurable_objects.clear
		Configurability.reset
	end

	after( :all ) do
		reset_logging()
	end

	it "can dump itself as YAML" do
		Configurability::Config.new.dump.strip.should == "--- {}"
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

	it "autoloads predicates for its members" do
		config = Configurability::Config.new( TEST_CONFIG )
		config.mergekey?.should be_true()
		config.mergemonkey?.should be_false()
		config.section?.should be_true()
		config.section.subsection?.should be_true()
		config.section.subsection.subsubsection?.should be_true()
		config.section.monkeysubsection?.should be_false()
	end


	context "a config with nil keys" do

		NIL_KEY_CONFIG = %{
		---
		trap_on:
		  "low disk space alert":
		    ~:
		      notepad:
		        patterns:
		          - pattern1
		          - pattern2
		}.gsub(/^\t{2}/, '')

		before( :each ) do
			@config = Configurability::Config.new( NIL_KEY_CONFIG )
		end

		it "doesn't raise a NoMethodError when loading (issue #1)" do
			@config[:trap_on]['low disk space alert'][nil][:notepad][:patterns].
				should == [ 'pattern1', 'pattern2' ]
		end

		it "knows that it has a nil member" do
			@config[:trap_on]['low disk space alert'].should have_member( nil )
		end

	end


	context "created with in-memory YAML source" do

		before( :each ) do
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
	context " whose internal values have been changed since loaded" do
		before( :each ) do
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
	context " loaded from a file" do
		before( :all ) do
			filename = Dir::Tmpname.make_tmpname( './test', '.conf' )
			@tmpfile = Pathname( filename )
			@tmpfile.open( 'w', 0644 ) {|io| io.print(TEST_CONFIG) }
		end

		after( :all ) do
			@tmpfile.unlink
		end

		before( :each ) do
			@config = Configurability::Config.load( @tmpfile.to_s )
		end


		### Specifications
		it "remembers which file it was loaded from" do
			@config.path.should == @tmpfile.expand_path
		end

		it "writes itself back to the same file by default" do
			@config.port = 114411
			@config.write
			otherconfig = Configurability::Config.load( @tmpfile.to_s )

			otherconfig.port.should == 114411
		end

		it "can be written to a different file" do
			path = Dir::Tmpname.make_tmpname( './another-', '.config' )

			@config.write( path )
			File.read( path ).should =~ /section:\n  subsection/

			File.unlink( path )
		end

		it "includes the name of the file in its inspect output" do
			@config.inspect.should include( File.basename(@tmpfile.to_s) )
		end

		it "yields itself if a block is given at load-time" do
			yielded_self = nil
			config = Configurability::Config.load( @tmpfile.to_s ) do
				yielded_self = self
			end
			yielded_self.should equal( config )
		end

		it "passes itself as the block argument if a block of arity 1 is given at load-time" do
			arg_self = nil
			yielded_self = nil
			config = Configurability::Config.load( @tmpfile.to_s ) do |arg|
				yielded_self = self
				arg_self = arg
			end
			yielded_self.should_not equal( config )
			arg_self.should equal( config )
		end

		it "doesn't re-read its source file if it hasn't changed" do
			@config.path.should_not_receive( :read )
			Configurability.should_not_receive( :configure_objects )
			@config.reload.should be_false()
		end
	end


	# reload if file changes
	context " whose file changes after loading" do
		before( :all ) do
			filename = Dir::Tmpname.make_tmpname( './test', '.conf' )
			@tmpfile = Pathname( filename )
			@tmpfile.open( 'w', 0644 ) {|io| io.print(TEST_CONFIG) }
		end

		after( :all ) do
			@tmpfile.unlink
		end


		before( :each ) do
			old_date = Time.now - 3600
			File.utime( old_date, old_date, @tmpfile.to_s )
			@config = Configurability::Config.load( @tmpfile.to_s )
			now = Time.now + 10
			File.utime( now, now, @tmpfile.to_s )
		end


		### Specifications
		it "reports that it is changed" do
			@config.should be_changed
		end

		it "reports that its source was updated as the reason for the change" do
			@config.changed_reason.should =~ /source.*updated/i
		end

		it "re-reads its file when reloaded" do
			@config.path.should_receive( :read ).and_return( TEST_CONFIG )
			Configurability.should_receive( :configure_objects ).with( @config )
			@config.reload.should be_true()
		end

		it "reapplies its defaults when reloading" do
			config = Configurability::Config.load( @tmpfile.to_s, :defaultskey => 8 )
			config.reload
			config.defaultskey.should == 8
		end
	end


	# merging
	context " created by merging two other configs" do
		before( :each ) do
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
