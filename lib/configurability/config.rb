#!/usr/bin/env ruby

require 'tmpdir'
require 'pathname'
require 'forwardable'
require 'yaml'
require 'logger'

require 'configurability'

# A configuration object class for systems with Configurability
# 
# @author Michael Granger <ged@FaerieMUD.org>
# @author Mahlon E. Smith <mahlon@martini.nu>
# 
# This class also delegates some of its methods to the underlying struct:
#
# @see Configurability::Config::Struct#to_hash
#      #to_hash (delegated to its internal Struct)
# @see Configurability::Config::Struct#member?
#      #member? (delegated to its internal Struct)
# @see Configurability::Config::Struct#members
#      #members (delegated to its internal Struct)
# @see Configurability::Config::Struct#merge
#      #merge (delegated to its internal Struct)
# @see Configurability::Config::Struct#merge!
#      #merge! (delegated to its internal Struct)
# @see Configurability::Config::Struct#each
#      #each (delegated to its internal Struct)
# @see Configurability::Config::Struct#[]
#      #[] (delegated to its internal Struct)
# @see Configurability::Config::Struct#[]=
#      #[]= (delegated to its internal Struct)
# 
class Configurability::Config
	extend Forwardable


	#############################################################
	###	C L A S S   M E T H O D S
	#############################################################

	### Read and return a Configurability::Config object from the file at the given +path+.
	### @param [String] path      the path to the config file
	### @param [Hash]   defaults  a Hash of default config values which will be
	###                           used if the config at +path+ doesn't override
	###                           them.
	def self::load( path, defaults=nil, &block )
		path = Pathname( path ).expand_path
		source = path.read
		Configurability.log.debug "Read %d bytes from %s" % [ source.length, path ]
		return new( source, path, defaults, &block )
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
	### @param [String] source           the YAML source of the configuration
	### @param [String, Pathname] path   the path to the config file (if loaded from a file)
	### @param [Hash] defaults           a Hash containing default values which the loaded values
	###                                  will be merged into.
	### @yield  A passed block will be evaluated with the config object as 'self' after
	###         the config is loaded.
	def initialize( source=nil, path=nil, defaults=nil, &block )

		# Shift the hash parameter if it shows up as the path
		if path.is_a?( Hash )
			defaults = path
			path = nil
		end

		# Make a deep copy of the defaults before loading so we don't modify
		# the argument
		@defaults     = Marshal.load( Marshal.dump(defaults) ) if defaults
		@time_created = Time.now
		@path         = path

		if source
			@struct = self.make_configstruct_from_source( source, @defaults )
		else
			@struct = Configurability::Config::Struct.new( @defaults )
		end

		if block
			Configurability.log.debug "Block arity is: %p" % [ block.arity ]

			# A block with an argument is called with the config as the argument
			# instead of instance_evaled
			case block.arity
			when 0, -1  # 1.9 and 1.8, respectively
				Configurability.log.debug "Instance evaling in the context of %p" % [ self ]
				self.instance_eval( &block )
			else
				block.call( self )
			end
		end
	end


	######
	public
	######

	# Define delegators to the inner data structure
	def_delegators :@struct, :to_hash, :to_h, :member?, :members, :merge,
		:merge!, :each, :[], :[]=

	# @return [Configurability::Config::Struct] The underlying config data structure
	attr_reader :struct

	# @return [Time] The time the configuration was loaded
	attr_accessor :time_created

	# @return [Pathname] the path to the config file, if loaded from a file
	attr_accessor :path


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
	def write( path=@path, *args )
		raise ArgumentError,
			"No name associated with this config." unless path
		path.open( File::WRONLY|File::CREAT|File::TRUNC ) do |ofh|
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
			Configurability.log.debug "Changed_reason: struct was modified"
			return "Struct was modified"
		end

		if self.path && self.is_older_than?( self.path )
			Configurability.log.debug "Source file (%s) has changed." % [ self.path ]
			return "Config source (%s) has been updated since %s" %
				[ self.path, self.time_created ]
		end

		return nil
	end


	### Return +true+ if the specified +file+ is newer than the time the receiver
	### was created.
	def is_older_than?( path )
		return false unless path.exist?
		st = path.stat
		Configurability.log.debug "File mtime is: %s, comparison time is: %s" %
			[ st.mtime, @time_created ]
		return st.mtime > @time_created
	end


	### Reload the configuration from the original source if it has
	### changed. Returns +true+ if it was reloaded and +false+ otherwise.
	### 
	def reload
		raise "can't reload from an in-memory source" unless self.path

		self.time_created = Time.now
		source = self.path.read
		@struct = self.make_configstruct_from_source( source, @defaults )

		self.install
	end


	### Return a human-readable, compact representation of the configuration
	### suitable for debugging.
	def inspect
		return "#<%s:0x%0x16 loaded from %s; %d sections: %s>" % [
			self.class.name,
			self.object_id * 2,
			self.path ? self.path : "memory",
			self.struct.members.length,
			self.struct.members.join( ', ' )
		]
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


		### Create a new ConfigStruct using the values from the given +hash+ if specified.
		### @param [Hash] hash  a hash of config values
		def initialize( hash=nil )
			hash ||= {}
			@hash = hash.dup
			@dirty = false
		end


		######
		public
		######

		# Forward some methods to the internal hash
		def_delegators :@hash, :keys, :key?, :values, :value?, :length,
		    :empty?, :clear, :each

		# Let :each be called as :each_section, too
		alias_method :each_section, :each


		### Return the value associated with the specified +key+.
		### @param [Symbol, String] key  the key of the value to return
		### @return [Object] the value associated with +key+, or another
		###                  Configurability::Config::ConfigStruct if +key+
		###                  is a section name.
		def []( key )
			key = key.untaint.to_sym

			# Create the config struct on the fly for subsections
			if !@hash.key?( key )
				@hash[ key ] = self.class.new
			elsif @hash[ key ].is_a?( Hash )
				@hash[ key ] = self.class.new( @hash[key] )
			end

			return @hash[ key ]
		end


		### Set the value associated with the specified +key+ to +value+.
		### @param [Symbol, String] key    the key of the value to set
		### @param [Object]         value  the value to set
		def []=( key, value )
			key = key.untaint.to_sym
			self.mark_dirty if @hash[ key ] != value
			@hash[ key ] = value
		end


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


		### Return a human-readable representation of the Struct suitable for debugging.
		def inspect
			return "#<%s:%0x16 %p>" % [
				self.class.name,
				self.object_id * 2,
				@hash,
			]
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
			return lambda { self[key] }
		end


		### Create a predicate method for the specified +key+ and return it.
		### @param [Symbol] key  the config key to create the predicate method body for
 		### @return [Proc] the body of the new method
		def create_member_predicate( key )
			return lambda { self[key] ? true : false }
		end


		### Create a writer method for the specified +key+ and return it.
		### @param [Symbol] key  the config key to create the writer method body for
		### @return [Proc] the body of the new method
		def create_member_writer( key )
			return lambda {|val| self[key] = val }
		end

	end # class Struct

end # class Configurability::Config

# vim: set nosta noet ts=4 sw=4:

