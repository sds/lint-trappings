if ENV['TRAVIS']
  # When running in Travis, report coverage stats to Coveralls.
  require 'coveralls'
  Coveralls.wear!
else
  # Otherwise render coverage information in coverage/index.html and display
  # coverage percentage in the console.
  require 'simplecov'
end

require 'lint_trappings/spec'
require 'rspec/its'

Dir[File.join(%W[#{File.dirname(__FILE__)} support ** *.rb])].each { |f| require f }

RSpec.configure do |config|
  config.expose_dsl_globally = false # Don't add `describe` to global namespace

  config.include LintTrappings::Spec::DirectoryHelpers
  config.include LintTrappings::Spec::IndentationHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
end
