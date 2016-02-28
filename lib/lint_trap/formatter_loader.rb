module LintTrap
  # Loads the configured formatters.
  class FormatterLoader
    def initialize(application, config, output)
      @application = application
      @config = config
      @output = output
    end

    def load(options)
      outputs = options.fetch(:formatters, [{ 'Default' => :stdout }])

      outputs.map do |output_specification|
        output_specification.map do |formatter_name, output_path|
          load_formatter(formatter_name)
          create_formatter(formatter_name, output_path, options)
        end
      end.flatten
    end

    private

    def load_formatter(formatter_name)
      formatter_path = File.join('lint_trap', 'formatter', Utils.snake_case(formatter_name))
      require formatter_path
    rescue LoadError, SyntaxError => ex
      raise FormatterLoadError,
            "Unable to load formatter `#{formatter_name}`: #{ex.message}"
    end

    def create_formatter(formatter_name, output_path, options)
      output_dest =
        if output_path == :stdout
          @output
        else
          Output.new(File.open(output_path, File::CREAT | File::WRONLY))
        end

      Formatter.const_get(formatter_name).new(@application, @config, options, output_dest)
    rescue NameError => ex
      raise FormatterLoadError,
            "Unable to create formatter `#{formatter_name}`: #{ex.message}"
    end
  end
end
