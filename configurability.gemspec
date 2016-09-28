# -*- encoding: utf-8 -*-
# stub: configurability 2.2.1.pre20160928141048 ruby lib

Gem::Specification.new do |s|
  s.name = "configurability".freeze
  s.version = "2.2.1.pre20160928141048"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.cert_chain = ["certs/ged.pem".freeze]
  s.date = "2016-09-28"
  s.description = "Configurability is a unified, unintrusive, assume-nothing configuration system\nfor Ruby. It lets you keep the configuration for multiple objects in a single\nconfig file, load the file when it's convenient for you, and distribute the\nconfiguration when you're ready, sending it everywhere it needs to go with a\nsingle action.".freeze
  s.email = ["ged@FaerieMUD.org".freeze]
  s.executables = ["configurability".freeze]
  s.extra_rdoc_files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "History.rdoc".freeze, "README.rdoc".freeze]
  s.files = ["ChangeLog".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "bin/configurability".freeze, "examples/basicconfig.rb".freeze, "examples/config.yml".freeze, "lib/configurability.rb".freeze, "lib/configurability/behavior.rb".freeze, "lib/configurability/config.rb".freeze, "lib/configurability/deferredconfig.rb".freeze, "spec/configurability/config_spec.rb".freeze, "spec/configurability/deferredconfig_spec.rb".freeze, "spec/configurability_spec.rb".freeze, "spec/helpers.rb".freeze]
  s.homepage = "https://bitbucket.org/ged/configurability".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "2.6.6".freeze
  s.summary = "Configurability is a unified, unintrusive, assume-nothing configuration system for Ruby".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.11"])
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.5"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.8"])
      s.add_development_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.12"])
    else
      s.add_dependency(%q<loggability>.freeze, ["~> 0.11"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.5"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.8"])
      s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.12"])
    end
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.11"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.5"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.8"])
    s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.12"])
  end
end
