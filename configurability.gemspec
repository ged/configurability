# -*- encoding: utf-8 -*-
# stub: configurability 2.3.0.pre20150227190908 ruby lib

Gem::Specification.new do |s|
  s.name = "configurability"
  s.version = "2.3.0.pre20150227190908"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger"]
  s.date = "2015-02-28"
  s.description = "Configurability is a unified, unintrusive, assume-nothing configuration system\nfor Ruby. It lets you keep the configuration for multiple objects in a single\nconfig file, load the file when it's convenient for you, and distribute the\nconfiguration when you're ready, sending it everywhere it needs to go with a\nsingle action."
  s.email = ["ged@FaerieMUD.org"]
  s.executables = ["configurability"]
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "History.rdoc", "README.rdoc"]
  s.files = ["ChangeLog", "History.rdoc", "LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "bin/configurability", "examples/basicconfig.rb", "examples/config.yml", "lib/configurability.rb", "lib/configurability/behavior.rb", "lib/configurability/config.rb", "lib/configurability/deferredconfig.rb", "spec/configurability/config_spec.rb", "spec/configurability/deferredconfig_spec.rb", "spec/configurability_spec.rb", "spec/helpers.rb"]
  s.homepage = "https://bitbucket.org/ged/configurability"
  s.licenses = ["BSD"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.rubygems_version = "2.4.5"
  s.signing_key = "/Volumes/Keys/ged-private_gem_key.pem"
  s.summary = "Configurability is a unified, unintrusive, assume-nothing configuration system for Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>, ["~> 0.11"])
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.8"])
      s.add_development_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_development_dependency(%q<rspec>, ["~> 3.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<loggability>, ["~> 0.11"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<simplecov>, ["~> 0.8"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_dependency(%q<rspec>, ["~> 3.0"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<loggability>, ["~> 0.11"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<simplecov>, ["~> 0.8"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
    s.add_dependency(%q<rspec>, ["~> 3.0"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
