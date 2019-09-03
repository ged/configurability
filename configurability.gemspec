# -*- encoding: utf-8 -*-
# stub: configurability 3.5.0.pre20190903110532 ruby lib

Gem::Specification.new do |s|
  s.name = "configurability".freeze
  s.version = "3.5.0.pre20190903110532"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Mahlon E. Smith".freeze]
  s.cert_chain = ["certs/ged.pem".freeze]
  s.date = "2019-09-03"
  s.description = "Configurability is a unified, non-intrusive, assume-nothing configuration system\nfor Ruby. It lets you keep the configuration for multiple objects in a single\nconfig file, load the file when it's convenient for you, and distribute the\nconfiguration when you're ready, sending it everywhere it needs to go with a\nsingle action.".freeze
  s.email = ["ged@FaerieMUD.org".freeze, "mahlon@martini.nu".freeze]
  s.extra_rdoc_files = ["History.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "History.md".freeze, "README.md".freeze]
  s.files = ["ChangeLog".freeze, "History.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "examples/basicconfig.rb".freeze, "examples/config.yml".freeze, "examples/readme.rb".freeze, "lib/configurability.rb".freeze, "lib/configurability/behavior.rb".freeze, "lib/configurability/config.rb".freeze, "lib/configurability/deferred_config.rb".freeze, "lib/configurability/setting_installer.rb".freeze, "spec/configurability/config_spec.rb".freeze, "spec/configurability/deferred_config_spec.rb".freeze, "spec/configurability_spec.rb".freeze, "spec/helpers.rb".freeze]
  s.homepage = "https://configur.ability.guide/".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Configurability is a unified, non-intrusive, assume-nothing configuration system for Ruby".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.14"])
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.10"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.12"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.18"])
    else
      s.add_dependency(%q<loggability>.freeze, ["~> 0.14"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.10"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.8"])
      s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.18"])
    end
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.14"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.10"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.8"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.18"])
  end
end
