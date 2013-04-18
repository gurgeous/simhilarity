require "bundler"
require "bundler/setup"
require "rake/testtask"
require "rdoc/task"

#
# gem
#

task gem: :build
task :build do
  system "gem build --quiet simhilarity.gemspec"
end

task install: :build do
  system "sudo gem install --quiet simhilarity-#{Simhilarity::VERSION}.gem"
end

task release: :build do
  system "git tag -a #{Simhilarity::VERSION} -m 'Tagging #{Simhilarity::VERSION}'"
  system "git push --tags"
  system "gem push simhilarity-#{Simhilarity::VERSION}.gem"
end

#
# test
#

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
end
task default: :test

#
# rdoc
#

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "simhilarity #{Simhilarity::VERSION}"
  rdoc.rdoc_files.include("lib/**/*.rb")
end
