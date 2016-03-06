require 'lint_trappings/document_loader'
require 'lint_trappings/formatter_forwarder'
require 'lint_trappings/formatter_loader'

module LintTrappings
  # Linter runner.
  #
  # Runs linters against a set of files, ensuring the appropriate linters are
  # run against the relevant files based on configuration.
  class Runner
    # A individual unit of work which can be processed by a concurrent worker.
    Job = Struct.new(:linter, :path)

    def initialize(application, config, output)
      @application = application
      @config = config
      @output = output
    end

    # Runs the appropriate linters against the set of specified files, return a
    # report of all lints found.
    #
    # @param options [Hash] options parsed by {LintTrappings::ArgumentsParser}
    #
    # @return [LintTrappings::Report] report of all lints found and other statistics
    def run(options = {})
      @options = options

      @formatter = FormatterForwarder.new(load_formatters)
      documents, parse_lints = load_documents

      # We store the documents in a map so that if we're parallelizing the run
      # we don't need to pass serialized Document objects via IPC, just the path
      # string.  Since forking will use copy-on-write semantics, we'll be able
      # to reuse the memory storing those documents for all workers, since we're
      # just reading.
      @paths_to_documents_map = documents.each_with_object({}) do |document, hash|
        hash[document.path] = document
      end

      jobs = determine_jobs_to_run(documents)

      lints = find_all_lints(jobs) + parse_lints
      report = Report.new(@config, lints, documents)
      @formatter.finished(report)

      report
    end

    private

    def load_formatters
      FormatterLoader.new(@application, @config, @output).load(@options)
    end

    def load_documents
      DocumentLoader.new(@application, @config, @formatter).load(@options)
    end

    def determine_jobs_to_run(documents)
      # Extract all jobs we want to run as file/linter pairs
      linter_selector = LinterSelector.new(@application, @config, @options)
      documents.map do |document|
        linter_selector.linters_for_file(document.path).map do |linter|
          Job.new(linter, document.path)
        end
      end.flatten
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
        severity: @config.fetch('linter_exception_severity', :error).to_sym,
        exception: err,
      )]

      @formatter.job_finished(job, lints)
      lints
    end

    def find_all_lints(jobs)
      lints =
        if workers = @options[:concurrency]
          require 'parallel'
          ::Parallel.map(jobs, { in_processes: workers }, &method(:scan_document))
        else
          jobs.map(&method(:scan_document))
        end

      lints.flatten
    end
  end
end
