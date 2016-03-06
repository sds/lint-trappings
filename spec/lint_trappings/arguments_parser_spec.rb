require 'spec_helper'
require 'lint_trappings/arguments_parser'

RSpec.describe LintTrappings::ArgumentsParser do
  let(:app) { double }
  subject { described_class.new(app) }

  before do
    allow(app).to receive(:executable_name) { 'MyApp' }
  end

  describe '#parse' do
    subject { super().parse(args) }

    context 'when no arguments are specified' do
      let(:args) { [] }
      its([:command]) { is_expected.to eq :scan }
      its([:included_paths]) { are_expected.to eq [] }
    end

    context 'when an invalid/non-existent flag is specified' do
      let(:args) { %w[--some-invalid-flag] }

      it 'raises an error with a suggestion to use --help flag' do
        expect { subject }.to raise_error LintTrappings::InvalidCliOptionError,
                                          /Run `MyApp --help`/
      end
    end

    context 'with --config' do
      let(:args) { %w[--config config.yaml] }
      its([:config_file]) { is_expected.to eq 'config.yaml' }
    end

    context 'with --exclude-path' do
      let(:args) { %w[--exclude-path some-file.txt] }
      its([:excluded_paths]) { are_expected.to eq %w[some-file.txt] }

      context 'specified multiple times' do
        let(:args) { %w[--exclude-path some-file.txt --exclude-path another-file.txt] }
        its([:excluded_paths]) { are_expected.to eq %w[some-file.txt another-file.txt] }
      end
    end

    context 'with --format' do
      let(:args) { %w[--format MyFormatter] }
      its([:formatters]) { are_expected.to eq [{ 'MyFormatter' => :stdout }] }

      context 'followed by --out' do
        let(:args) { super() + %w[--out some-file.txt] }
        its([:formatters]) { are_expected.to eq [{ 'MyFormatter' => 'some-file.txt' }] }

        context 'followed by another --out' do
          let(:args) { super() + %w[--out another-file.txt] }

          its([:formatters]) do
            are_expected.to eq [{ 'MyFormatter' => 'some-file.txt' },
                                { 'MyFormatter' => 'another-file.txt' }]
          end
        end
      end

      context 'followed by --format' do
        let(:args) { super() + %w[--format AnotherFormatter] }
        its([:formatters]) do
          are_expected.to eq [{ 'MyFormatter' => :stdout },
                              { 'AnotherFormatter' => :stdout }]
        end

        context 'followed by --out' do
          let(:args) { super() + %w[--out some-file.txt] }

          its([:formatters]) do
            are_expected.to eq [{ 'MyFormatter' => :stdout },
                                { 'AnotherFormatter' => 'some-file.txt' }]
          end
        end
      end
    end

    context 'with --out' do
      let(:args) { %w[--out some-file.txt] }
      its([:formatters]) { are_expected.to eq [{ 'Default' => 'some-file.txt' }] }
    end

    context 'with --stdin-file-path' do
      let(:args) { %w[--stdin-file-path some-file.txt] }
      its([:stdin]) { is_expected.to eq STDIN }
      its([:stdin_file_path]) { is_expected.to eq 'some-file.txt' }
    end

    context 'with --require' do
      let(:args) { %w[--require some/lib/path] }
      its([:require_paths]) { are_expected.to eq %w[some/lib/path] }

      context 'specified multiple times' do
        let(:args) { super() + %w[--require another/lib/path] }
        its([:require_paths]) { are_expected.to eq %w[some/lib/path another/lib/path] }
      end
    end

    context 'with --include-linter' do
      let(:args) { %w[--include-linter MyLinter] }
      its([:included_linters]) { are_expected.to eq %w[MyLinter] }

      context 'specified multiple times' do
        let(:args) { super() + %w[--include-linter AnotherLinter] }
        its([:included_linters]) { are_expected.to eq %w[MyLinter AnotherLinter] }
      end
    end

    context 'with --exclude-linter' do
      let(:args) { %w[--exclude-linter MyLinter] }
      its([:excluded_linters]) { are_expected.to eq %w[MyLinter] }

      context 'specified multiple times' do
        let(:args) { super() + %w[--exclude-linter AnotherLinter] }
        its([:excluded_linters]) { are_expected.to eq %w[MyLinter AnotherLinter] }
      end
    end

    context 'with --concurrency' do
      let(:args) { %w[--concurrency 4] }
      its([:concurrency]) { is_expected.to eq 4 }

      context 'less than 1' do
        let(:args) { %w[--concurrency 0] }

        it 'raises' do
          expect { subject }.to raise_error LintTrappings::InvalidCliOptionError,
                                            /cannot be < 1/
        end
      end
    end

    context 'with --show-linters' do
      let(:args) { %w[--show-linters] }
      its([:command]) { is_expected.to eq :display_linters }
    end

    context 'with --show-formatters' do
      let(:args) { %w[--show-formatters] }
      its([:command]) { is_expected.to eq :display_formatters }
    end

    context 'with --show-docs' do
      let(:args) { %w[--show-docs] }

      context 'without a linter name' do
        let(:args) { %w[--show-docs] }
        its([:command]) { is_expected.to eq :display_documentation }
        it { is_expected.to_not have_key :linter }
      end

      context 'with a linter name' do
        let(:args) { %w[--show-docs SomeLinter] }

        its([:command]) { is_expected.to eq :display_documentation }
        its([:linter]) { is_expected.to eq 'SomeLinter' }
      end
    end

    context 'with --color' do
      context 'enabled' do
        let(:args) { %w[--color] }
        its([:color]) { is_expected.to eq true }
      end

      context 'disabled' do
        let(:args) { %w[--no-color] }
        its([:color]) { is_expected.to eq false }
      end
    end

    context 'with --debug' do
      let(:args) { %w[--debug] }
      its([:debug]) { is_expected.to eq true }
    end

    context 'with --help' do
      let(:args) { %w[--help] }
      its([:command]) { is_expected.to eq :display_help }
    end

    context 'with --version' do
      let(:args) { %w[--version] }
      its([:command]) { is_expected.to eq :display_version }
    end

    context 'with --version' do
      let(:args) { %w[--verbose-version] }
      its([:command]) { is_expected.to eq :display_version }
      its([:verbose_version]) { is_expected.to eq true }
    end
  end
end
