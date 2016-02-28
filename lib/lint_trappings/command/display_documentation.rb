require 'terminal-table'

module LintTrappings::Command
  # Displays documentation for the specified linter
  class DisplayDocumentation < Base
    def run
      LintTrappings::LinterLoader.new(application, config).load(options)

      output.info 'Linter Documentation'
      output.info '--------------------'

      linter_classes(options).sort_by(&:canonical_name).each do |linter_class|
        display_linter_doc(linter_class)
      end
    end

    private

    def display_linter_doc(linter_class)
      output.newline
      output.notice linter_class.canonical_name
      output.puts linter_class.description
      output.newline

      return unless linter_class.options.any?

      table = Terminal::Table.new do |t|
        t << %w[Option Description Type Default]

        t.add_separator

        linter_class.options.each do |option_name, option_spec|
          t << [
            option_name,
            option_spec[:description],
            option_spec[:type],
            display_value(option_spec[:default]),
          ]
        end
      end

      output.puts table.to_s
    end

    def display_value(value)
      if value.is_a?(Array)
        value.map { |v| "- #{v}" }.join("\n")
      else
        value
      end
    end

    def linter_classes(options)
      if options[:linter]
        begin
          [application.linter_base_class.const_get(options[:linter])]
        rescue NameError
          raise NoSuchLinter, "No linter named #{options[:linter]} exists!"
        end
      else
        application.linter_base_class.descendants
      end
    end
  end
end
