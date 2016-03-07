require 'spec_helper'
require 'lint_trappings/linter_loader'

RSpec.describe LintTrappings::LinterLoader do
  let(:app) { double }
  let(:config_hash) { {} }
  let(:config) { LintTrappings::Configuration.new(config_hash) }
  let(:loader) { described_class.new(app, config) }

  describe '#load' do
    let(:options) { {} }
    subject { loader.load(options) }

    before do
      config.path = '/original/config/path.yaml'
      allow(app).to receive(:linters_directory).and_return('built-in/linters/directory')
    end

    context 'when no options are specified' do
      it 'loads the built-in linters' do
        expect(loader).to receive(:load_directory).with('built-in/linters/directory')
        subject
      end
    end

    context 'when `linter_directories` is specified in the configuration' do
      let(:config_hash) { { 'linter_directories' => %w[some/directory another/directory] } }

      it 'loads the built-in linters' do
        allow(loader).to receive(:load_directory)
        expect(loader).to receive(:load_directory).with('built-in/linters/directory')
        subject
      end

      it 'loads the linters relative to the config path' do
        allow(loader).to receive(:load_directory)
        expect(loader).to receive(:load_directory).with('/original/config/some/directory')
        expect(loader).to receive(:load_directory).with('/original/config/another/directory')
        subject
      end
    end

    context 'when `linter_directories` option is specified' do
      let(:options) { { linter_directories: %w[some/directory another/directory] } }

      it 'loads the built-in linters' do
        allow(loader).to receive(:load_directory)
        expect(loader).to receive(:load_directory).with('built-in/linters/directory')
        subject
      end

      it 'loads the linters relative to the current working directory' do
        allow(loader).to receive(:load_directory)
        expect(loader).to receive(:load_directory).with('some/directory')
        expect(loader).to receive(:load_directory).with('another/directory')
        subject
      end
    end
  end
end
