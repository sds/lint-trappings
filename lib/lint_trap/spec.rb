require 'lint_trap'

# Stub declaration so nested modules can reference it
module LintTrap::Spec; end

Dir[File.join(File.dirname(__FILE__), 'spec', '**', '*.rb')].each do |file|
  require file
end

RSpec.configure do |config|
  config.include LintTrap::Matchers
end
