require 'lint_trappings/file_finder'
require 'lint_trappings/preprocessor'

module LintTrappings
  # Loads the set of files to be linted as {Document} objects.
  class DocumentLoader
    # A file to be linted.
    FileToLint = Struct.new(:io, :path)

    def initialize(application, config, formatter)
      @application = application
      @config = config
      @formatter = formatter
    end

    # Load the set of documents to lint.
    #
    # Returns a tuple of the list of documents and a list of lints representing
    # the errors reported for the documents that could not be parsed.
    #
    # @param options [Hash] options parsed by {LintTrappings::ArgumentsParser}
    #
    # @return [Array<LintTrappings::Document>, Array<LintTrappings::Lint>]
    def load(options)
      documents = []
      parse_lints = []

      files_to_lint = determine_files_to_lint(options)
      Preprocessor.new(@config).preprocess_files(files_to_lint)
      @formatter.started(files_to_lint)

      files_to_lint.each do |file_to_lint|
        begin
          documents << @application.document_class.new(file_to_lint.io.read,
                                                       @config,
                                                       path: file_to_lint.path)
        rescue ParseError => err
          parse_lints << Lint.new(
            path: file_to_lint.path,
            source_range: err.source_range,
            message: "Error occurred while parsing #{file_to_lint.path}: #{err.message}",
            severity: @config.fetch('parse_exception_severity', :error),
          )
        end
      end

      [documents, parse_lints]
    end

    def determine_files_to_lint(options)
      if options[:stdin_file_path]
        [FileToLint.new(options[:stdin], options[:stdin_file_path])]
      else
        find_files(options).map do |path|
          FileToLint.new(File.open(path), path)
        end
      end
    rescue Errno::ENOENT => err
      raise InvalidFilePathError, err.message
    end

    def find_files(options)
      opts = {}
      opts[:allowed_extensions] = @config.fetch('file_extensions', @application.file_extensions)

      opts[:included_paths] = options.fetch(:included_paths, @config.fetch('included_paths', []))
      opts[:excluded_paths] = @config.fetch('excluded_paths', []) +
                              options.fetch(:excluded_paths, [])

      opts[:included_patterns] = @config.fetch('include') do
        if opts[:included_paths].any?
          # Don't specify default inclusion pattern since include paths were
          # explicitly specified
          []
        else
          # Otherwise, we want the default behavior to lint all files with the
          # default file extensions
          opts[:allowed_extensions].map { |ext| "**/*.#{ext}" }
        end
      end
      opts[:excluded_patterns] = @config.fetch('exclude', [])

      FileFinder.find(opts)
    end
  end
end
