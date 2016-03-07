require 'optparse'

module LintTrappings
  # Handles option parsing for the command line application.
  class ArgumentsParser # rubocop:disable Metrics/ClassLength
    def initialize(application)
      @application = application
    end

    # Parses command line options into an options hash.
    #
    # @param args [Array<String>] arguments passed via the command line
    #
    # @return [Hash] parsed options
    def parse(args)
      @options = {}
      @options[:command] = :scan # Default command is to scan for lints

      OptionParser.new do |parser|
        parser.banner = "Usage: #{@application.executable_name} [options] [file1, file2, ...]"

        add_linter_options parser
        add_file_options parser
        add_misc_options parser
        add_info_options parser
      end.parse!(args)

      # Any remaining arguments are assumed to be files that should be linted
      @options[:included_paths] = args

      @options
    rescue OptionParser::InvalidOption => ex
      raise InvalidCliOptionError,
            "#{ex.message}\nRun `#{@application.executable_name} --help` to " \
            'see a list of available options.'
    end

    private

    # Register file-related flags.
    def add_file_options(parser)
      parser.on('-c', '--config config-file', String,
                'Specify which configuration file you want to use') do |conf_file|
        @options[:config_file] = conf_file
      end

      parser.on('-e', '--exclude-path file', String,
                'List of file paths to exclude') do |file_path|
        (@options[:excluded_paths] ||= []) << file_path
      end

      parser.on('-f', '--format formatter-name', String,
                'Specify which output format you want') do |formatter_name|
        (@options[:formatters] ||= []) << {
          formatter_name => :stdout,
        }
      end

      parser.on('-o', '--out output-file-path', String,
                'Specify a file to write output to') do |file_path|
        redirect_formatter(file_path)
      end

      parser.on('--stdin-file-path file-path', String,
                'Specify the path name for the file passed via STDIN') do |file_path|
        @options[:stdin] = STDIN
        @options[:stdin_file_path] = file_path
      end

      parser.on('-r', '--require require-path', String,
                'Specify a path to `require`') do |require_path|
        (@options[:require_paths] ||= []) << require_path
      end

      parser.on('-p', '--plugin plugin-require-path', String,
                'Specify a path to `require` to load a linter plugin') do |require_path|
        (@options[:linter_plugins] ||= []) << require_path
      end
    end

    # Register linter-related flags.
    def add_linter_options(parser)
      parser.on('-i', '--include-linter linter', String,
                'Specify which linters you want to run ' \
                '(overrides those in your configuration)') do |linter|
        (@options[:included_linters] ||= []).concat(linter.split(/\s*,\s*/))
      end

      parser.on('-x', '--exclude-linter linter', String,
                "Specify which linters you don't want to run " \
                '(in addition to those disabled by your configuration)') do |linter|
        (@options[:excluded_linters] ||= []).concat(linter.split(/\s*,\s*/))
      end
    end

    def add_misc_options(parser)
      parser.on('-C', '--concurrency workers', Integer,
                'Specify the number of concurrent workers you want') do |workers|
        raise InvalidCliOptionError, 'Concurrency cannot be < 1' if workers < 1
        @options[:concurrency] = workers
      end
    end

    # Register informational flags.
    def add_info_options(parser)
      parser.on('--show-linters',
                'Display available linters and whether or not they are enabled') do
        @options[:command] = :display_linters
      end

      parser.on('--show-formatters', 'Display available formatters') do
        @options[:command] = :display_formatters
      end

      parser.on('--show-docs [linter-name]', '--show-documentation [linter-name]') do |linter_name|
        @options[:command] = :display_documentation
        @options[:linter] = linter_name if linter_name
      end

      parser.on('--[no-]color', 'Force output to be colorized') do |color|
        @options[:color] = color
      end

      parser.on('-d', '--debug', 'Enable debug mode for more verbose output') do
        @options[:debug] = true
      end

      parser.on_tail('-h', '--help', 'Display help documentation') do
        @options[:command] = :display_help
        @options[:help_message] = parser.help
      end

      parser.on_tail('-v', '--version', 'Display version') do
        @options[:command] = :display_version
      end

      parser.on_tail('-V', '--verbose-version', 'Display verbose version information') do
        @options[:command] = :display_version
        @options[:verbose_version] = true
      end
    end

    def redirect_formatter(file_path)
      if @options[:formatters]
        # Change the last specified formatter to output to the given file
        last_formatter = @options[:formatters].last
        formatter_name = last_formatter.keys.first
        if last_formatter[formatter_name] == :stdout
          # Write output to file
          last_formatter[formatter_name] = file_path
        else
          # Otherwise this formatter's output has already been set to a file,
          # so assume the user wants to output the same format to two
          # different files
          @options[:formatters] << { formatter_name => file_path }
        end
      else
        # Otherwise if no formatters have been specified yet, set the default
        # formatter to write to the given file
        @options[:formatters] = [{ 'Default' => file_path }]
      end
    end
  end
end
