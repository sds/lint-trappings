require 'lint_trappings/cli'

# Helper module for creating a LintTrappings-powered executable.
module LintTrappings::Executable
  module_function

  # Runs the command line interface.
  #
  # This should be called from your application executable, like so:
  #
  # @example
  #   #!/usr/bin/env ruby
  #   require 'my_linter_gem'
  #   require 'lint_trappings/executable'
  #   LintTrappings::Executable.run(MyLinter::Application, STDOUT, STDERR, ARGV)
  #
  # @param application_class [Class]
  # @param stdout [IO] output stream
  # @param arguments [Array<String>] command line arguments
  def run(application_class, stdout, stderr, arguments)
    output = LintTrappings::Output.new(stdout)
    error_output = LintTrappings::Output.new(stderr)
    application = application_class.new(output)
    exit LintTrappings::Cli.new(application, error_output).run(arguments)
  end
end
