# -*- encoding: utf-8 -*-
# stub: natto 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "natto"
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Brooke M. Fujita"]
  s.date = "2016-06-18"
  s.description = "natto provides a naturally Ruby-esque interface to MeCab. It runs on both CRuby (mri/yarv) and JRuby (jvm). It works with MeCab installations on Windows, Unix/Linux, and OS X. No compiler is necessary, as natto is not a C extension.\n"
  s.email = "buruzaemon@gmail.com"
  s.homepage = "https://github.com/buruzaemon/natto"
  s.licenses = ["BSD"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.requirements = ["MeCab 0.996", "FFI, 1.9.0 or greater"]
  s.rubygems_version = "2.5.1"
  s.summary = "A gem leveraging FFI (foreign function interface), natto combines the Ruby programming language with MeCab, the part-of-speech and morphological analyzer for the Japanese language."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ffi>, [">= 1.9.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
    else
      s.add_dependency(%q<ffi>, [">= 1.9.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
    end
  else
    s.add_dependency(%q<ffi>, [">= 1.9.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
  end
end
