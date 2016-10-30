# -*- encoding: utf-8 -*-
# stub: meta-tags 2.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "meta-tags"
  s.version = "2.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Dmytro Shteflyuk"]
  s.bindir = "exe"
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDcDCCAligAwIBAgIBATANBgkqhkiG9w0BAQUFADA/MQ8wDQYDVQQDDAZrcHVt\ndWsxFjAUBgoJkiaJk/IsZAEZFgZrcHVtdWsxFDASBgoJkiaJk/IsZAEZFgRpbmZv\nMB4XDTE2MDgyNDAxMDYwOFoXDTE3MDgyNDAxMDYwOFowPzEPMA0GA1UEAwwGa3B1\nbXVrMRYwFAYKCZImiZPyLGQBGRYGa3B1bXVrMRQwEgYKCZImiZPyLGQBGRYEaW5m\nbzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALw2YroZc+IT+rs8NuPu\nc13DelrxrpAgPEu1zuRb3l7WaHRNWA4TyS8Z6Aa1G2O+FdUZNMW1n7IwP/QMJ9Mz\nahRBiTmhik5kasJ9s0h1lq5/hZiycm0o5OtGioUzCkvk+UEMpzMHbLmVSZCzYciy\nNDRDbXB0rLLu1eJk+gKgn6Qf5vj93h1w28BdWdaA7YegtbmipZ+pjmzCQAfPActT\n6uXHG4dSo7Lz9jiFRI5dUizFbGXcRqkQ2b5AB8FFmfcvbqERvzQKBICnybjsKP0N\npJ3vGgO2sh5GvJFOPk1Vlur2nX9ZFznPEP1CEAQ+NFrmKRt355Z5sgOkAojSGnIL\n/1sCAwEAAaN3MHUwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFPa4\nVFc1YOlV1u/7EGTwMCAk8YE9MB0GA1UdEQQWMBSBEmtwdW11a0BrcHVtdWsuaW5m\nbzAdBgNVHRIEFjAUgRJrcHVtdWtAa3B1bXVrLmluZm8wDQYJKoZIhvcNAQEFBQAD\nggEBAKOnJYyA5Aq2BPQTSd9uxUzoYL010HsxIz2xFPNRxcI9wvgy6tE7noUD6yu5\nk/IXjQOiqMag0zGF3rdEbDFHsvDhos9xZeGUaM3YIfoYg4YF7P7HgRCQFYL7G3va\nh++H5FhlqFOF8g4lvYZ80AMNBO/tDfGuIzaJFbv+1mlHc2Szd3t7Mt2kNae92OYJ\nx9+w3/LzxW8XariFP1RBseVgHdH9JwbranEqRJ51WwJ0zTGgDnvGxOxigExXEfYE\nHe5T3dBG5WWdIclQcE+JgohBpQ78TcVs1pFNjFmW9pC/P7Rm2GlYqOPHBQG1/Qx9\nySbbrGHRLVz8DCxQbhKw+mdT5bg=\n-----END CERTIFICATE-----\n"]
  s.date = "2016-09-14"
  s.description = "Search Engine Optimization (SEO) plugin for Ruby on Rails applications."
  s.email = ["kpumuk@kpumuk.info"]
  s.homepage = "http://github.com/kpumuk/meta-tags"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Collection of SEO helpers for Ruby on Rails."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>, ["<= 5.1.0", ">= 3.2.0"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.5.0"])
      s.add_development_dependency(%q<rspec-html-matchers>, ["~> 0.8.0"])
    else
      s.add_dependency(%q<actionpack>, ["<= 5.1.0", ">= 3.2.0"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<rspec>, ["~> 3.5.0"])
      s.add_dependency(%q<rspec-html-matchers>, ["~> 0.8.0"])
    end
  else
    s.add_dependency(%q<actionpack>, ["<= 5.1.0", ">= 3.2.0"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<rspec>, ["~> 3.5.0"])
    s.add_dependency(%q<rspec-html-matchers>, ["~> 0.8.0"])
  end
end
