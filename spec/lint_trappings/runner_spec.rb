require 'spec_helper'
require 'lint_trappings/runner'

RSpec.describe LintTrappings::Runner do
  let(:app) { double }
  let(:config) { double }
  let(:output) { double }
  let(:runner) { described_class.new(app, config, output) }

  describe '#run' do
    let(:options) { {} }
    subject { runner.run(options) }

    before do
      allow(config).to receive(:fetch).with('linter_exception_severity', :error) { 'error' }
    end

    it 'loads formatters based on options given' do
      allow(runner).to receive(:load_documents) { [[], []] }
      allow(runner).to receive(:determine_jobs_to_run) { [] }

      formatter_loader = double
      expect(LintTrappings::FormatterLoader).to receive(:new)
        .with(app, config, output) { formatter_loader }
      expect(formatter_loader).to receive(:load).with(options) { [] }
      subject
    end

    it 'loads documents based on options given' do
      allow(runner).to receive(:load_formatters) { [] }
      allow(runner).to receive(:determine_jobs_to_run) { [] }

      document_loader = double
      expect(LintTrappings::DocumentLoader).to receive(:new)
        .with(app, config, instance_of(LintTrappings::FormatterForwarder)) { document_loader }
      expect(document_loader).to receive(:load).with(options) { [[], []] }
      subject
    end

    it 'determines jobs based on options given' do
      allow(runner).to receive(:load_formatters) { [] }

      doc1 = double(path: 'some-file.txt')
      doc2 = double(path: 'another-file.txt')
      allow(runner).to receive(:load_documents) { [[doc1, doc2], []] }

      linter_selector = double
      expect(LintTrappings::LinterSelector).to receive(:new)
        .with(app, config, options) { linter_selector }

      linter1 = double
      linter2 = double
      linter3 = double
      expect(linter_selector).to receive(:linters_for_file)
        .with('some-file.txt') { [linter1, linter2] }
      expect(linter_selector).to receive(:linters_for_file)
        .with('another-file.txt') { [linter1, linter3] }

      expect(runner).to receive(:find_all_lints).with(
        [
          described_class::Job.new(linter1, 'some-file.txt'),
          described_class::Job.new(linter2, 'some-file.txt'),
          described_class::Job.new(linter1, 'another-file.txt'),
          described_class::Job.new(linter3, 'another-file.txt'),
        ]
      ) { [] }

      subject
    end

    it 'includes found lints in the report' do
      allow(runner).to receive(:load_formatters) { [] }
      allow(runner).to receive(:load_documents) { [[], []] }
      allow(runner).to receive(:determine_jobs_to_run) { [] }

      lint1 = double
      lint2 = double
      allow(runner).to receive(:find_all_lints) { [lint1, lint2] }

      report = double
      expect(LintTrappings::Report).to receive(:new)
        .with(config, [lint1, lint2], []) { report }

      expect(subject).to eq report
    end

    it 'reports parse errors as lints' do
      parse_lint1 = double
      parse_lint2 = double

      allow(runner).to receive(:load_formatters) { [] }
      allow(runner).to receive(:load_documents) { [[], [parse_lint1, parse_lint2]] }
      allow(runner).to receive(:determine_jobs_to_run) { [] }

      report = double
      expect(LintTrappings::Report).to receive(:new)
        .with(config, [parse_lint1, parse_lint2], []) { report }

      expect(subject).to eq report
    end

    it 'calls FormatterForwarder#finished to mark the end of the run' do
      allow(runner).to receive(:load_formatters) { [] }
      allow(runner).to receive(:load_documents) { [[], []] }
      allow(runner).to receive(:determine_jobs_to_run) { [] }

      expect_any_instance_of(LintTrappings::FormatterForwarder).to receive(:finished)
        .with(instance_of(LintTrappings::Report))
      subject
    end

    context 'when concurrency option not specified' do
      it 'executes the jobs in serial' do
        allow(runner).to receive(:load_formatters) { [] }

        doc1 = double(path: 'some-file.txt')
        doc2 = double(path: 'another-file.txt')
        allow(runner).to receive(:load_documents) { [[doc1, doc2], []] }

        linter1 = double
        linter2 = double
        job1 = double(linter: linter1, path: doc1.path)
        job2 = double(linter: linter2, path: doc2.path)
        allow(runner).to receive(:determine_jobs_to_run) { [job1, job2] }

        expect(runner).to receive(:scan_document).with(job1).and_call_original
        expect(runner).to receive(:scan_document).with(job2).and_call_original

        expect(linter1).to receive(:run).with(doc1) { [] }
        expect(linter2).to receive(:run).with(doc2) { [] }

        subject
      end
    end

    context 'when concurrency option is specified' do
      let(:options) { { concurrency: 4 } }

      it 'executes the jobs in parallel' do
        require 'parallel' # This is the only test that uses this library

        allow(runner).to receive(:load_formatters) { [] }
        allow(runner).to receive(:load_documents) { [[], []] }

        jobs = double
        allow(runner).to receive(:determine_jobs_to_run) { jobs }

        expect(::Parallel).to receive(:map)
          .with(jobs, hash_including(in_processes: 4)) { [] }

        subject
      end
    end

    context 'when a linter raises an unexpected error' do
      let(:doc) { double(path: 'some-file.txt') }
      let(:linter) { double }
      let(:job) { double(linter: linter, path: doc.path) }
      let(:exception) { StandardError.new('Something happened!') }
      let(:source_range) { LintTrappings::Location.new(1)..LintTrappings::Location.new(1) }

      before do
        allow(runner).to receive(:load_formatters) { [] }
        allow(runner).to receive(:load_documents) { [[doc], []] }
        allow(runner).to receive(:determine_jobs_to_run) { [job] }
        expect(linter).to receive(:run).with(doc).and_raise(exception)
      end

      it 'captures the exception in a lint' do
        expect(LintTrappings::Lint).to receive(:new).with(
          hash_including(
            linter: linter,
            path: doc.path,
            source_range: source_range,
            message: 'Error occurred while linting some-file.txt: Something happened!',
            severity: :error,
            exception: exception,
          )
        ).and_call_original

        expect { subject }.to_not raise_error
      end

      context 'when linter_exception_severity is specified in config' do
        before do
          allow(config).to receive(:fetch).with(any_args)
          allow(config).to receive(:fetch)
            .with('linter_exception_severity', :error) { :custom_severity }
        end

        it 'uses the specified severity' do
          expect(LintTrappings::Lint).to receive(:new).with(
            hash_including(severity: :custom_severity)
          ).and_call_original

          subject
        end
      end
    end
  end
end
