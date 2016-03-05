require 'spec_helper'
require 'lint_trappings/formatter_loader'

RSpec.describe LintTrappings::FormatterLoader do
  let(:app) { double }
  let(:config) { LintTrappings::Configuration.new }
  let(:output) { double }
  let(:loader) { described_class.new(app, config, output) }

  describe '#load' do
    subject { loader.load(options) }

    context 'when no formatters are specified' do
      let(:options) { {} }

      it 'loads the default formatter' do
        allow(loader).to receive(:require)
          .with('lint_trappings/formatter/base').and_call_original
        expect(loader).to receive(:require)
          .with('lint_trappings/formatter/default').and_call_original
        subject
      end

      it 'configures formatter to output to the default output stream' do
        expect(LintTrappings::Formatter::Default)
          .to receive(:new).with(anything, anything, anything, output)
        subject
      end

      it 'returns an instance of the default formatter' do
        expect(subject.map(&:class)).to eq [LintTrappings::Formatter::Default]
      end
    end

    context 'when a non-existent formatter is specified' do
      let(:options) { { formatters: [{ 'NonExistent' => :stdout }] } }

      it 'raises' do
        expect { subject }.to raise_error LintTrappings::FormatterLoadError,
                                          /Unable to load formatter/
      end
    end

    context 'when the loaded formatter file does not declare a class of the specified name' do
      let(:options) { { formatters: [{ 'NonExistent' => :stdout }] } }

      before do
        allow(loader).to receive(:require).with('lint_trappings/formatter/base').and_call_original
        # Pretend the load succeeded (but the class won't exist)
        allow(loader).to receive(:require).with('lint_trappings/formatter/non_existent')
      end

      it 'raises' do
        expect { subject }.to raise_error LintTrappings::FormatterLoadError,
                                          /Unable to create formatter/
      end
    end

    context 'when a formatter redirects output to a file' do
      let(:options) { { formatters: [{ 'Default' => 'some-file.txt' }] } }

      before do
        # Prevent file from actually being created
        allow(File).to receive(:open)
          .with('some-file.txt', File::CREAT | File::TRUNC | File::WRONLY)
      end

      it 'creates/truncates the file and opens it for writing' do
        expect(File).to receive(:open)
          .with('some-file.txt', File::CREAT | File::TRUNC | File::WRONLY)
        subject
      end

      it 'configures the formatter to output to the given file' do
        fake_output = double
        allow(LintTrappings::Output).to receive(:new) { fake_output }
        expect(LintTrappings::Formatter::Default).to receive(:new)
          .with(app, config, options, fake_output)
        subject
      end
    end
  end
end
