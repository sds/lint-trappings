require 'lint_trap/linter_configuration_validator'
require 'ostruct'

module LintTrap
  # Base implementation for all lint checks.
  #
  # @abstract
  class Linter
    class << self
      # Return all subclasses.
      #
      # @return [Array<Class>]
      def descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      # Returns the canonical name for this linter class.
      #
      # The canonical name is used as the key for configuring the linter in the
      # configuration file, or when referring to it from the command line.
      #
      # This uses the "Linter" module as an indicator of when to start removing
      # unnecessary module prefixes.
      #
      # @example
      #   LintTrap::Linter::MyLinter
      #   => "MyLinter"
      #
      # @example
      #   MyCustomNamespace::MyLinter
      #   => "MyCustomNamespace::MyLinter"
      #
      # @example
      #   MyModule::Linter::MyCustomNamespace::MyLinter
      #   => "MyCustomNamespace::MyLinter"
      #
      # @return [String]
      def canonical_name
        @canonical_name ||=
          begin
            full_name = name.to_s.split('::')

            if linter_class_index = full_name.index('Linter')
              # Otherwise, the name follows the `Linter` module
              linter_class_index += 1
            else
              # If not found, include the full name
              linter_class_index = 0
            end

            full_name[linter_class_index..-1].join('::')
          end
      end

      def description(*args)
        if args.any?
          @description = args.first
        else
          @description
        end
      end

      def option(name, options)
        options = options.dup

        @options_spec ||= {}
        opt = @options_spec[name] = {}
        %i[type default description].each do |option_sym|
          opt[option_sym] = options.delete(option_sym) if options[option_sym]
        end

        if options.keys.any?
          raise InvalidOptionSpecificationError,
                "Unknown key `#{options.keys.first}` for `#{name}` option " \
                "specification on linter #{self}"
        end
      end

      def options
        @options_spec || {}
      end

      attr_accessor :options_struct_class
    end

    # Initializes a linter with the specified configuration.
    #
    # @param config [Hash] configuration for this linter
    def initialize(config)
      @orig_hash_config = @config = config
      validate_options_specification
      @config = convert_config_hash_to_struct(@config)
      @lints = []
    end

    # Runs the linter against the given Slim document.
    #
    # @param document [LintTrap::Document]
    def run(document)
      @document = document
      @lints = []
      scan
      @lints
    end

    # Returns the canonical name of this linter's class.
    #
    # @see {LintTrap::Linter.canonical_name}
    #
    # @return [String]
    def canonical_name
      self.class.canonical_name
    end

    private

    attr_reader :config, :document, :lints

    # Scans the document for lints.
    def scan
      raise NotImplementedError, 'Subclass must implement #scan'
    end

    def validate_options_specification
      LinterConfigurationValidator.new.validate(self, @config, self.class.options)
    end

    # List of built-in hook options which are available to every hook
    BUILT_IN_HOOK_OPTIONS = %w[enabled severity include exclude]

    # Converts a configuration hash to a struct so configuration values are
    # accessed via method calls. This is valuable as it provides faster feedback
    # in the event of a typo (you get an error instead of a `nil` value).
    #
    # @return [Struct]
    def convert_config_hash_to_struct(hash)
      option_names = self.class.options.keys
      return OpenStruct.new unless option_names.any?
      self.class.options_struct_class ||= Struct.new(*option_names)

      unknown_keys = (hash.keys - option_names.map(&:to_s) - BUILT_IN_HOOK_OPTIONS)
      if unknown_keys.any?
        option_plural = Utils.pluralize('option', unknown_keys.count)
        raise LinterConfigurationError,
              "Unknown configuration #{option_plural} for #{canonical_name}: " \
              "#{unknown_keys.join(', ')}\n" \
              "Available options: #{(BUILT_IN_HOOK_OPTIONS + option_names).join(', ')}"
      end

      values = option_names.map { |option_name| hash[option_name.to_s] }
      self.class.options_struct_class.new(*values)
    end

    # Record a lint for reporting back to the user.
    #
    # @param range [Range<LintTrap::Location>,#source_range] source range of lint
    # @param message [String] error/warning to display to the user
    def report_lint(range_or_obj, message)
      unless range_or_obj.is_a?(Range) || range_or_obj.respond_to?(:source_range)
        raise LinterError,
              '`report_lint` must be given a Range or an object ' \
              "that responds to `source_range`, but was given: #{range_or_obj.inspect}"
      end

      @lints << Lint.new(
        linter: self,
        path: @document.path,
        source_range: range_or_obj.is_a?(Range) ? range_or_obj : range_or_obj.source_range,
        message: message,
        severity: @orig_hash_config.fetch('severity'),
      )
    end

    # Shortcut for creating a range for a single location.
    #
    # @return [Range<LintTrap::Location>]
    def location(*args)
      loc = Location.new(*args)
      loc..loc
    end
  end
end
