require 'lint_trappings/formatter/base'
require 'json'

module LintTrappings::Formatter
  # Outputs report as a JSON document.
  class JSON < Base
    def finished(report)
      lints = report.lints
      grouped = lints.group_by(&:path)

      report_hash = {
        metadata: metadata,
        files: grouped.map { |path, lints_for_path| path_hash(path, lints_for_path) },
        summary: {
          offense_count: lints.count,
          offending_file_count: grouped.count,
          inspected_file_count: report.documents_inspected.count,
        },
      }

      output.puts ::JSON.pretty_generate(report_hash)
    end

    private

    def metadata
      {
        linter_version:   @application.version,
        ruby_engine:      RUBY_ENGINE,
        ruby_version:     RUBY_VERSION,
        ruby_patchlevel:  RUBY_PATCHLEVEL.to_s,
        ruby_platform:    RUBY_PLATFORM,
      }
    end

    def path_hash(path, lints)
      {
        path: path,
        offenses: lints.map { |lint| lint_hash(lint) },
      }
    end

    def lint_hash(lint)
      {
        severity: lint.severity,
        message: lint.message,
        line: lint.source_range.begin.line,
        column: lint.source_range.begin.column,
        source_range: {
          begin: {
            line: lint.source_range.begin.line,
            column: lint.source_range.begin.column,
          },
          end: {
            line: lint.source_range.end.line,
            column: lint.source_range.end.column,
          },
        },
      }
    end
  end
end
