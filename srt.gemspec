# -*- encoding: utf-8 -*-
require File.expand_path('../lib/srt/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Christopher Petersen"]
  gem.email         = ["christopher.petersen@gmail.com"]
  gem.description   = %q{Ruby gem for parsing srt (subtitle) files. SRT stands for SubRip text file format, which is a file for storing subtitles.}
  gem.summary       = %q{Ruby gem for parsing subtitle files.}
  gem.homepage      = "https://github.com/cpetersen/srt"

  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('coveralls')

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "srt"
  gem.require_paths = ["lib"]
  gem.version       = SRT::VERSION
end
