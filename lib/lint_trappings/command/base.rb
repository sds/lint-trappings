module LintTrappings::Command
  # Abstract base class of all commands.
  #
  # @abstract
  class Base
    # @param application [LintTrappings::Application]
    # @param config [LintTrappings::Configuration]
    # @param options [Hash]
    # @param output [LintTrappings::Output]
    def initialize(application, config, options, output)
      @application = application
      @config = config
      @options = options
      @output = output
    end

    # Runs the command.
    def run
      raise NotImplementedError, 'Define `execute` in `Command::Base` subclass'
    end

    private

    # @return [LintTrappings::Application]
    attr_reader :application

    # @return [LintTrappings::Configuration]
    attr_reader :config

    # @return [Hash]
    attr_reader :options

    # @return [LintTrappings::Output]
    attr_reader :output
  end
end
