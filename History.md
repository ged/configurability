## v3.2.0 [2017-04-17] Michael Granger <ged@FaerieMUD.org>

Enhancements:

- Add an option to use class variables for settings instead of class-instance variables.

Bugfixes:

- Update the README to point out that the setting block needs to
  handle the default value.


## v3.1.2 [2017-01-16] Michael Granger <ged@FaerieMUD.org>

Bugfix:

- Always use the pre-processor block for defaults.


## v3.1.1 [2017-01-03] Michael Granger <ged@FaerieMUD.org>

Bugfix:

- Fix inheritance of defaults when declared using settings


## v3.1.0 [2017-01-03] Michael Granger <ged@FaerieMUD.org>

Enhancement:

- Add optional pre-processor block to `setting`s.


## v3.0.0 [2016-11-23] Michael Granger <ged@FaerieMUD.org>

Enhancement:

- Add hierarchical config keys
- Add a DSL for setting up settings and defaults
- Add a better default #configure method


## v2.2.2 [2016-09-28] Michael Granger <ged@FaerieMUD.org>

- Added signature for changeset 806d1f512f55

## v2.2.2 [2016-09-28] Michael Granger <ged@FaerieMUD.org>

- Fix the merge used by Configurability.gather_defaults
  It should now correctly merge top-level sections together.
- Make configuration source logging log at a consistent level.


## v2.2.1 [2014-06-04] Michael Granger <ged@FaerieMUD.org>

Update shared behavior to work under RSpec 3.0.0.


## v2.2.0 [2014-05-19] Michael Granger <ged@FaerieMUD.org>

- Add a .default_config method to objects with Configurability.


## v2.1.2 [2014-01-20] Michael Granger <ged@FaerieMUD.org>

Symbolify keys of defaults for Configurability::Config.new (fixes #3).


## v2.1.1 [2013-11-20] Michael Granger <ged@FaerieMUD.org>

- Fix untainting to not try to dup/untaint immediate objects.
  Thanks to john@cozy.co for the bug report.


## v2.1.0 [2013-08-13] Michael Granger <ged@FaerieMUD.org>

- Fix behavior of inherited Configurability
- Convert specs to use RSpec expect syntax
- Drop support for Ruby 1.8.7.


## v2.0.2 [2013-06-14] Mahlon E. Smith <mahlon@martini.nu>

- Added signature for changeset e53b53d65079

## v2.0.2 [2013-06-14] Mahlon E. Smith <mahlon@martini.nu>

- Load YAML safely if the safe_yaml gem is present.


## v2.0.1 [2013-06-07] Mahlon E. Smith <mahlon@martini.nu>

- Repair relationship with Loggability.


## v2.0.0 [2013-01-30] Michael Granger <ged@FaerieMUD.org>

- Make missing Configurability::Config values return nil instead of
  auto-vivifying to a Struct.

  This is not a backward-compatible change, but in practice, far more
  work was done to detect non-existant values than was saved by the
  debatable convenience of being able to auto-create nested structs.

- Update to loggability 0.4 and add Rubinius (1.9-mode) fixes.


## v1.2.0 [2012-05-09] Michael Granger <ged@FaerieMUD.org>

- Added a command-line utility.
- Convert logging to use Loggability.


## v1.1.0 [2012-04-25] Michael Granger <ged@FaerieMUD.org>

Add a 'defaults' API that allows defaults to be gathered from any
object with configurability and merged into a hash keyed by the
object's config_key. This hash can be used to generate an initial
unified config file for all configurable parts of a given system.


## v1.0.10 [2012-03-13] Michael Granger <ged@FaerieMUD.org>

- Fix log level message.


## v1.0.9 [2012-01-27] Michael Granger <ged@FaerieMUD.org>

Fix problems associated with inheritance.

- Added a Hash of configure methods that have already been called
  as pairs of Methods and Config sections. (Configurability.configured)
- Use the `configured` hash to avoid re-calling configure with the same
  config section more than once when a class with Configurability is
  inherited.
- Configurability.install_config -- Only use the index operator method
  of the config object if it actually has the config_key as a key. Else
  configure with +nil+.
- Support different whitespace conventions in different YAML libraries

Thanks to Mahlon E. Smith for reporting this bug, and for pairing with
me to fix it.


## v1.0.8 [2011-11-01] Michael Granger <ged@FaerieMUD.org>

- Fix for Ruby 1.9.3-p0.


## v1.0.7 [2011-10-13] Michael Granger <ged@FaerieMUD.org>

- De-Yard and fix some other documentation/packaging issues.


## v1.0.6 [2011-03-03] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

* Fixed predicate methods for missing sections/values, which previously returned
  `true` as well.


## v1.0.5 [2011-02-08] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

* Now handles config files with nil keys correctly.


## v1.0.4 [2010-11-29] Michael Granger <ged@FaerieMUD.org>

Packaging fix.


## v1.0.3 [2010-11-29] Michael Granger <ged@FaerieMUD.org>

Enchancements:

* Propagate the installed config to objects that add Configurability after the
  config is loaded.


## v1.0.2 [2010-11-29] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

* Fixes for specs under 1.9.2.


## v1.0.1 [2010-08-08] Michael Granger <ged@FaerieMUD.org>

Enhancements:

* Adding a Configurability::Config class for YAML config loading.
* Add an rspec shared behavior for testing classes with Configurability
* Converted tests to RSpec 2.


## v1.0.0 [2010-07-12] Michael Granger <ged@FaerieMUD.org>

Initial release

