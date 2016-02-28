require 'lint_trappings/formatter/base'

module LintTrappings::Formatter
  # Outputs lints in a simple format with the filename, line number, and lint
  # message.
  class Default < Base
    def started(files_to_lint)
      files = LintTrappings::Utils.pluralize('file', files_to_lint.count)
      output.info "Scanning #{files_to_lint.count} #{files}..."
    end

    def job_finished(_job, lints)
      @at_least_one_job_finished = true

      if lints.any? { |lint| failing_lint?(lint) }
        output.error 'F', false
      elsif lints.any? { |lint| warning_lint?(lint) }
        output.warning 'W', false
      else
        output.success '.', false
      end
    end

    def finished(report)
      # Ensure we have a newline after the last progress dot output
      output.newline if @at_least_one_job_finished

      report.lints.each do |lint|
        print_location(lint)
        print_message(lint)
      end

      output.newline

      files = LintTrappings::Utils.pluralize('file', report.documents_inspected.count)
      output.print "#{report.documents_inspected.count} #{files} inspected"

      if report.failures?
        failures = LintTrappings::Utils.pluralize('failure', report.failures.count)
        output.print ', '
        output.error "#{report.failures.count} #{failures} reported", false
      end

      if report.warnings?
        warnings = LintTrappings::Utils.pluralize('warning', report.warnings.count)
        output.print ', '
        output.warning "#{report.warnings.count} #{warnings} reported", false
      end

      if report.success?
        output.print ', '
        output.success 'no issues reported', false
      end

      output.newline
    end

    private

    def print_location(lint)
      output.info lint.path, false
      output.puts ':', false
      output.bold lint.source_range.begin.line, false
      output.print ':'
      output.bold lint.source_range.begin.column, false
      output.print ' '
    end

    def print_message(lint)
      if failing_lint?(lint)
        output.error severity_character(lint.severity), false
      elsif warning_lint?(lint)
        output.warning severity_character(lint.severity), false
      end

      if lint.linter
        output.notice("[#{lint.linter.canonical_name}] ", false)
      end

      message = lint.message
      if lint.exception
        message << ' (specify --debug flag to see backtrace)' unless options[:debug]
      end
      output.puts message

      print_exception(lint)
    end

    def print_exception(lint)
      return unless lint.exception && options[:debug]
      output.error "#{lint.exception.class}: #{lint.exception.message}"
      output.error lint.exception.backtrace.join("\n")
    end

    def severity_character(severity)
      "#{severity.to_s[0].capitalize} "
    end
  end
end
