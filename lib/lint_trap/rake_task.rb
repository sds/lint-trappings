require 'rake'
require 'rake/tasklib'

module LintTrap
  # Rake task interface factory for a LintTrap application.
  #
  # In your application, define your Rake task factory class as:
  #
  #   require 'lint_trap/rake_task'
  #   require 'my_app'
  #
  #   module MyApp
  #     class RakeTask < LintTrap::RakeTask
  #       def initialize(name = :my_app)
  #         @application_class = MyApp::Application
  #         super
  #       end
  #     end
  #   end
  #
  # Then developers can follow the instructions below (swapping out MyApp/my_app
  # with the appropriate name of your application) to invoke your application
  # via Rake.
  #
  # @example
  #   # Add the following to your Rakefile...
  #   require 'my_app/rake_task'
  #
  #   MyApp::RakeTask.new do |t|
  #     t.config = 'path/to/custom/config.yml'
  #     t.files = %w[app/views/**/*.txt custom/*.txt]
  #     t.quiet = true # Don't display output from app
  #   end
  #
  #   # ...and then execute from the command line:
  #   rake my_app
  #
  # You can also specify the list of files as explicit task arguments:
  #
  # @example
  #   # Add the following to your Rakefile...
  #   require 'my_app/rake_task'
  #
  #   MyApp::RakeTask.new
  #
  #   # ...and then execute from the command line:
  #   rake my_app[some/directory, some/specific/file.txt]
  #
  class RakeTask < Rake::TaskLib
    # Name of the task.
    # @return [String]
    attr_accessor :name

    # Path of the configuration file to use.
    # @return [String]
    attr_accessor :config

    # List of files to lint.
    #
    # Note that this will be ignored if you explicitly pass a list of files as
    # task arguments via the command line.
    # @return [Array<String>]
    attr_accessor :files

    # Whether output from application should not be displayed to the standard
    # out stream.
    # @return [true,false]
    attr_accessor :quiet

    # Create the task so it exists in the current namespace.
    #
    # @param name [Symbol] task name
    def initialize(name)
      @name = name
      @files = []
      @quiet = false

      # Allow custom configuration to be defined in a block passed to constructor
      yield self if block_given?

      define
    end

    private

    # Defines the Rake task.
    def define
      desc default_description unless ::Rake.application.last_description

      task(name, [:files]) do |_task, task_args|
        run_cli(task_args)
      end
    end

    # Executes the CLI given the specified task arguments.
    #
    # @param task_args [Rake::TaskArguments]
    def run_cli(task_args)
      raise ArgumentError, '@application_class must be defined!' unless @application_class

      output = quiet ? LintTrap::Output.silent : LintTrap::Output.new(STDOUT)
      app = @application_class.new(output)

      options = {}.tap do |opts|
        opts[:command] = :scan
        opts[:config_file] = @config if @config
        opts[:included_paths] = files_to_lint(task_args)
      end

      begin
        app.run(options) # Will raise exception on failure
      rescue LintTrap::ScanWarned
        puts "#{app.name} reported warnings"
      end
    end

    # Returns the list of files that should be linted given the specified task
    # arguments.
    #
    # @param task_args [Rake::TaskArguments]
    def files_to_lint(task_args)
      # Note: we're abusing Rake's argument handling a bit here. We call the
      # first argument `files` but it's actually only the first file--we pull
      # the rest out of the `extras` from the task arguments. This is so we
      # can specify an arbitrary list of files separated by commas on the
      # command line or in a custom task definition.
      explicit_files = Array(task_args[:files]) + Array(task_args.extras)

      explicit_files.any? ? explicit_files : @files
    end

    # Friendly description that shows up in Rake task listing.
    #
    # This allows us to change the information displayed by `rake --tasks` based
    # on the options passed to the constructor which defined the task.
    #
    # @return [String]
    def default_description
      description = "Run `#{@application_class.name}`"
      description << ' quietly' if @quiet
      description << " using config file #{@config}" if @config
      description
    end
  end
end
