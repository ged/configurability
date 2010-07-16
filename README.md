# Configurability

Configurability is a mixin that allows you to add configurability to one or
more objects or classes. You can assign them each a subsection of the
configuration, and then later, when the configuration is loaded, the
configuration is split up and sent to the objects that will use it.

## Usage

To add configurability to a class, just require the library and extend
the class:

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
underscores (`_`) by default.

If the object responds to the `#name` method, then the return value of that
method is used to derive the name. If it doesn't have a `#name` method, the
name of its `Class` will be used instead. If its class is anonymous, then
the object's config key will be `:anonymous`.

When the configuration is loaded, an instance variable called `@config` is set
to the appropriate section of the config object for each object that has
been extended with Configurability.


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

        def self::configure( configsection )
            @default_bind_addr = configsection[:host]
            @default_port = configsection[:port]
        end
    end

If you still want the `config` variable to be set, just `super` from your implementation; don't if you don't want it to be set.


## Development

You can submit bug reports, suggestions, and read more about future plans at
the project page:

> http://bitbucket.org/ged/configurability

or clone it with Mercurial from the same address.


## License

Copyright (c) 2010, Michael Granger
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
