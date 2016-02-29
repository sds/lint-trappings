require 'spec_helper'
require 'lint_trappings/cli'
require 'stringio'

RSpec.describe LintTrappings::Cli do
  let(:app) { double }
  let(:output) { StringIO.new }
  let(:output_stream) { LintTrappings::Output.new(output) }
  subject { described_class.new(app, output_stream) }

  describe '#run' do
    let(:args) { %w[some dummy list of arguments] }
    let(:parsed_options) { { one: 'option', and: 'another' } }

    subject { super().run(args) }

    before do
      allow(app).to receive(:run)
      allow_any_instance_of(LintTrappings::ArgumentsParser).to receive(:parse) { parsed_options }
    end

    it 'parses arguments' do
      expect_any_instance_of(LintTrappings::ArgumentsParser).to receive(:parse).with(args)
      subject
    end

    it 'executes the application using the parsed arguments' do
      expect(app).to receive(:run).with(parsed_options)
      subject
    end

    context 'when no exception is raised' do
      it 'returns 0' do
        expect(subject).to eq 0
      end
    end

    context 'when warnings are reported' do
      before do
        allow(app).to receive(:run) { raise LintTrappings::ScanWarned }
      end

      it 'returns 0' do
        expect(subject).to eq 0
      end
    end

    context 'when errors are reported' do
      before do
        allow(app).to receive(:run) { raise LintTrappings::ScanFailed }
      end

      it 'returns 0' do
        expect(subject).to eq 2
      end
    end

    context 'when unexpected error is raised' do
      let(:app_name) { 'MyLinterApp' }
      let(:app_version) { '1.2.3' }
      let(:app_issues_url) { 'https://some-issue-page.com' }

      before do
        allow(app).to receive(:run) { raise unexpected_error }
        allow(app).to receive(:name) { app_name }
        allow(app).to receive(:version) { app_version }
        allow(app).to receive(:issues_url) { app_issues_url }
      end

      shared_examples_for 'an unexpected error' do
        it 'returns exit status 70 (EX_SOFTWARE)' do
          expect(subject).to eq 70
        end

        it 'displays an issue page URL' do
          subject
          expect(output.string).to include app_issues_url
        end

        it 'displays the application name' do
          subject
          expect(output.string).to include app_name
        end

        it 'displays the application version' do
          subject
          expect(output.string).to include app_version
        end

        it 'displays the Ruby version' do
          ruby_version = '6.6.6'
          stub_const('RUBY_VERSION', ruby_version)
          subject
          expect(output.string).to include ruby_version
        end
      end

      context 'and the error is a LintTrappings error' do
        context 'and the error defines an exit status' do
          let(:unexpected_error) do
            Class.new(LintTrappings::LintTrappingsError) do
              exit_status 123
            end
          end

          it 'returns the exit status of the error' do
            expect(subject).to eq 123
          end
        end

        context 'and the error does not define an exit status' do
          let(:unexpected_error) { LintTrappings::LintTrappingsError }

          it_behaves_like 'an unexpected error'
        end
      end

      context 'and the error is not a LintTrappings error' do
        let(:unexpected_error) { KeyError }

        it_behaves_like 'an unexpected error'
      end
    end
  end
end
