module LintTrap::Command
  # Abstract base class of all commands.
  #
  # @abstract
  class Base
    # @param application [LintTrap::Application]
    # @param config [LintTrap::Configuration]
    # @param options [Hash]
    # @param output [LintTrap::Output]
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

    # @return [LintTrap::Application]
    attr_reader :application

    # @return [LintTrap::Configuration]
    attr_reader :config

    # @return [Hash]
    attr_reader :options

    # @return [LintTrap::Output]
    attr_reader :output
  end
end
