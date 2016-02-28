module LintTrap
  # Validates a linter's configuration options.
  class LinterConfigurationValidator
    # Verifies the configuration passed to this linter satisfies the options
    # specifications declared in the linter class.
    #
    # @param linter [LintTrap::Linter]
    # @param config [Hash]
    # @param options_specs [Hash]
    def validate(linter, config, options_specs)
      insert_default_values(config, options_specs)
      check_option_types(linter, config, options_specs)
    end

    private

    def check_option_types(linter, config, options_specs)
      options_specs.select do |option_name, option_spec|
        expected_class = option_spec[:type]
        actual_value = config[option_name.to_s]
        actual_class = actual_value.class

        # If the class isn't the same or a subclass, it's different
        next if actual_class <= expected_class

        raise LinterConfigurationError,
              "Option `#{option_name}` for linter " \
              "#{linter.canonical_name} must be of " \
              "type #{expected_class}, but was #{actual_class} (#{actual_value.inspect})!"
      end
    end

    def insert_default_values(config, options_specs)
      options_specs.select do |option_name, option_spec|
        option_name_str = option_name.to_s
        next unless option_spec.key?(:default) && !config.key?(option_name_str)

        config[option_name_str] = option_spec[:default]
      end
    end
  end
end
