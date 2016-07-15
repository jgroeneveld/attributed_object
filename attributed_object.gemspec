# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'attributed_object/version'

Gem::Specification.new do |spec|
  spec.name          = "attributed_object"
  spec.version       = AttributedObject::VERSION
  spec.authors       = ["Jaap Groeneveld"]
  spec.email         = ["jgroeneveld@me.com"]
  spec.summary       = %q{Simple and fast module for named arguments in model initializers}
  spec.description   = %q{Simple and fast module for named arguments in model initializers}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
