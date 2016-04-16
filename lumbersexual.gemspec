# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lumbersexual/version'

Gem::Specification.new do |spec|
  spec.name          = "lumbersexual"
  spec.version       = Lumbersexual::VERSION
  spec.authors       = ["Sam Pointer"]
  spec.email         = ["sam.pointer@outsidethe.net"]

  spec.summary       = %q{Benchmark syslog, fluentd and ELK stacks}
  spec.description   = %q{This gem generates random-enough syslog entries for the purposes of testing syslog throughput, ELK stacks, aggregated logging infrastructures and log index performance.}
  spec.homepage      = "https://github.com/sampointer/lumbersexual"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.2.0"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_dependency "slop", "~> 4.3.0"
  spec.add_dependency "statsd-ruby", "~> 1.3.0"
end
