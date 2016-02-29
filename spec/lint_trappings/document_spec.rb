require 'spec_helper'

RSpec.describe LintTrappings::Document do
  let(:config) { double }
  let(:options) { {} }
  let(:document_class) { described_class }

  let(:source) { normalize_indent(<<-SRC) }
    This is some source code
    It is beautiful source code
  SRC

  subject { document_class.new(source, config, options) }

  describe '#initialize' do
    before do
      allow_any_instance_of(described_class).to receive(:process_source)
    end

    it 'calls #process_source' do
      expect_any_instance_of(described_class).to receive(:process_source)
      subject
    end

    it 'stores the source code' do
      expect(subject.source).to eq source
    end

    it 'stores the individual lines of source code' do
      expect(subject.source_lines).to eq source.split("\n")
    end

    context 'when path is explicitly specified' do
      let(:options) { super().merge(path: 'my_file.slim') }

      it 'sets the path' do
        expect(subject.path).to eq 'my_file.slim'
      end
    end

    context 'when path is not specified' do
      it 'sets the path to `nil`' do
        expect(subject.path).to be_nil
      end
    end
  end

  describe '#process_source' do
    context 'when process_source has not been implemented' do
      let(:document_class) { Class.new(LintTrappings::Document) }

      it 'raises' do
        expect { subject }.to raise_error NotImplementedError, 'Must implement #process_source'
      end
    end
  end
end
