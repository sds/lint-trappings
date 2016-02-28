module LintTrappings
  # Chooses the appropriate linters to run against a file.
  #
  # All linter inclusion/exclusion based on command line flags or configuration
  # is handled here. This is utilized by the runner to generate linter/file
  # tuples representing jobs to execute (i.e. run the linter X against file Y).
  class LinterSelector
    # @param application [LintTrappings::Application]
    # @param config [LintTrappings::Configuration]
    # @param options [Hash]
    #
    # @raise [LintTrappings::NoLintersError] when no linters are enabled
    def initialize(application, config, options)
      @application = application
      @config = config
      @options = options

      # Pre-compute this as it is expensive to calculate and used many times.
      # This forces any errors in the configuration to be surfaced ahead of time.
      @enabled_linter_classes = enabled_linter_classes
    end

    # Return all loaded linter classes for this application.
    # @return [Array<Class>]
    def all_linter_classes
      @application.linter_base_class.descendants
    end

    # Returns initialized linter instances to run against a given file.
    #
    # @param path [String]
    #
    # @return [Array<LintTrappings::Linter>]
    def linters_for_file(path)
      @enabled_linter_classes.map do |linter_class|
        linter_conf = @config.for_linter(linter_class)
        next unless run_linter_on_file?(linter_conf, path)

        linter_class.new(linter_conf)
      end.compact
    end

    # Returns a list of linters that are enabled given the specified
    # configuration and additional options.
    #
    # @return [Array<LintTrappings::Linter>]
    def enabled_linter_classes
      # Include the explicit list of linters if a list was specified
      explicitly_included = included_linter_classes =
        linter_classes_from_names(@options.fetch(:included_linters, []))

      if included_linter_classes.empty?
        # Otherwise use the list of enabled linters specified by the config.
        # Note: this means that a linter which is disabled in the configuration
        # can still be run if it is explicitly specified in `included_linters`
        included_linter_classes = all_linter_classes.select do |linter_class|
          linter_enabled?(linter_class)
        end
      end

      excluded_linter_classes =
        linter_classes_from_names(@options.fetch(:excluded_linters, []))

      linter_classes = included_linter_classes - excluded_linter_classes

      # Highlight conditions where all linters were filtered out, as this was
      # likely a mistake on the user's part
      if linter_classes.empty?
        if explicitly_included.any?
          raise NoLintersError,
                'All specified linters were explicitly excluded!'
        elsif included_linter_classes.empty?
          raise NoLintersError,
                'All linters are disabled. Enable some in your configuration!'
        else
          raise NoLintersError,
                'All enabled linters were explicitly excluded!'
        end
      end

      linter_classes
    end

    private

    # Whether to run the given linter against the specified file.
    #
    # @param linter_conf [Hash]
    # @param path [String]
    #
    # @return [Boolean]
    def run_linter_on_file?(linter_conf, path)
      if linter_conf['include'] &&
         !Utils.any_glob_matches?(linter_conf['include'], path)
        return false
      end

      if Utils.any_glob_matches?(linter_conf['exclude'], path)
        return false
      end

      true
    end

    def linter_enabled?(linter_class)
      @config.for_linter(linter_class)['enabled']
    end

    def linter_classes_from_names(linter_names)
      linter_names.map do |linter_name|
        begin
          @application.linter_base_class.const_get(linter_name)
        rescue NameError
          raise NoSuchLinter,
                "Linter #{linter_name} does not exist! Are you sure you spelt it correctly?"
        end
      end
    end
  end
end
