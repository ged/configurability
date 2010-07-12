#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'configurability'
require 'sequel'
require 'treequel'


class DatabaseAdapter
	extend Configurability

	config_key :db

	### Configure the database
	def self::configure( dbconfig )
		$stderr.puts "Configuring database adapter: %p" % [ dbconfig ]
		@database = Sequel.connect( dbconfig )
	end

end # class DatabaseAdapter

class LdapAdapter
	extend Configurability

	config_key :ldap

	def self::configure( ldapconfig )
		$stderr.puts "Configuring LDAP adapter: %p" % [ ldapconfig ]
		@ldap = Treequel.directory( ldapconfig )
	end

end # class LdapAdapter


config = YAML.load( DATA )
Configurability.configure_objects( config )


__END__

:db:
  :adapter: postgres
  :host: localhost
  :database: test
  :user: test

:ldap:
  :host: localhost
  :port: 389
  :connect_type: tls
  :base_dn: dc=acme,dc=com

