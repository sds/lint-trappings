require 'spec_helper'
require 'lint_trappings/preprocessor'

RSpec.describe LintTrappings::Preprocessor do
  let(:config_hash) { {} }
  let(:config) { LintTrappings::Configuration.new(config_hash) }
  let(:preprocessor) { described_class.new(config) }

  describe '#preprocess_files' do
    let(:subject) { preprocessor.preprocess_files(files_to_lint) }

    context 'when no files are given' do
      let(:files_to_lint) { [] }

      it 'does nothing' do
        expect(preprocessor).to_not receive(:preprocess)
        subject
      end
    end

    context 'when files are given' do
      let(:files_to_lint) do
        file_struct = Struct.new(:io, :path)
        [
          file_struct.new(double(read: 'Content'), 'some-file.txt'),
          file_struct.new(double(read: 'More content'), 'another-file.txt')
        ]
      end

      context 'when no preprocess_command specified' do
        it 'does nothing' do
          expect(preprocessor).to_not receive(:preprocess)
          subject
        end
      end

      context 'when preprocess_command specified' do
        let(:config_hash) { { 'preprocess_command' => 'cat' } }

        context 'when no preprocess_files config option specified' do
          it 'processes all files' do
            expect(preprocessor).to receive(:preprocess).with(files_to_lint[0])
            expect(preprocessor).to receive(:preprocess).with(files_to_lint[1])
            subject
          end

          it 'passes the contents of each file to the external command' do
            expect(Open3).to receive(:capture2)
              .with('cat', stdin_data: 'Content')
              .and_return(['Modified content', double(success?: true)])

            expect(Open3).to receive(:capture2)
              .with('cat', stdin_data: 'More content')
              .and_return(['More modified content', double(success?: true)])

            subject
          end

          it 'updates the IO object of each file to lint' do
            expect(Open3).to receive(:capture2)
              .with('cat', stdin_data: 'Content')
              .and_return(['Modified content', double(success?: true)])

            expect(Open3).to receive(:capture2)
              .with('cat', stdin_data: 'More content')
              .and_return(['More modified content', double(success?: true)])

            subject

            expect(files_to_lint[0].io.read).to eq 'Modified content'
            expect(files_to_lint[1].io.read).to eq 'More modified content'
          end

          context 'when external command returns unsuccessfully' do
            it 'raises with a helpful error message' do
              expect(Open3).to receive(:capture2)
                .with('cat', stdin_data: 'Content')
                .and_return(['Modified content', double(success?: true)])

              expect(Open3).to receive(:capture2)
                .with('cat', stdin_data: 'More content')
                .and_return(['More modified content', double(success?: false, exitstatus: 4)])

              expect { subject }.to raise_error(
                LintTrappings::PreprocessorError,
                /command `cat` failed.*'another-file\.txt'.*status.*4/,
              )
            end
          end
        end

        context 'when preprocess_files config option matches files to process' do
          let(:config_hash) { super().merge('preprocess_files' => ['**/*.txt']) }

          it 'processes matching files' do
            expect(preprocessor).to receive(:preprocess).with(files_to_lint[0])
            expect(preprocessor).to receive(:preprocess).with(files_to_lint[1])
            subject
          end
        end

        context 'when preprocess_files config option does not match files' do
          let(:config_hash) { super().merge('preprocess_files' => ['**/*.nope']) }

          it 'processes nothing' do
            expect(preprocessor).to_not receive(:preprocess)
            subject
          end
        end
      end
    end
  end
end
