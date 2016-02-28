module LintTrappings::Formatter
  # Abstract lint formatter. Subclass and override {#display_report} to
  # implement a custom formatter.
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

      # Used in helpers to determine if severity should be displayed as failure
      # or not
      severities = @config.fetch('severities', error: 'fail', warning: 'warn')
      @fail_severities = severities.select { |_severity, action| action == 'fail' }.keys
      @warn_severities = severities.select { |_severity, action| action == 'warn' }.keys
    end

    # Called at the start of the run once runner has determined all files it
    # will lint.
    def started(_files_to_lint)
    end

    # Called at the beginning of a job for a linter run against a file.
    #
    # This can be called in parallel.
    def job_started(_job)
    end

    # Called at the end of a job for a linter run against a file.
    #
    # This can be called in parallel.
    def job_finished(_job, _lints)
    end

    # Called at the end of the run.
    def finished(_report)
    end

    private

    # @return [LintTrappings::Application]
    attr_reader :application

    # @return [LintTrappings::Configuration]
    attr_reader :config

    # @return [Hash]
    attr_reader :options

    # @return [LintTrappings::Output] stream to send output to
    attr_reader :output

    def failing_lint?(lint)
      @fail_severities.include?(lint.severity)
    end

    def warning_lint?(lint)
      @warn_severities.include?(lint.severity)
    end
  end
end
