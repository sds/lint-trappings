require 'pathname'
require 'yaml'

module LintTrappings
  # Manages configuration file loading.
  class ConfigurationLoader
    def initialize(application)
      @application = application
    end

    # Load configuration file given the current working directory the
    # application is running within.
    #
    # @param options [Hash]
    # @option options :working_directory [String] directory to start searching
    #   from
    #
    # @raise [NoConfigurationFileError] if no configuration file was found
    #
    # @return [LintTrappings::Configuration]
    def load(options = {})
      config_file_names = @application.configuration_file_names
      working_directory = options.fetch(:working_directory, Dir.pwd)

      directory = File.expand_path(working_directory)
      config_file = possible_config_files(config_file_names, directory).find(&:file?)

      if config_file
        load_file(config_file.to_path)
      else
        raise NoConfigurationFileError,
              "No configuration file #{config_file_names.join('/')} found in " \
              'working directory or any parent directory'
      end
    end

    # Loads a configuration, ensuring it extends the base configuration.
    #
    # @param path [String]
    #
    # @raise [LintTrappings::ConfigurationParseError] YAML file could not be parsed
    # @raise [LintTrappings::NoConfigurationFileError] specified file not found
    #
    # @return [LintTrappings::Configuration]
    def load_file(path)
      load_from_file(path)
    rescue ::Psych::SyntaxError => error
      raise ConfigurationParseError,
            "Unable to parse configuration from '#{file}': #{error}",
            error.backtrace
    rescue Errno::ENOENT => error
      raise NoConfigurationFileError,
            "Unable to load configuration from '#{file}': #{error}"
    end

    private

    def configuration_class
      @application.base_configuration.class
    end

    # Parses and loads a configuration from the given file.
    #
    # @param path [String]
    #
    # @return [LintTrappings::Configuration]
    def load_from_file(path)
      hash =
        if yaml = YAML.load_file(path)
          yaml.to_hash
        else
          {}
        end

      configuration_class.new(hash).tap do |config|
        config.path = path
      end
    end

    # Returns an enumerator for the possible configuration file paths given
    # the context of the specified working directory.
    #
    # @param config_file_name [String]
    # @param directory [String]
    #
    # @return [Array<Pathname>]
    def possible_config_files(config_file_names, directory)
      Enumerator.new do |y|
        Pathname.new(directory)
                .enum_for(:ascend)
                .each do |path|
          config_file_names.each { |config_name| y << (path + config_name) }
        end
        config_file_names.each { |config_name| y << Pathname.new(config_name) }
      end
    end
  end
end
