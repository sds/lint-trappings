require 'lint_trap'
require 'lint_trap/arguments_parser'

module LintTrap
  # Command line application interface.
  class Cli
    # @param application [LintTrap::Application]
    # @param output [LintTrap::Output] stderr stream
    def initialize(application, output)
      @application = application
      @output = output
    end

    # Parses the given command line arguments and executes appropriate logic
    # based on those arguments.
    #
    # @param args [Array<String>] command line arguments
    #
    # @return [Integer] exit status code
    def run(args)
      options = ArgumentsParser.new(@application).parse(args)
      @application.run(options)
      0 # OK
    rescue ScanWarned, ScanFailed => ex
      # Special errors which we don't want to display, but do want their exit status
      ex.exit_status
    rescue => ex
      handle_exception(ex)
    end

    private

    # Returns an appropriate error code for the specified exception, and outputs
    # a message if necessary.
    def handle_exception(ex)
      if ex.is_a?(LintTrap::LintTrapError) && ex.exit_status != 70
        @output.error ex.message
        ex.exit_status
      else
        print_unexpected_exception(ex)
        ex.respond_to?(:exit_status) ? ex.exit_status : 70
      end
    end

    # Outputs the backtrace of an exception with instructions on how to report
    # the issue.
    def print_unexpected_exception(ex)
      @output.bold_error ex.message
      @output.error ex.backtrace.join("\n")
      @output.warning 'Report this bug at ', false
      @output.info @application.issues_url
      @output.newline
      @output.success 'To help fix this issue, please include:'
      @output.puts '- The above stack trace'
      @output.print "- #{@application.name} version: "
      @output.info @application.version
      @output.print '- Ruby version: '
      @output.info RUBY_VERSION
    end
  end
end
