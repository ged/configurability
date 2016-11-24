# Configurability

home
: https://bitbucket.org/ged/configurability

code
: https://bitbucket.org/ged/configurability

docs
: http://deveiate.org/code/configurability

github
: https://github.com/ged/configurability



## Description

Configurability is a unified, unintrusive, assume-nothing configuration system
for Ruby. It lets you keep the configuration for multiple objects in a single
config file, load the file when it's convenient for you, and distribute the
configuration when you're ready, sending it everywhere it needs to go with a
single action.



## Installation

    gem install configurability


## Usage

To add configurability to a class, just require the library and extend
the class:

    require 'configurability'
    class User
        extend Configurability
    end

Or, add it to a instance:

    user = User.new
    user.extend( Configurability )

Later, when you've loaded the configuration, can can call

    Configurability.configure_objects( config )

and the `config` will be spliced up and sent to all the objects that have
been extended with it. `Configurability` expects the configuration to be 
broken up into a number of sections, each of which is accessible via either
a method with the _section name_ or the index operator (`#[]`) that takes the 
_section name_ as a `Symbol` or a `String`:

    config.section_name
    config[:section_name]
    config['section_name']

The section name is based on an object's _config key_, which is the name of
the object that is being extended with all non-word characters converted into
underscores (`_`) by default. It will also have any leading Ruby-style
namespaces stripped, e.g.,

            MyClass            -> :myclass
            Acme::User         -> :user
            "J. Random Hacker" -> :j_random_hacker

If the object responds to the `#name` method, then the return value of that
method is used to derive the name. If it doesn't have a `#name` method, the
name of its `Class` will be used instead. If its class is anonymous, then
the object's config key will be `:anonymous`.

When the configuration is loaded, an instance variable called `@config` is set
to the appropriate section of the config object for each object that has
been extended with Configurability.

As you add more objects to your configuration, it may be useful to group
related sections together. You can specify that your object's configuration
is part of a group by prepending the name of the group to your config key
separated by a double underscore (`__`)


## Customization

The default behavior above is just provided as a reasonable default; it is
expected that you'll want to customize at least one or two things about
how configuration is handled in your objects.


### Setting a Custom Config Key

The first thing you might want to do is change the config section that
corresponds to your object. You can do that by declaring a different
config key, either using a declarative method:

    class OutputFormatter
        extend Configurability
        config_key :format
    end

or by overriding the `#config_key` method and returning the desired value
as a Symbol:

    class User
        extend Configurability
        def self::config_key
            return :employees
        end
    end


### Changing How an Object Is Configured

You can also change what happens when an object is configured by implementing
a `#configure` method that takes the config section as an argument:

    class WebServer
        extend Configurability

        config_key :webserver

        def self::configure( configsection )
            @default_bind_addr = configsection[:host]
            @default_port = configsection[:port]
        end
    end

If you still want the `@config` variable to be set, just `super` from your
implementation; don't if you don't want it to be set.


## Configuration Objects

Configurability also includes `Configurability::Config`, a fairly simple
configuration object class that can be used to load a YAML configuration file,
and then present both a Hash-like and a Struct-like interface for reading
configuration sections and values; it's meant to be used in tandem with
Configurability, but it's also useful on its own.

Here's a quick example to demonstrate some of its features. Suppose you have a
config file that looks like this:

    --- 
    database: 
      development: 
        adapter: sqlite3
        database: db/dev.db
        pool: 5
        timeout: 5000
      testing: 
        adapter: sqlite3
        database: db/testing.db
        pool: 2
        timeout: 5000
      production: 
        adapter: postgres
        database: fixedassets
        pool: 25
        timeout: 50
    ldap: 
      uri: ldap://ldap.acme.com/dc=acme,dc=com
      bind_dn: cn=web,dc=acme,dc=com
      bind_pass: Mut@ge.Mix@ge
    branding: 
      header: "#333"
      title: "#dedede"
      anchor: "#9fc8d4"

