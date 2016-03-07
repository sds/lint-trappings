module LintTrappings
  # Represents a collection of linters/configuration which are loaded from a
  # gem.
  #
  # This is just a wrapper to make accessing files in the gem easier.
  class LinterPlugin
    # @param require_path [String] name of the gem (must be the same as the path
    #   to `require`!)
    def initialize(require_path)
      @require_path = require_path
      require @require_path
    rescue LoadError, SyntaxError => ex
      raise LinterLoadError,
            "Unable to load linter plugin at path '#{@require_path}': #{ex.message}"
    end

    # Returns path to the configuration file that ships with this linter plugin.
    #
    # Note that this may not exist if no configuration is shipped with the gem.
    #
    # @return [String]
    def config_file_path
      File.join(gem_dir, 'config.yaml')
    end

    private

    def gem_dir
      Gem::Specification.find_by_name(@require_path).gem_dir
    end
  end
end
