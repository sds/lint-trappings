require_relative 'base'

module LintTrappings::Command
  # Displays all available formatters.
  class DisplayFormatters < Base
    def run
      formatter_names = LintTrappings::Formatter::Base.descendants.map do |formatter_class|
        formatter_class.name.split('::').last.sub(/Formatter$/, '').downcase
      end

      formatter_names.sort.each do |formatter_name|
        output.puts " - #{formatter_name}"
      end
    end
  end
end
