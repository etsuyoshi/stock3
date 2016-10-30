# -*- encoding: utf-8 -*-
# stub: highcharts-rails 4.2.5 ruby lib

Gem::Specification.new do |s|
  s.name = "highcharts-rails"
  s.version = "4.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Per Christian B. Viken"]
  s.date = "2016-05-06"
  s.description = "Gem that includes Highcharts (Interactive JavaScript charts for your web projects), in the Rails Asset Pipeline introduced in Rails 3.1"
  s.email = ["perchr@northblue.org"]
  s.homepage = "http://northblue.org/"
  s.rubygems_version = "2.5.1"
  s.summary = "Gem for easily adding Highcharts to the Rails Asset Pipeline"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, [">= 3.1"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<rails>, [">= 3.1"])
    else
      s.add_dependency(%q<railties>, [">= 3.1"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<rails>, [">= 3.1"])
    end
  else
    s.add_dependency(%q<railties>, [">= 3.1"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<rails>, [">= 3.1"])
  end
end
