$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'lint_trappings/version'

Gem::Specification.new do |s|
  s.name             = 'lint_trappings'
  s.version          = LintTrappings::VERSION
  s.license          = 'MIT'
  s.summary          = 'Linter framework'
  s.description      = 'Framework for writing static analysis tools (a.k.a. linters)'
  s.authors          = ['Shane da Silva']
  s.email            = ['shane@dasilva.io']
  s.homepage         = 'https://github.com/sds/lint-trappings'

  s.require_paths    = ['lib']

  s.files            = Dir['lib/**/*.rb'] + ['LICENSE.md']

  s.required_ruby_version = '>= 2'

  s.add_dependency 'parallel', '~> 1.6'
  s.add_dependency 'terminal-table', '~> 1.4'
end
