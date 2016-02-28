module LintTrappings
  # Contains information about a problem or issue with a document.
  class Lint
    # @return [LintTrappings::Linter, nil] linter that reported the lint (if applicable)
    attr_reader :linter

    # @return [String] file path to which the lint applies
    attr_reader :path

    # @return [Range<LintTrappings::Location>] source range of the problem within the file
    attr_reader :source_range

    # @return [String] message describing the lint
    attr_reader :message

    # @return [Symbol] whether this lint is a warning or an error
    attr_reader :severity

    # @return [Exception] the exception that was raised, if any
    attr_reader :exception

    # @param options [Hash]
    # @option options :linter [LintTrappings::Linter] optional
    # @option options :path [String]
    # @option options :source_range [Range<LintTrappings::Location>]
    # @option options :message [String]
    # @option options :severity [Symbol]
    def initialize(options)
      @linter       = options[:linter]
      @path         = options.fetch(:path)
      @source_range = options.fetch(:source_range)
      @message      = options.fetch(:message)
      @severity     = options.fetch(:severity)
      @exception    = options[:exception]
    end
  end
end
