# Collection of errors that can be raised by the framework.
module LintTrappings
  # Abstract error. Separates LintTrappings errors from other kinds of
  # errors in the exception hierarchy.
  #
  # @abstract
  class LintTrappingsError < StandardError
    # Returns the status code that should be output if this error goes
    # unhandled.
    #
    # Ideally these should resemble exit codes from the sysexits documentation
    # where it makes sense.
    def self.exit_status(*args)
      if args.any?
        @exit_status = args.first
      else
        if @exit_status
          @exit_status
        else
          ancestors[1..-1].each do |ancestor|
            return 70 if ancestor == LintTrappingsError # No exit status defined
            return ancestor.exit_status if ancestor.exit_status
          end
        end
      end
    end

    def exit_status
      self.class.exit_status
    end
  end

  # Superclass of all configuration-related errors.
  # @abstract
  class ConfigurationError < LintTrappingsError
    exit_status 78 # EX_CONFIG
  end

  # Raised when a LintTrappings::Application subclass does not set a value for a
  # required configuration attribute.
  class ApplicationConfigurationError < ConfigurationError; end

  # Raised when a configuration file could not be parsed.
  class ConfigurationParseError < ConfigurationError; end

  # Raised when configuration file was not found.
  class NoConfigurationFileError < ConfigurationError; end

  # Raised when a linter's configuration does not match its specification.
  class LinterConfigurationError < ConfigurationError; end

  # Superclass of all usage-related errors
  # @abstract
  class UsageError < LintTrappingsError
    exit_status 64 # EX_USAGE
  end

  # Raised when there was a problem loading a formatter.
  class FormatterLoadError < UsageError; end

  # Raised when invalid/incompatible command line options are specified.
  class InvalidCliOptionError < UsageError; end

  # Raised when invalid command was specified.
  class InvalidCommandError < UsageError; end

  # Raised when an invalid file path is specified.
  class InvalidFilePathError < UsageError; end

  # Raised when an invalid file glob pattern is specified.
  class InvalidFilePatternError < UsageError; end

  # Raised when an invalid option specification is specified for a linter.
  class InvalidOptionSpecificationError < ConfigurationError; end

  # Raised when a linter raises an unexpected error.
  class LinterError < LintTrappingsError; end

  # Raised when an error occurs loading a linter file.
  class LinterLoadError < ConfigurationError; end

  # Raised when an external preprocessor command returns a non-zero exit status.
  class PreprocessorError < LintTrappingsError
    exit_status 84
  end

  # Raised when a report contains lints which qualify as warnings, but does not
  # contain failures.
  class ScanWarned < LintTrappingsError
    exit_status 0 # Don't fail for warnings
  end

  # Raised when a report contains lints which qualify as failures.
  class ScanFailed < LintTrappingsError
    exit_status 2
  end

  # Raised when running with options that would result in no linters being
  # enabled.
  class NoLintersError < ConfigurationError; end

  # Raised when there was a problem parsing a document.
  class ParseError < LintTrappingsError
    # @return [String] path to the file that failed to parse
    attr_reader :path

    # @return [Range<LintTrappings::Location>] source range of the parse error
    attr_reader :source_range

    def initialize(options)
      @message = options[:message]
      @path = options[:path]

      if @source_range = options[:source_range]
        @line = @source_range.begin.line
        @column = @source_range.begin.column
      end
    end

    def message
      msg = @message
      msg << " on line #{@line}" if @line
      msg << ", column #{@column}" if @column
      msg
    end
  end
end
