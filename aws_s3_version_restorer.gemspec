# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_s3_version_restorer/version'

Gem::Specification.new do |spec|
  spec.name          = "aws_s3_version_restorer"
  spec.version       = AwsS3VersionRestorer::VERSION
  spec.authors       = ["Kai Xiang"]
  spec.email         = ["kxiang@pivotallabs.com"]
  spec.description   = %q{This is a tool helps restore your S3 objects in AWS, once you enabled S3 versioning }
  spec.summary       = %q{Managing A big S3 bucket with versioning enabled could be painful, This is a tool intent to help relieve the pain}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.9.0"
  spec.add_development_dependency "mothership"
  spec.add_development_dependency "highline"
  spec.add_development_dependency "aws-sdk", '1.35'
end