You can load this config like so:

    require 'configurability/config'
    config = Configurability::Config.load( 'examples/config.yml' )
    # => #<Configurability::Config:0x1018a7c7016 loaded from 
        examples/config.yml; 3 sections: database, ldap, branding>

And then access it using struct-like methods:

    config.database
    # => #<Configurability::Config::Struct:101806fb816
        {:development=>{:adapter=>"sqlite3", :database=>"db/dev.db", :pool=>5,
        :timeout=>5000}, :testing=>{:adapter=>"sqlite3",
        :database=>"db/testing.db", :pool=>2, :timeout=>5000},
        :production=>{:adapter=>"postgres", :database=>"fixedassets",
        :pool=>25, :timeout=>50}}>

    config.database.development.adapter
    # => "sqlite3"

    config.ldap.uri
    # => "ldap://ldap.acme.com/dc=acme,dc=com"

    config.branding.title
    # => "#dedede"

or using a Hash-like interface using either `Symbol`s, `String`s, or a mix of
both:

    config[:branding][:title]
    # => "#dedede"

    config['branding']['header']
    # => "#333"

    config['branding'][:anchor]
    # => "#9fc8d4"

You can install it via the Configurability interface:

    config.install

Check to see if the file it was loaded from has changed since you
loaded it:

    config.changed?
    # => false

    # Simulate changing the file by manually changing its mtime
    File.utime( Time.now, Time.now, config.path )
    config.changed?
    # => true

If it has changed (or even if it hasn't), you can reload it, which
automatically re-installs it via the Configurability interface:

    config.reload

You can make modifications via the same Struct- or Hash-like interfaces and
write the modified config back out to the same file:

    config.database.testing.adapter = 'mysql'
    config[:database]['testing'].database = 't_fixedassets'

then dump it to a YAML string:

    config.dump
	# => "--- \ndatabase: \n  development: \n    adapter: sqlite3\n   
		database: db/dev.db\n    pool: 5\n    timeout: 5000\n  testing: \n   
		adapter: mysql\n    database: t_fixedassets\n    pool: 2\n    timeout:
		5000\n  production: \n    adapter: postgres\n    database:
		fixedassets\n    pool: 25\n    timeout: 50\nldap: \n  uri:
		ldap://ldap.acme.com/dc=acme,dc=com\n  bind_dn:
		cn=web,dc=acme,dc=com\n  bind_pass: Mut@ge.Mix@ge\nbranding: \n 
		header: \"#333\"\n  title: \"#dedede\"\n  anchor: \"#9fc8d4\"\n"

or write it back to the file it was loaded from:

	config.write


## Configuration Defaults

It's a good idea to provide a set of reasonable defaults for any configured
object. Configurability provides a `defaults` method that will look for a constant
called either `DEFAULT_CONFIG` or `CONFIG_DEFAULTS` on each object extended with
Configurability, and will return a dup of the value of this constant if it does.

You can also override `defaults` yourself if you wish to provide them via something
other than a constant.

There are also a couple of useful functions built on top of this method:

gather_defaults
: You can fetch a Hash of the default config values of all objects that have been extended 
  with Configurability by calling `Configurabilty.gather_defaults`. You can also pass an
  object that responds to `#merge!` to the method to merge the defaults into an existing
  config.

default_config
: This will return a Configurability::Config object made from the results of
  `gather_defaults`. This makes it easy to write a config file that contains the default
  configuration: `Configurability.default_config.write( "defaults.yml" )`


## Development

You can submit bug reports, suggestions, clone it with Mercurial, and
read more about future plans at 
{the project page}[http://bitbucket.org/ged/configurability]. If you 
prefer Git, there is also a 
{Github mirror}[https://github.com/ged/configurability].

After checking out the source, run:

    $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the API documentation.


## License

Copyright (c) 2010-2016 Michael Granger and Mahlon E. Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


