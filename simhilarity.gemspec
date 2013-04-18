$LOAD_PATH << File.expand_path("../lib", __FILE__)

require "simhilarity/version"

Gem::Specification.new do |s|
  s.name        = "simhilarity"
  s.version     = Simhilarity::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.9.0"
  s.authors     = ["Adam Doppelt"]
  s.email       = ["amd@gurge.com"]
  s.homepage    = "http://github.com/gurgeous/simhilarity"
  s.summary     = "Simhilarity - measure text similarity using frequency weighted ngrams."
  s.description = "Measure text similarity using frequency weighted ngrams."

  s.rubyforge_project = "simhilarity"

  s.add_runtime_dependency "bk"
  s.add_runtime_dependency "progressbar"

  s.add_development_dependency "awesome_print"
  s.add_development_dependency "rake"
  s.add_development_dependency "rdoc"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |i| File.basename(i) }
  s.require_paths = ["lib"]
end
