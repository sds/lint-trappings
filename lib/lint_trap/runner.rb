require 'lint_trap/formatter_forwarder'
require 'lint_trap/formatter_loader'
require 'lint_trap/preprocessor'

module LintTrap
  # Linter runner.
  #
  # Runs linters against a set of files, ensuring the appropriate linters are
  # run against the relevant files based on configuration.
  class Runner
    def initialize(application, config, output)
      @application = application
      @config = config
      @output = output
    end

    # A individual unit of work which can be processed by a worker.
    Job = Struct.new(:linter, :path)

    # Runs the appropriate linters against the set of specified files, return a
    # report of all lints found.
    #
    # @param options [Hash]
    #
    # @return [LintTrap::Report] report of all lints found and other statistics
    def run(options = {})
      @options = options

      # Coalesce formatters into a single formatter which will forward calls
      formatters = FormatterLoader.new(@application, @config, @output).load(options)
      @formatter = FormatterForwarder.new(formatters)

      # We store the documents in a map so that if we're parallelizing the run
      # we don't need to pass serialized Document objects via IPC, just the path
      # string.  Since forking will use copy-on-write semantics, we'll be able
      # to reuse the memory storing those documents for all workers, since we're
      # just reading.
      @paths_to_documents_map, parse_lints = load_documents_to_lint(options)

      # Extract all jobs we want to run as file/linter pairs
      linter_selector = LinterSelector.new(@application, @config, options)
      jobs = @paths_to_documents_map.keys.map do |path|
        linter_selector.linters_for_file(path).map { |linter| Job.new(linter, path) }
      end.flatten

      lints = find_all_lints(jobs) + parse_lints
      report = Report.new(@config, lints, @paths_to_documents_map.values)

      @formatter.finished(report)

      report
    end

    private

    # A file to be linted.
    FileToLint = Struct.new(:io, :path)

    def determine_files_to_lint(options)
      if options[:stdin_file_path]
        [FileToLint.new(options[:stdin], options[:stdin_file_path])]
      else
        find_files(options).map do |path|
          FileToLint.new(File.open(path), path)
        end
      end
    rescue Errno::ENOENT => err
      raise InvalidFilePathError, err.message
    end

    def find_files(options)
      opts = {}
      opts[:allowed_extensions] = @config.fetch(:file_extensions, @application.file_extensions)

      opts[:included_paths] = options.fetch(:included_paths, @config.fetch(:included_paths, []))
      opts[:excluded_paths] = @config.fetch(:excluded_paths, []) +
                              options.fetch(:excluded_paths, [])

      opts[:included_patterns] = @config.fetch(:include) do
        if opts[:included_paths].any?
          # Don't specify default inclusion pattern since include paths were
          # explicitly specified
          []
        else
          # Otherwise, we want the default behavior to lint all files with the
          # default file extensions
          opts[:allowed_extensions].map { |ext| "**/*.#{ext}" }
        end
      end
      opts[:excluded_patterns] = @config.fetch(:exclude, [])

      FileFinder.find(opts)
    end

    def load_documents_to_lint(options)
      documents = {}
      parse_lints = []

      files_to_lint = determine_files_to_lint(options)
      Preprocessor.new(@config).preprocess_files(files_to_lint)
      @formatter.started(files_to_lint)

      files_to_lint.each do |file_to_lint|
        begin
          documents[file_to_lint.path] =
            @application.document_class.new(file_to_lint.io.read,
                                            @config,
                                            path: file_to_lint.path)
        rescue ParseError => err
          parse_lints << Lint.new(
            path: file_to_lint.path,
            source_range: err.source_range,
            message: "Error occurred while parsing #{file_to_lint.path}: #{err.message}",
            severity: :error,
          )
        end
      end

      [documents, parse_lints]
    end

    def scan_document(job)
      @formatter.job_started(job)

      document = @paths_to_documents_map[job.path]
      reported_lints = job.linter.run(document)

      @formatter.job_finished(job, reported_lints)

      reported_lints
    rescue => err
      loc = Location.new(1)
      message = "Error occurred while linting #{job.path}: #{err.message}"

      lints = [Lint.new(
        linter: job.linter,
        path: job.path,
        source_range: loc..loc,
        message: message,
        severity: :error,
        exception: err,
      )]

      @formatter.job_finished(job, lints)
      lints
    end

    def find_all_lints(jobs)
      lints =
        if workers = @options[:concurrency]
          require 'parallel'
          workers = workers == 'auto' ? Parallel.processor_count : Integer(workers)
          ::Parallel.map(jobs, { in_processes: workers }, &method(:scan_document))
        else
          jobs.map(&method(:scan_document))
        end

      lints.flatten
    end
  end
end
