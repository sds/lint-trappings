module LintTrap::Command
  # Outputs help documentation.
  class DisplayHelp < Base
    def run
      output.puts options[:help_message]
    end
  end
end
