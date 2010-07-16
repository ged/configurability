#!/usr/bin/env ruby

require 'tmpdir'
require 'pathname'
require 'forwardable'
require 'yaml'
require 'logger'

require 'configurability'

# A configuration object class for systems with Configurability
# 
#@author Michael Granger <ged@FaerieMUD.org>
#@author Mahlon E. Smith <mahlon@martini.nu>
class Configurability::Config
	extend Forwardable


	#############################################################
	###	C L A S S   M E T H O D S
	#############################################################

	### Read and return a Configurability::Config object from the given file or
	### configuration source.
	### @param [String] path      the path to the config file
	### @param [Hash]   defaults  a Hash of default config values which will be
	###                           used if the config at +path+ doesn't override
	###                           them.
	def self::load( path, defaults=nil )
		path = Pathname( path ).expand_path
		source = path.read
		Configurability.log.debug "Read %d bytes from %s" % [ source.length, path ]
		return new( source, path, defaults )
	end


	### Recursive hash-merge function. Used as the block argument to a Hash#merge.
	### @param [Symbol]  key     the key that's in conflict
	### @param [Object]  oldval  the value in the original Hash
	### @param [Object]  newval  the value in the Hash being merged
	def self::merge_complex_hashes( key, oldval, newval )
		return oldval.merge( newval, &method(:merge_complex_hashes) ) if
			oldval.is_a?( Hash ) && newval.is_a?( Hash )
		return newval
	end



	#############################################################
	###	I N S T A N C E   M E T H O D S
	#############################################################

	### Create a new Configurability::Config object. If the optional +source+ argument
	### is specified, parse the config from it.
	### 
	### @param []
	### @param []
	### @param []
	def initialize( source=nil, name=nil, defaults=nil, &block )

		if source
			@struct = self.make_configstruct_from_source( source, defaults )
		elsif defaults
			confighash = Marshal.load( Marshal.dump(defaults) )
			@struct = Configurability::Config::Struct.new( confighash )
		else
			@struct = Configurability::Config::Struct.new
		end

		@time_created    = Time.now
		@name            = name.to_s if name

		self.instance_eval( &block ) if block
	end


	######
	public
	######

	# Define delegators to the inner data structure
	def_delegators :@struct, :to_hash, :to_h, :member?, :members, :merge,
		:merge!, :each, :[], :[]=

	# The underlying config data structure
	attr_reader :struct

	# The time the configuration was loaded
	attr_accessor :time_created

	# The name of the associated record stored on permanent storage for this
	# configuration.
	attr_accessor :name


	### Install this config object in any objects that have added
	### Configurability.
	def install
		Configurability.configure_objects( self )
	end


	### Return the config object as a YAML hash
	def dump
		strhash = stringify_keys( self.to_h )
		return YAML.dump( strhash )
	end


	### Write the configuration object using the specified name and any
	### additional +args+.
	def write( name=@name, *args )
		raise ArgumentError,
			"No name associated with this config." unless name
		File.open( name, File::WRONLY|File::CREAT|File::TRUNC ) do |ofh|
			ofh.print( self.dump )
		end
	end


	### Returns +true+ for methods which can be autoloaded
	def respond_to?( sym )
		return true if @struct.member?( sym.to_s.sub(/(=|\?)$/, '').to_sym )
		super
	end


	### Returns +true+ if the configuration has changed since it was last
	### loaded, either by setting one of its members or changing the file
	### from which it was loaded.
	def changed?
		return self.changed_reason ? true : false
	end


	### If the configuration has changed, return the reason. If it hasn't,
	### returns nil.
	def changed_reason
		if @struct.dirty?
			return "Struct was modified"
		end

		if self.name && self.is_older_than?( self.name )
			return "Config source (%s) has been updated since %s" %
				[ self.name, self.time_created ]
		end

		return nil
	end


	### Return +true+ if the specified +file+ is newer than the time the receiver
	### was created.
	def is_older_than?( file )
		return false unless File.exists?( file )
		st = File.stat( file )
		Configurability.log.debug "File mtime is: %s, comparison time is: %s" %
			[ st.mtime, @time_created ]
		return st.mtime > @time_created
	end


	### Reload the configuration from the original source if it has
	### changed. Returns +true+ if it was reloaded and +false+ otherwise.
	def reload
		return false unless @name

		self.time_created = Time.now
		source = File.read( @name )
		@struct = self.make_configstruct_from_source( source )

		self.install
	end



	#########
	protected
	#########


	### Read in the specified +filename+ and return a config struct.
	### @param [String]  source  the YAML source to be converted
	### @return [Configurability::Config::Struct]  the converted config struct
	def make_configstruct_from_source( source, defaults=nil )
		defaults ||= {}
		mergefunc = Configurability::Config.method( :merge_complex_hashes )
		hash = YAML.load( source )
		ihash = symbolify_keys( untaint_values(hash) )
		mergedhash = defaults.merge( ihash, &mergefunc )

		return Configurability::Config::Struct.new( mergedhash )
	end


	### Handle calls to struct-members
	def method_missing( sym, *args )
		key = sym.to_s.sub( /(=|\?)$/, '' ).to_sym

		self.class.class_eval %{
			def #{key}; @struct.#{key}; end
			def #{key}=(arg); @struct.#{key} = arg; end
			def #{key}?; @struct.#{key}?; end
		}

		return self.method( sym ).call( *args )
	end


	#######
	private
	#######

	### Return a copy of the specified +hash+ with all of its values
	### untainted.
	def untaint_values( hash )
		newhash = {}
		hash.each do |key,val|
			case val
			when Hash
				newhash[ key ] = untaint_values( hash[key] )

			when Array
				newval = val.collect {|v| v.dup.untaint}
				newhash[ key ] = newval

			when NilClass, TrueClass, FalseClass, Numeric, Symbol
				newhash[ key ] = val

			else
				newval = val.dup
				newval.untaint
				newhash[ key ] = newval
			end
		end
		return newhash
	end


	### Return a duplicate of the given +hash+ with its identifier-like keys
	### transformed into symbols from whatever they were before.
	def symbolify_keys( hash )
		newhash = {}
		hash.each do |key,val|
			if val.is_a?( Hash )
				newhash[ key.to_sym ] = symbolify_keys( val )
			else
				newhash[ key.to_sym ] = val
			end
		end

		return newhash
	end


	### Return a version of the given +hash+ with its keys transformed
	### into Strings from whatever they were before.
	def stringify_keys( hash )
		newhash = {}
		hash.each do |key,val|
			if val.is_a?( Hash )
				newhash[ key.to_s ] = stringify_keys( val )
			else
				newhash[ key.to_s ] = val
			end
		end

		return newhash
	end



	#############################################################
	###	I N T E R I O R   C L A S S E S
	#############################################################

	### Hash-wrapper that allows struct-like accessor calls on nested
	### hashes.
	class Struct
		extend Forwardable
		include Enumerable

		# Mask most of Kernel's methods away so they don't collide with
		# config values.
		Kernel.methods(false).each {|meth|
			next unless method_defined?( meth )
			next if /^(?:__|dup|object_id|inspect|class|raise|method_missing)/.match( meth )
			undef_method( meth )
		}


		### Create a new ConfigStruct from the given +hash+.
		def initialize( hash={} )
			@hash = hash.dup
			@dirty = false
		end


		######
		public
		######

		# Forward some methods to the internal hash
		def_delegators :@hash, :keys, :key?, :values, :value?, :[], :[]=, :length,
		    :empty?, :clear, :each

		# Let :each be called as :each_section, too
		alias_method :each_section, :each


		### Mark the struct has having been modified since its creation.
		def mark_dirty
			@dirty = true
		end


		### Returns +true+ if the ConfigStruct or any of its sub-structs
		### have changed since it was created.
		def dirty?
			return true if @dirty
			return true if @hash.values.find do |obj|
				obj.respond_to?( :dirty? ) && obj.dirty?
			end
		end


		### Return the receiver's values as a (possibly multi-dimensional)
		### Hash with String keys.
		def to_hash
			rhash = {}
			@hash.each {|k,v|
				case v
				when Configurability::Config::Struct
					rhash[k] = v.to_h
				when NilClass, FalseClass, TrueClass, Numeric
					# No-op (can't dup)
					rhash[k] = v
				when Symbol
					rhash[k] = v.to_s
				else
					rhash[k] = v.dup
				end
			}
			return rhash
		end
		alias_method :to_h, :to_hash


		### Return +true+ if the receiver responds to the given
		### method. Overridden to grok autoloaded methods.
		def respond_to?( sym, priv=false )
			key = sym.to_s.sub( /(=|\?)$/, '' ).to_sym
			return true if @hash.key?( key )
			super
		end


		### Returns an Array of Symbols, one for each of the struct's members.
		def members
			return @hash.keys
		end


		### Returns +true+ if the given +name+ is the name of a member of
		### the receiver.
		def member?( name )
			return @hash.key?( name.to_s.to_sym )
		end


		### Merge the specified +other+ object with this config struct. The
		### +other+ object can be either a Hash, another Configurability::Config::Struct, or an
		### Configurability::Config.
		def merge!( other )
			mergefunc = Configurability::Config.method( :merge_complex_hashes )

			case other
			when Hash
				@hash = self.to_h.merge( other, &mergefunc )

			when Configurability::Config::Struct
				@hash = self.to_h.merge( other.to_h, &mergefunc )

			when Configurability::Config
				@hash = self.to_h.merge( other.struct.to_h, &mergefunc )

			else
				raise TypeError,
					"Don't know how to merge with a %p" % other.class
			end

			# :TODO: Actually check to see if anything has changed?
			@dirty = true

			return self
		end


		### Return a new Configurability::Config::Struct which is the result of merging the
		### receiver with the given +other+ object (a Hash or another
		### Configurability::Config::Struct).
		def merge( other )
			self.dup.merge!( other )
		end



		#########
		protected
		#########

		### Handle calls to key-methods
		def method_missing( sym, *args )
			key = sym.to_s.sub( /(=|\?)$/, '' ).to_sym

			# Create new methods for this key
			reader    = self.create_member_reader( key )
			writer    = self.create_member_writer( key )
			predicate = self.create_member_predicate( key )

			# ...and install them
			self.class.send( :define_method, key, &reader )
			self.class.send( :define_method, "#{key}=", &writer )
			self.class.send( :define_method, "#{key}?", &predicate )

			# Now jump to the requested method in a way that won't come back through
			# the proxy method if something didn't get defined
			self.method( sym ).call( *args )
		end


		### Create a reader method for the specified +key+ and return it.
		### @param [Symbol] key  the config key to create the reader method body for
		### @return [Proc] the body of the new method
		def create_member_reader( key )
			return lambda do

				# Create the config struct on the fly for subsections
				if !@hash.key?( key )
					@hash[ key ] = self.class.new
				elsif @hash[ key ].is_a?( Hash )
					@hash[ key ] = self.class.new( @hash[key] )
				end

				@hash[ key ]
			end
		end


		### Create a predicate method for the specified +key+ and return it.
		### @param [Symbol] key  the config key to create the predicate method body for
		### @return [Proc] the body of the new method
		def create_member_predicate( key )
			return lambda { @hash[key] ? true : false }
		end


		### Create a writer method for the specified +key+ and return it.
		### @param [Symbol] key  the config key to create the writer method body for
		### @return [Proc] the body of the new method
		def create_member_writer( key )
			return lambda do |val|
				self.mark_dirty if @hash[ key ] != val
				@hash[ key ] = val
			end
		end

	end # class Struct

end # class Configurability::Config

# vim: set nosta noet ts=4 sw=4:

