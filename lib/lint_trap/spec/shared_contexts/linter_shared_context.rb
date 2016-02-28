# Makes writing tests for linters a lot DRYer by taking any `src` variable
# defined via `let` and normalizing it (removing indentation that would be
# inserted by using Heredocs) and setting up the subject to be the lints
# returned by Linter#run.
#
# Thus a typical test will look like:
#
# @example
#   require 'spec_helper'
#
#   RSpec.describe MyApp::Linter::MyLinter do
#     include_context 'linter'
#
#     context 'when source contains "foo"' do
#       let(:src) { <<-SRC }
#         This is some code
#         with the word "foo" in it.
#       SRC
#
#       it { should report_lint line: 2 }
#     end
#   end
shared_context 'linter' do
  let(:config) do
    LINT_TRAP_APPLICATION_CLASS.base_configuration.for_linter(described_class)
  end

  subject do
    linter = described_class.new(config)
    document = LINT_TRAP_APPLICATION_CLASS.document_class
                                          .new(normalize_indent(src), config)
    linter.run(document)
    linter
  end
end
