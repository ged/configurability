#!/usr/bin/env rake

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires 'hoe' (gem install hoe)"
end


Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :deveiate
Hoe.plugin :bundler

Hoe.plugins.delete :rubyforge

Encoding.default_internal = Encoding::UTF_8

hoespec = Hoe.spec 'configurability' do |spec|
	spec.readme_file = 'README.rdoc'
	spec.history_file = 'History.rdoc'
	spec.extra_rdoc_files = Rake::FileList[ '*.rdoc' ]
	spec.license 'BSD'

	spec.developer 'Michael Granger', 'ged@FaerieMUD.org'

	spec.dependency 'loggability', '~> 0.4'

	spec.dependency 'hoe-deveiate', '~> 0.3', :developer
	spec.dependency 'simplecov', '~> 0.5', :developer
	spec.dependency 'hoe-bundler', '~> 1.2', :developer

	spec.require_ruby_version( '>= 1.9.2' )

	spec.hg_sign_tags = true if spec.respond_to?( :hg_sign_tags= )
	spec.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [ :check_history, :check_manifest, :spec ]


desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end

