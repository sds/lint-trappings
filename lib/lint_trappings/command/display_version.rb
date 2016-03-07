require_relative 'base'

module LintTrappings::Command
  # Outputs application version information.
  class DisplayVersion < Base
    def run
      output.bold(application.executable_name, false)
      output.info(application.version)

      if options[:verbose]
        output.bold('Ruby version: ', false)
        output.info(RUBY_VERSION)
      end
    end
  end
end
