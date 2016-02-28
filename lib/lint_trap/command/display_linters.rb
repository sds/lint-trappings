require 'set'

module LintTrap::Command
  # Displays all available linters and whether or not they are enabled.
  class DisplayLinters < Base
    def run
      LintTrap::LinterLoader.new(application, config).load(options)

      linter_selector = LintTrap::LinterSelector.new(config, options)
      all_linter_names = linter_selector.all_linter_classes.map(&:canonical_name)
      enabled_linter_names = linter_selector.enabled_linter_classes.map(&:canonical_name).to_set

      all_linter_names.sort.each do |linter_name|
        output.print(' - ')
        output.bold(linter_name, false)
        if enabled_linter_names.include?(linter_name)
          output.success(' enabled')
        else
          output.error(' disabled')
        end
      end
    end
  end
end
