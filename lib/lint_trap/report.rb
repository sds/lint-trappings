module LintTrap
  # Contains information about all lints detected during a scan.
  class Report
    # List of lints that were found.
    # @return [Array<LintTrap::Lint]
    attr_accessor :lints

    # @return [Array<String>] List of files that were inspected.
    attr_reader :documents_inspected

    # @param config [LintTrap::Configuration]
    # @param lints [Array<LintTrap::Lint>] lints that were found
    # @param documents [Array<Document>] files that were linted
    def initialize(config, lints, documents)
      @config = config
      @lints = lints.sort_by { |lint| [lint.path, lint.source_range.begin.line] }
      @documents_inspected = documents
    end

    def severities
      @severities ||= @config.fetch('severities', error: 'fail', warning: 'warn')
    end

    def fail_severities
      @fail_severities ||= severities.select { |_severity, action| action == 'fail' }.keys
    end

    def warn_severities
      @warn_severities ||= severities.select { |_severity, action| action == 'warn' }.keys
    end

    def failures?
      failures.any?
    end

    def failures
      @failures ||=
        begin
          @lints.select { |lint| fail_severities.include?(lint.severity) }
        end
    end

    def warnings?
      warnings.any?
    end

    def warnings
      @warnings ||=
        begin
          @lints.select { |lint| warn_severities.include?(lint.severity) }
        end
    end

    def success?
      lints.empty?
    end
  end
end
