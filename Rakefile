#!/usr/bin/env rake

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires 'hoe' (gem install hoe)"
end

GEMSPEC = 'configurability.gemspec'

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :deveiate

Hoe.plugins.delete :rubyforge

Encoding.default_internal = Encoding::UTF_8

hoespec = Hoe.spec 'configurability' do |spec|
	spec.readme_file = 'README.rdoc'
	spec.history_file = 'History.rdoc'
	spec.extra_rdoc_files = Rake::FileList[ '*.rdoc' ]
	spec.license 'BSD-3-Clause'

	spec.developer 'Michael Granger', 'ged@FaerieMUD.org'

	spec.dependency 'loggability', '~> 0.11'

	spec.dependency 'hoe-deveiate', '~> 0.5', :developer
	spec.dependency 'simplecov', '~> 0.8', :developer
	spec.dependency 'hoe-bundler', '~> 1.2', :developer
	spec.dependency 'rspec', '~> 3.0', :developer

	spec.require_ruby_version( '>= 1.9.2' )

	spec.hg_sign_tags = true if spec.respond_to?( :hg_sign_tags= )
	spec.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [ :check_history, :check_manifest, :gemspec, :spec ]


desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end


# Use the fivefish formatter for docs generated from development checkout
if File.directory?( '.hg' )
	require 'rdoc/task'

	Rake::Task[ 'docs' ].clear
	RDoc::Task.new( 'docs' ) do |rdoc|
	    rdoc.main = "README.md"
	    rdoc.rdoc_files.include( "*.rdoc", "*.md", "ChangeLog", "lib/**/*.rb" )
	    rdoc.generator = :fivefish
		rdoc.title = 'Configurability'
	    rdoc.rdoc_dir = 'doc'
	end
end


task :gemspec => [ 'ChangeLog', GEMSPEC ]
file GEMSPEC => __FILE__ do |task|
	spec = $hoespec.spec
	spec.files.delete( '.gemtest' )
	spec.files.delete( 'LICENSE' )
	spec.signing_key = nil
	spec.version = "#{spec.version}.pre#{Time.now.strftime("%Y%m%d%H%M%S")}"
	spec.cert_chain = [ 'certs/ged.pem' ]
	File.open( task.name, 'w' ) do |fh|
		fh.write( spec.to_ruby )
	end
end
CLOBBER.include( GEMSPEC )

task :default => :gemspec

