module LintTrappings::Command
  # Scan for lints, outputting report of results using the specified formatter.
  class Scan < Base
    def run
      LintTrappings::LinterLoader.new(application, config).load(options)

      runner = LintTrappings::Runner.new(application, config, output)
      report = runner.run(options)

      if report.failures?
        raise LintTrappings::ScanFailed,
              'High severity lints were reported!'
      elsif report.warnings?
        raise LintTrappings::ScanWarned,
              'Warnings were reported.'
      end
    end
  end
end
