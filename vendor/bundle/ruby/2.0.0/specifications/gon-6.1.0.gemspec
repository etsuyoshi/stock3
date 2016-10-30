# -*- encoding: utf-8 -*-
# stub: gon 6.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gon"
  s.version = "6.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["gazay"]
  s.date = "2016-07-11"
  s.description = "If you need to send some data to your js files and you don't want to do this with long way trough views and parsing - use this force!"
  s.email = ["alex.gaziev@gmail.com"]
  s.homepage = "https://github.com/gazay/gon"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new("> 1.8.7")
  s.rubygems_version = "2.2.2"
  s.summary = "Get your Rails variables in your JS"

  s.installed_by_version = "2.2.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>, [">= 3.0"])
      s.add_runtime_dependency(%q<request_store>, [">= 1.0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>, [">= 0"])
      s.add_development_dependency(%q<rabl>, ["= 0.11.3"])
      s.add_development_dependency(%q<rabl-rails>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 3.0"])
      s.add_development_dependency(%q<jbuilder>, [">= 0"])
      s.add_development_dependency(%q<railties>, [">= 3.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
    else
      s.add_dependency(%q<actionpack>, [">= 3.0"])
      s.add_dependency(%q<request_store>, [">= 1.0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<multi_json>, [">= 0"])
      s.add_dependency(%q<rabl>, ["= 0.11.3"])
      s.add_dependency(%q<rabl-rails>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 3.0"])
      s.add_dependency(%q<jbuilder>, [">= 0"])
      s.add_dependency(%q<railties>, [">= 3.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
    end
  else
    s.add_dependency(%q<actionpack>, [">= 3.0"])
    s.add_dependency(%q<request_store>, [">= 1.0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<multi_json>, [">= 0"])
    s.add_dependency(%q<rabl>, ["= 0.11.3"])
    s.add_dependency(%q<rabl-rails>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 3.0"])
    s.add_dependency(%q<jbuilder>, [">= 0"])
    s.add_dependency(%q<railties>, [">= 3.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
  end
end
