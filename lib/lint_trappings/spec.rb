require 'lint_trappings'

# Stub declaration so nested modules can reference it
module LintTrappings::Spec; end

Dir[File.join(File.dirname(__FILE__), 'spec', '**', '*.rb')].each do |file|
  require file
end

RSpec.configure do |config|
  config.include LintTrappings::Matchers
end
