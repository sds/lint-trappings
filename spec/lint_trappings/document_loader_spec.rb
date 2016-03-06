require 'spec_helper'
require 'lint_trappings/document_loader'

RSpec.describe LintTrappings::DocumentLoader do
  let(:app) { double }
  let(:config) { LintTrappings::Configuration.new }
  let(:formatter) { double }
  let(:app_file_extensions) { %w[txt] }
  let(:document_class) { double }
  let(:document_loader) { described_class.new(app, config, formatter) }

  describe '#load' do
    let(:options) { {} }
    subject { document_loader.load(options) }

    before do
      preprocessor = double
      allow(LintTrappings::Preprocessor).to receive(:new)
        .with(config) { preprocessor }
      allow(preprocessor).to receive(:preprocess_files).with(anything)

      allow(formatter).to receive(:started).with(anything)

      allow(app).to receive(:file_extensions) { app_file_extensions }
      allow(app).to receive(:document_class) { document_class }
    end

    context 'when no options are specified' do
      it 'tries to find files matching the default allowed extensions' do
        expect(LintTrappings::FileFinder).to receive(:find).with(
          hash_including(
            allowed_extensions: app_file_extensions,
            included_paths: [],
            excluded_paths: [],
            included_patterns: %w[**/*.txt],
            excluded_patterns: [],
          )
        ).and_return([])

        subject
      end

      context 'when configuration specifies custom file_extensions' do
        it 'searches for the extensions specified by the config' do
          allow(config).to receive(:fetch).with(any_args).and_call_original
          allow(config).to receive(:fetch)
            .with('file_extensions', app_file_extensions) { %w[ext1 ext2] }

          expect(LintTrappings::FileFinder).to receive(:find).with(
            hash_including(
              allowed_extensions: %w[ext1 ext2],
              included_paths: [],
              excluded_paths: [],
              included_patterns: %w[**/*.ext1 **/*.ext2],
              excluded_patterns: [],
            )
          ).and_return([])

          subject
        end
      end
    end

    context 'when stdin/stdin_file_path options are specified' do
      let(:options) do
        {
          stdin: double(read: 'Contents of file'),
          stdin_file_path: 'some-file.txt',
        }
      end

      it 'creates a document using stdin/stdin_file_path' do
        expect(document_class).to receive(:new).with('Contents of file',
                                                     config,
                                                     path: 'some-file.txt')
        subject
      end
    end

    context 'when included_paths option is specified' do
      let(:options) { { included_paths: %w[some/path.txt] } }

      it 'searched for the included_paths' do
        expect(LintTrappings::FileFinder).to receive(:find)
          .with(hash_including(included_paths: %w[some/path.txt])) { [] }

        subject
      end
    end

    context 'when included_paths option is not specified' do
      let(:options) { {} }

      it 'searches for included_paths specified by configuration' do
        allow(config).to receive(:fetch).with(any_args).and_call_original
        expect(config).to receive(:fetch)
          .with('included_paths', []) { %w[path/specified/by/config.txt] }

        expect(LintTrappings::FileFinder).to receive(:find)
          .with(hash_including(included_paths: %w[path/specified/by/config.txt])) { [] }

        subject
      end
    end

    context 'when excluded_paths option is specified' do
      let(:options) { { excluded_paths: %w[some/path.txt] } }

      it 'excludes the excluded_paths' do
        expect(LintTrappings::FileFinder).to receive(:find)
          .with(hash_including(excluded_paths: %w[some/path.txt])) { [] }

        subject
      end

      context 'and excluded_paths is specified in the configuration' do
        it 'combines the excluded_paths specified by option and config' do
          allow(config).to receive(:fetch).with(any_args).and_call_original
          expect(config).to receive(:fetch)
            .with('excluded_paths', []) { %w[path/specified/by/config.txt] }

          expect(LintTrappings::FileFinder).to receive(:find).with(
            hash_including(
              excluded_paths: %w[path/specified/by/config.txt some/path.txt],
            )
          ) { [] }

          subject
        end
      end
    end

    context 'when excluded_paths option is not specified' do
      it 'searches for excluded_paths specified by configuration' do
        allow(config).to receive(:fetch).with(any_args).and_call_original
        expect(config).to receive(:fetch)
          .with('excluded_paths', []) { %w[path/specified/by/config.txt] }

        expect(LintTrappings::FileFinder).to receive(:find)
          .with(hash_including(excluded_paths: %w[path/specified/by/config.txt])) { [] }

        subject
      end
    end

    context 'when a specified file does not exist' do
      let(:options) { { included_paths: %w[some-file.txt] } }

      before do
        expect(LintTrappings::FileFinder).to receive(:find) { %w[some-file.txt] }

        expect(File).to receive(:open)
          .with('some-file.txt').and_raise(Errno::ENOENT, 'some-file.txt')
      end

      it 'raises' do
        expect { subject }.to raise_error LintTrappings::InvalidFilePathError
      end
    end

    context 'when a parse failure occurs in a file' do
      let(:source_range) { LintTrappings::Location.new(1, 3)..LintTrappings::Location.new(1, 9) }

      before do
        file_to_lint = double(io: double(read: 'Some invalid content'), path: 'some-file.txt')
        allow(document_loader).to receive(:determine_files_to_lint) { [file_to_lint] }

        parse_error = LintTrappings::ParseError.new(
          message: 'Document is invalid!',
          path: 'some-file.txt',
          source_range: source_range,
        )

        allow(document_class).to receive(:new).with(
          'Some invalid content',
          config,
          path: 'some-file.txt'
        ).and_raise(parse_error)
      end

      it 'captures the failure in a parse lint' do
        _documents, parse_lints = subject
        expect(parse_lints.count).to eq 1
        parse_lint = parse_lints.first
        expect(parse_lint.path).to eq 'some-file.txt'
        expect(parse_lint.source_range).to eq source_range
        expect(parse_lint.message).to match /Error occurred while parsing some-file\.txt/
        expect(parse_lint.severity).to eq :error
      end

      context 'when parse_exception_severity is specified in config' do
        before do
          allow(config).to receive(:fetch).with(any_args).and_call_original
          allow(config).to receive(:fetch)
            .with('parse_exception_severity', :error) { :custom_severity }
        end

        it 'uses the specified severity' do
          _documents, parse_lints = subject
          expect(parse_lints.first.severity).to eq :custom_severity
        end
      end
    end
  end
end
