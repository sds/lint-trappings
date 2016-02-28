module LintTrap::Command
  # Scan for lints, outputting report of results using the specified formatter.
  class Scan < Base
    def run
      LintTrap::LinterLoader.new(application, config).load(options)

      runner = LintTrap::Runner.new(application, config, output)
      report = runner.run(options)

      if report.failures?
        raise LintTrap::ScanFailed,
              'High severity lints were reported!'
      elsif report.warnings?
        raise LintTrap::ScanWarned,
              'Warnings were reported.'
      end
    end
  end
end
