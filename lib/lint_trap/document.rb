module LintTrap
  # Represents a parsed document and its associated metadata.
  #
  # Implementors should implement the {#process_source} method.
  #
  # @abstract
  class Document
    # @return [LintTrap::Configuration] configuration used to parse template
    attr_reader :config

    # @return [String, nil] path of the file that was parsed, or nil if it was
    #   parsed directory from a string
    attr_reader :path

    # @return [String] original source code
    attr_reader :source

    # @return [Array<String>] original source code as an array of lines
    attr_reader :source_lines

    # Parses the specified Slim code into a {Document}.
    #
    # @param source [String] Source code to parse
    # @param config [LintTrap::Configuration]
    # @param options [Hash]
    # @option options :path [String] path of document that was parsed
    def initialize(source, config, options = {})
      @config = config
      @path = options[:path]
      @source = source
      @source_lines = @source.split("\n")

      process_source(source)
    end

    private

    # Processes the source code of the document, initializing the document.
    #
    # @raise [LintTrap::ParseError] if there was a problem parsing the document
    def process_source(_source)
      raise NotImplementedError, 'Must implement #process_source'
    end
  end
end
