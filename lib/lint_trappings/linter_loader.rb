module LintTrappings
  # Loads linters so they can be run.
  class LinterLoader
    def initialize(application, config)
      @application = application
      @config = config
    end

    # Load linters into memory so they can be instantiated.
    #
    # @param options [Hash]
    #
    # @raise [LinterLoadError] problem loading a linter file/library
    def load(options)
      load_directory(@application.linters_directory)

      Array(@config['linter_directories']).each do |directory|
        load_directory(File.expand_path(directory, File.dirname(@config.path)))
      end

      Array(options[:linter_directories]).each do |directory|
        load_directory(directory)
      end

      # NOTE: Linter plugins get loaded via the ConfigurationResolver. While it
      # would seem to make more sense for the LinterLoader to do this, the
      # resolver needs to since the plugins might have configuration files that
      # need to be merged.
    end

    private

    # Recursively load all files in a directory and its subdirectories.
    def load_directory(directory)
      # NOTE: While it might seem inefficient to load ALL linters (rather than
      # only ones which are enabled), the reality is that the difference is
      # negligible with respect to the application's startup time. It's also
      # very difficult to do, as you can't infer the file name from the linter
      # name (since the user can use any naming scheme they desire)
      Dir[File.join(directory, '**', '*.rb')].each do |path|
        load_path(path)
      end
    end

    def load_path(path)
      Kernel.load path
    rescue LoadError, SyntaxError => ex
      raise LinterLoadError,
            "Unable to load linter file '#{path}': #{ex.message}"
    end
  end
end
