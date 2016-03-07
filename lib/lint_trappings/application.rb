require 'lint_trappings/errors'
require 'lint_trappings/configuration_loader'
require 'lint_trappings/configuration_resolver'

module LintTrappings
  # Linter application superclass.
  #
  # Implementors will subclass this and specify a number of high-level
  # configuration options which will help the class run your custom application.
  #
  # @abstract
  class Application
    # Define an application configuration attribute.
    #
    # This is intended to be used to make specifying the configuration for a
    # LintTrappings application easy. It defines a class instance variable which is
    # specified in the body of the class itself via DSL-like method call, and
    # also defines a method so the value can be obtained from a single instance.
    def self.class_attribute(attr_name)
      # Define DSL getter/setter
      metaclass = (class << self; self; end)
      metaclass.instance_eval do
        define_method(attr_name) do |*args|
          if args.any?
            instance_variable_set(:"@#{attr_name}", args.first)
          else
            value = instance_variable_get(:"@#{attr_name}")

            if value.nil?
              raise ApplicationConfigurationError,
                    "`#{attr_name}` class attribute must be defined in #{self}!"
            end

            value
          end
        end
      end

      # Define method on the class
      define_method(attr_name) do
        self.class.send(attr_name)
      end
    end

    # @return [String] Proper name of this application
    class_attribute :name

    # @return [String] Name of the application executable
    class_attribute :executable_name

    # @return [String] Application version
    class_attribute :version

    # @return [LintTrappings::Configuration] Base configuration which all other
    #   configurations extend (can be empty if desired). This should be the same
    #   class as the configuration_class attribute.
    class_attribute :base_configuration

    # @return [String] Configuration file names to look for, in order of
    #   precedence (first one found wins)
    class_attribute :configuration_file_names

    # @return [String] List of file extensions the application can lint
    class_attribute :file_extensions

    # @return [String] URL of the application's home page
    class_attribute :home_url

    # @return [String] URL of the application's issue and bug reports page
    class_attribute :issues_url

    # @return [String] Directory prefix where gem stores built-in linters
    class_attribute :linters_directory

    # @return [Class] Base class of all linters for this application
    class_attribute :linter_base_class

    # @return [Class] Class to use when loading/parsing documents
    class_attribute :document_class

    # @param output [LintTrappings::Output]
    def initialize(output)
      @output = output
    end

    def run(options = {})
      configure_color(options)
      config = load_configuration(options)

      command = create_command(options[:command], config, options)
      command.run
    end

    private

    def configure_color(options)
      @output.color_enabled = options.fetch(:color, @output.tty?)
    end

    def create_command(command, config, options)
      raise InvalidCommandError,
            '`command` option must be specified!' unless command

      command = command.to_s

      begin
        require "lint_trappings/command/#{Utils.snake_case(command)}"
      rescue LoadError, SyntaxError => ex
        raise InvalidCommandError,
              "Unable to load command '#{command}': #{ex.message}"
      end

      Command.const_get(Utils.camel_case(command)).new(self, config, options, @output)
    end

    # Loads the application configuration.
    #
    # @param options [Hash]
    #
    # @return [LintTrappings::Configuration]
    def load_configuration(options)
      config_loader = ConfigurationLoader.new(self)

      config =
        if options[:config_file]
          config_loader.load_file(options[:config_file])
        else
          begin
            config_loader.load(working_directory: Dir.pwd)
          rescue NoConfigurationFileError
            Configuration.new # Assume empty configuration
          end
        end

      config = ConfigurationResolver.new(config_loader).resolve(config, options)

      # Always extend the base/default configuration
      base_configuration.merge(config)
    end
  end
end
