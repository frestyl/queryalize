# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "queryalize/version"

Gem::Specification.new do |s|
  s.name        = "queryalize"
  s.version     = Queryalize::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Peter Brindisi", "frestyl"]
  s.email       = ['npj@frestyl.com', 'info@frestyl.com']
  s.license     = 'MIT'
  s.homepage    = 'http://github.com/frestyl/queryalize'
  s.summary     = %q{Serialize chainable queries constructed with ActiveRecord::QueryMethods}
  s.description = %q{
    Queryalize lets you use Rails 3 to build queries just like with ActiveRecord::QueryMethods,
    except you can serialize the end result. This is useful for running queries that potentially
    return large result sets in the background using something like Resque or Delayed::Job.
  }

  s.rubyforge_project = "queryalize"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = ["lib"]
  
  s.add_dependency('activerecord', [">= 3.0.0"])
end
