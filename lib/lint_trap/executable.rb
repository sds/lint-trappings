require 'lint_trap/cli'

# Helper module for creating a LintTrap-powered executable.
module LintTrap::Executable
  module_function

  # Runs the command line interface.
  #
  # This should be called from your application executable, like so:
  #
  # @example
  #   #!/usr/bin/env ruby
  #   require 'my_linter_gem'
  #   require 'lint_trap/executable'
  #   LintTrap::Executable.run(MyLinter::Application, STDOUT, STDERR, ARGV)
  #
  # @param application_class [Class]
  # @param stdout [IO] output stream
  # @param arguments [Array<String>] command line arguments
  def run(application_class, stdout, stderr, arguments)
    output = LintTrap::Output.new(stdout)
    error_output = LintTrap::Output.new(stderr)
    application = application_class.new(output)
    exit LintTrap::Cli.new(application, error_output).run(arguments)
  end
end
