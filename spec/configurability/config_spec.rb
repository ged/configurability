#!/usr/bin/env ruby

require 'helpers'

require 'logger'
require 'fileutils'
require 'rspec'

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
	listofints:
	  - 1
	  - 2
	  - 3
	  - 5
	  - 7
	mergekey: Yep.
	textsection: |-
	  With some text as the value
	  ...and another line.
	}.gsub(/^\t/, '')



	after( :each ) do
		Configurability.configurable_objects.clear
		Configurability.reset
	end


	it "can dump itself as YAML" do
		expect( described_class.new.dump.strip ).to eq( "--- {}" )
	end

	it "returns nil as its change description" do
		expect( described_class.new.changed_reason ).to be_nil()
	end

	it "autogenerates accessors for non-existant struct members" do
		config = described_class.new
		config.plugins ||= {}
		config.plugins.filestore ||= {}
		config.plugins.filestore.maxsize = 1024

		expect( config.plugins.filestore.maxsize ).to eq( 1024 )
	end

	it "merges values loaded from the config with any defaults given" do
		config = described_class.new( TEST_CONFIG, :defaultkey => "Oh yeah." )

		expect( config.defaultkey ).to eq( "Oh yeah." )
	end

	it "symbolifies keys in defaults (issue #3)" do
		config = described_class.new( TEST_CONFIG, 'stringkey' => "String value." )

		expect( config.stringkey ).to eq( "String value." )
	end

	it "yields itself if a block is given at creation" do
		yielded_self = nil
		config = described_class.new { yielded_self = self }

		expect( yielded_self ).to equal( config )
	end

	it "passes itself as the block argument if a block of arity 1 is given at creation" do
		arg_self = nil
		yielded_self = nil
		config = described_class.new do |arg|
			yielded_self = self
			arg_self = arg
		end

		expect( yielded_self ).not_to equal( config )
		expect( arg_self ).to equal( config )
	end

	it "supports both Symbols and Strings for Hash-like access" do
		config = described_class.new( TEST_CONFIG )

		expect( config[:section]['subsection'][:subsubsection] ).to eq( 'value' )
	end

	it "autoloads predicates for its members" do
		config = described_class.new( TEST_CONFIG )

		expect( config.mergekey? ).to be_truthy()
		expect( config.mergemonkey? ).to be_falsey()
		expect( config.section? ).to be_truthy()
		expect( config.section.subsection? ).to be_truthy()
		expect( config.section.subsection.subsubsection? ).to be_truthy()
		expect( config.section.monkeysubsection? ).to be_falsey()
	end

	it "untaints values loaded from a config" do
		yaml = TEST_CONFIG.dup.taint
		config = described_class.new( yaml )
		expect( config.listsection.first ).to_not be_tainted
		expect( config.textsection ).to_not be_tainted
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

		let( :config ) { described_class.new(NIL_KEY_CONFIG) }

		it "doesn't raise a NoMethodError when loading (issue #1)" do
			val = config[:trap_on]['low disk space alert'][nil][:notepad][:patterns]
			expect( val ).to eq([ 'pattern1', 'pattern2' ])
		end

		it "knows that it has a nil member" do
			val = config[:trap_on]['low disk space alert']
			expect( val ).to have_member( nil )
		end

	end


	context "created with in-memory YAML source" do

		let( :config ) { described_class.new(TEST_CONFIG) }

		it "responds to methods which are the same as struct members" do
			expect( config ).to respond_to( :section )
			expect( config.section ).to respond_to( :subsection )
			expect( config ).not_to respond_to( :pork_sausage )
		end

		it "contains values specified in the source" do
			# section:
			#   subsection:
			#     subsubsection: value
			expect( config.section.subsection.subsubsection ).to eq( 'value' )

			# listsection:
			#   - list
			#   - values
			#   - are
			#   - neat
			expect( config.listsection ).to eq( %w[list values are neat] )

			# mergekey: Yep.
			expect( config.mergekey ).to eq( 'Yep.' )

			# textsection: |-
			#   With some text as the value
			#   ...and another line.
			expect( config.textsection ).to eq("With some text as the value\n...and another line.")
		end

		it "returns struct members as an Array of Symbols" do
			expect( config.members ).to be_an_instance_of( Array )
			expect( config.members.size ).to be >= 4
			config.members.each do |member|
				expect( member ).to be_an_instance_of( Symbol )
			end
		end

		it "is able to iterate over sections" do
			config.each do |key, struct|
				expect( key ).to be_an_instance_of( Symbol )
			end
		end

		it "dumps values specified in the source" do
			expect( config.dump ).to match( /^section:/ )
			expect( config.dump ).to match( /^\s+subsection:/ )
			expect( config.dump ).to match( /^\s+subsubsection:/ )
			expect( config.dump ).to match( /^- list/ )
		end

		it "provides a human-readable description of itself when inspected" do
			expect( config.inspect ).to match( /\d+ sections/i )
			expect( config.inspect ).to match( /mergekey/ )
			expect( config.inspect ).to match( /textsection/ )
			expect( config.inspect ).to match( /from memory/i )
		end

		it "raises an exception when reloaded" do
			expect {
				config.reload
			}.to raise_exception( RuntimeError, /can't reload from an in-memory source/i )
		end

	end


	# saving if changed since loaded
	context " whose internal values have been changed since loaded" do
		let( :config ) do
			config = described_class.new( TEST_CONFIG )
			config.section.subsection.anothersection = 11451
			config
		end


		it "should report that it is changed" do
			expect( config.changed? ).to be_truthy()
		end

		it "should report that its internal struct was modified as the reason for the change" do
			expect( config.changed_reason ).to match( /struct was modified/i )
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

		let( :config ) { described_class.load(@tmpfile.to_s) }


		### Specifications
		it "remembers which file it was loaded from" do
			expect( config.path ).to eq( @tmpfile.expand_path )
		end

		it "writes itself back to the same file by default" do
			config.port = 114411
			config.write
			otherconfig = described_class.load( @tmpfile.to_s )

			expect( otherconfig.port ).to eq( 114411 )
		end

		it "can be written to a different file" do
			begin
			path = Dir::Tmpname.make_tmpname( './another-', '.config' )

				config.write( path )
				expect( File.read(path) ).to match( /section: ?\n  subsection/ )
			ensure
				File.unlink( path ) if path
			end
		end

		it "includes the name of the file in its inspect output" do
			expect( config.inspect ).to include( File.basename(@tmpfile.to_s) )
		end

		it "yields itself if a block is given at load-time" do
			yielded_self = nil
			config = described_class.load( @tmpfile.to_s ) do
				yielded_self = self
			end
			expect( yielded_self ).to equal( config )
		end

		it "passes itself as the block argument if a block of arity 1 is given at load-time" do
			arg_self = nil
			yielded_self = nil
			config = described_class.load( @tmpfile.to_s ) do |arg|
				yielded_self = self
				arg_self = arg
			end

			expect( yielded_self ).not_to equal( config )
			expect( arg_self ).to equal( config )
		end

		it "doesn't re-read its source file if it hasn't changed" do
			expect( config.path ).not_to receive( :read )
			expect( Configurability ).not_to receive( :configure_objects )
			expect( config.reload ).to be_falsey()
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
			@config = described_class.load( @tmpfile.to_s )
			now = Time.now + 10
			File.utime( now, now, @tmpfile.to_s )
		end


		### Specifications
		it "reports that it is changed" do
			expect( @config ).to be_changed
		end

		it "reports that its source was updated as the reason for the change" do
			expect( @config.changed_reason ).to match( /source.*updated/i )
		end

		it "re-reads its file when reloaded" do
			expect( @config.path ).to receive( :read ).and_return( TEST_CONFIG )
			expect( Configurability ).to receive( :configure_objects ).with( @config )
			expect( @config.reload ).to be_truthy()
		end

		it "reapplies its defaults when reloading" do
			@config = described_class.load( @tmpfile.to_s, :defaultskey => 8 )
			@config.reload

			expect( @config.defaultskey ).to eq( 8 )
		end
	end


	# merging
	context " created by merging two other configs" do


		### Specifications
		it "contains values from both" do
			config1 = described_class.new
			config2 = described_class.new( TEST_CONFIG )
			merged = config1.merge(config2)

			expect( merged.mergekey ).to eq( config2.mergekey )
		end


		it "recursively merges shared sub-sections" do
			config1 = described_class.new( manager: {state_file: '/tmp/manager.state'} )
			config2 = described_class.new( manager: {port: 1200} )
			merged = config1.merge( config2 )

			expect( merged.manager.state_file ).to eq( '/tmp/manager.state' )
			expect( merged.manager.port ).to eq( 1200 )
		end

	end

end

# vim: set nosta noet ts=4 sw=4:
