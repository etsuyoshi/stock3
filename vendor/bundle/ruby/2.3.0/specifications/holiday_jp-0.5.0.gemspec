# -*- encoding: utf-8 -*-
# stub: holiday_jp 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "holiday_jp"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Masaki Komagata"]
  s.date = "2016-09-09"
  s.description = "Japanese Holidays from 1970 to 2050."
  s.email = ["komagata@gmail.com"]
  s.homepage = "http://github.com/komagata/holiday_jp"
  s.rubyforge_project = "holiday_jp"
  s.rubygems_version = "2.5.1"
  s.summary = "Japanese Holidays."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.6"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, ["= 3.0.9"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.6"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<test-unit>, ["= 3.0.9"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.6"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<test-unit>, ["= 3.0.9"])
  end
end
