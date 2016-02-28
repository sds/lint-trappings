require 'lint_trap/linter_plugin'

module LintTrap
  # Resolves a configuration to its final representation.
  #
  # This does the dirty work of loading and merging a configuration with the
  # configurations it extends via the `extends` option or `linter_gems` option.
  class ConfigurationResolver
    # @param loader [LintTrap::ConfigurationLoader]
    def initialize(loader)
      @loader = loader
    end

    # Resolves the given configuration, returning a configuration with all
    # external configuration files merged into one {Configuration}.
    #
    # @param conf [LintTrap::Configuration]
    def resolve(conf, options)
      configs_to_extend = Array(conf.delete('extends')).map do |extend_path|
        # If the path is relative, expand it relative to the path of this config
        config_path = File.expand_path(extend_path, conf.path)

        # Recursively resolve this configuration (it may have `extends` of its own)
        resolve(@loader.load_file(config_path))
      end

      # Load any configurations included by plugins
      require_paths = Array(conf.delete('linter_plugins')) + options.fetch(:linter_plugins, [])
      configs_to_extend += require_paths.map do |require_path|
        plugin = LinterPlugin.new(require_path)
        plugin.load
        resolve(@loader.load_file(plugin.config_file_path))
      end

      conf = extend_configs(configs_to_extend, conf) if configs_to_extend.any?
      conf
    end

    private

    # Extend the given configurations with the specified config, merging into a
    # single config.
    def extend_configs(configs_to_extend, config)
      configs_to_extend[1..-1].inject(configs_to_extend.first) do |merged, config_to_extend|
        merged.merge(config_to_extend)
      end.merge(config)
    end
  end
end
