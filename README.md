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

Configurability is a unified, non-intrusive, assume-nothing configuration system
for Ruby. It lets you keep the configuration for multiple objects in a single
config file, load the file when it's convenient for you, and distribute the
configuration when you're ready, sending it everywhere it needs to go with a
single action.


## Installation

    gem install configurability


## Example

    # user.rb
    require 'configurability'
    
    class User
        extend Configurability

        configurability( :users ) do
            setting :min_password_length, default: 6
        end

    end


    # config.yml
    users:
      min_password_length: 12

In pry:

    [1] pry(main)> require 'user'
    => true
    [2] pry(main)> User.min_password_length
    => 6
    [3] pry(main)> config = Configurability::Config.load( "config.yml" )
    => #<Configurability::Config:0x7fd99a0f635816 loaded from config.yml ...>
    [4] pry(main)> config.install
    => [Loggability, User]
    [5] pry(main)> User.min_password_length
    => 12


## Usage

To add Configurability to your module or class, just `extend` it and declare
some settings:

    require 'configurability'
    class Database
        extend Configurability

        configurability( :db ) do
            setting :url, default: 'sqlite:/'
            setting :user
            setting :password
            setting :port do |value|
                Integer( value ) if value
            end
        end
    end

This sets up the class to use the `db` config key, and adds attributes for the
three subkey settings under it (with getters and setters) to the class. It also
adds a `configure` class method that will set whichever of the settings are
passed to it, defaulting the `url` to the provided value if it's not given.

The `setting` can include a block which is given the config value before it's
set; from this block you can do validity-checking, cast it to something other
than a String, etc. The new value will be set to the return value of the block.
Note that this will be called with the default for the setting when it's
declared, so the block should be able to handle the default (even if it's
`nil`).

If your config file (e.g., `config.yml`) looks like this:

    --
    db:
        url: 'postgres:/acme'
        user: tim
        password: "pXVvVY,YjWNRRi[yPWx4"

You can configure the `Database` class (and all other objects extended with
Configurability) with it like so:

    require 'configurability/config'
    
    config = Configurability::Config.load( 'config.yml' )
    Configurability.configure_objects( config )

After this happens you can access the configuration values like this:

    Database.url
    # => "postgres:/acme"
    Database.user
    # => "tim"
    Database.password
    # => "pXVvVY,YjWNRRi[yPWx4"


### More Details

Configurability is implemented using `Module#extend`, so there's very little
magic going on. Every object (including Class and Module objects) that is
extended with Configurability is registered in an Array of objects that will be
configured when the config is loaded.

You extend a Class, of course, as in the above example:

    class MyClass
        extend Configurabtility
    end

But you can also add it to individual instances of objects to configure them
separately:

    user = User.new
    user.extend( Configurability )

When you call:

    Configurability.configure_objects( config )

the specified `config` will be spliced up and sent to all the objects that have
been registered. `Configurability` expects the configuration to be broken
up into a number of sections, each of which is accessible via either a method
with the _section name_ or the index operator (`#[]`) that takes the _section
name_ as a `Symbol` or a `String`:

    config.section_name
    config[:section_name]
    config['section_name']

The section name is based on an object's _config key_, which is the argument
you specify when declaring your settings. If you don't provide one, it defaults
to the name of the object that is being extended with all non-word characters
converted into underscores (`_`). It will also have any leading Ruby-style
namespaces stripped, e.g.,

    MyClass            -> :myclass
    Acme::User         -> :user
    "J. Random Hacker" -> :j_random_hacker

If the object responds to the `#name` method, then the return value of that
method is used to derive the name. If it doesn't have a `#name` method, the
name of its `Class` will be used instead. If its class is anonymous, then
the object's config key will be `:anonymous`.

When the configuration is loaded, any attribute writers that correspond with
keys of the config will be called with the configured values, and an instance
variable called `@config` is set to the appropriate section of the config.

As you add more objects to your configuration, it may be useful to group
related sections together. You can specify that your object's configuration
is part of a group by specifying a config key with either a dot if it's a String or a double underscore if it's a Symbol. E.g.,

    # Read from the `db` subsection of `myapp`
    configurability( 'myapp.db' )

    # Same thing, but with a symbol:
    configurability( :myapp__db )


## Customization

The default behavior above is just provided as a reasonable default; you may
want to customize one or two things about how configuration is handled in your
objects.


### Setting a Custom Config Key

If you want to customize the config key without calling `configurability` you
can do that by declaring it with the `config_key` method:

    class OutputFormatter
        extend Configurability
        config_key :format
    end

or by overriding the `#config_key` method youtself and returning the desired
value as a Symbol:

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

        def self::configure( config )
            @default_bind_addr = config[:host]
            @default_port = config[:port]
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

You can install it (i.e., configure your objects) via the Configurability
interface:

    config.install

If you change the values in the config object, they won't propagate
automatically; you'll need to call `#install` on it again to send the changes to
the objects being configured.

You can check to see if the file the config was loaded from has changed since
you loaded it:

    config.changed?
    # => false

    # Simulate changing the file by manually changing its mtime
    File.utime( Time.now, Time.now, config.path )
    config.changed?
    # => true

If it has changed (or even if it hasn't), you can reload it, which
automatically re-installs it via the Configurability interface if it has:

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

Note that this is just using `YAML.dump`, so any comments, ordering, or other
nice formatting you have in your config file will be clobbered if you rewrite
it.


## Configuration Defaults

It's a good idea to provide a set of reasonable defaults for any configured
object. The defaults for all settings are added to extended Classes and Modules
as a constant named `CONFIG_DEFAULTS`. You can, of course set this constant
yourself as well.

Configurability provides a `defaults` method that will return the hash of
settings and their default values from the `CONFIG_DEFAULTS` constant. You can
also override the `defaults` method yourself (and super to the original) if you
wish to do something different.

There are also a couple of useful functions built on top of this method:

gather_defaults
: You can fetch a Hash of the default config values of all objects that have
  been extended with Configurability by calling
  `Configurabilty.gather_defaults`. You can also pass an object that responds
  to `#merge!` to the method to merge the defaults into an existing
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

Copyright (c) 2010-2017 Michael Granger and Mahlon E. Smith
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


