# -*- encoding: utf-8 -*-
# stub: webrobots 0.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "webrobots"
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Akinori MUSHA"]
  s.date = "2016-01-04"
  s.description = "This library helps write robots.txt compliant web robots in Ruby.\n"
  s.email = ["knu@idaemons.org"]
  s.extra_rdoc_files = ["LICENSE.txt", "README.rdoc"]
  s.files = ["LICENSE.txt", "README.rdoc"]
  s.homepage = "https://github.com/knu/webrobots"
  s.licenses = ["2-clause BSDL"]
  s.rdoc_options = ["--exclude", "\\.ry$"]
  s.rubygems_version = "2.5.1"
  s.summary = "A Ruby library to help write robots.txt compliant web robots"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0.9.2.2"])
      s.add_development_dependency(%q<racc>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<vcr>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["> 2.4.2"])
      s.add_development_dependency(%q<bundler>, [">= 1.2", "~> 1.2"])
      s.add_development_dependency(%q<nokogiri>, [">= 1.4.7", "~> 1.4"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<coveralls>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0.9.2.2"])
      s.add_dependency(%q<racc>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<vcr>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["> 2.4.2"])
      s.add_dependency(%q<bundler>, [">= 1.2", "~> 1.2"])
      s.add_dependency(%q<nokogiri>, [">= 1.4.7", "~> 1.4"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<coveralls>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.9.2.2"])
    s.add_dependency(%q<racc>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<vcr>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["> 2.4.2"])
    s.add_dependency(%q<bundler>, [">= 1.2", "~> 1.2"])
    s.add_dependency(%q<nokogiri>, [">= 1.4.7", "~> 1.4"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<coveralls>, [">= 0"])
  end
end
