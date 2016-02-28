require 'spec_helper'

RSpec.describe LintTrap::LinterSelector do
  let(:application) { double }
  let(:config) { {} }
  let(:options) { {} }

  let(:linter_selector) do
    described_class.new(application, LintTrap::Configuration.new(config), options)
  end

  # Create 3 linters with actual names. Doing this dynamically allows us to not
  # need actual linter implemenations.
  linter_classes = 3.times.map do |i|
    LintTrap::Linter.const_set("Linter#{i + 1}", Class.new(LintTrap::Linter))
  end

  after(:all) do
    # Undefine classes afterwards so we don't pollute the namespace
    linter_classes.each do |linter_class|
      LintTrap::Linter.send(:remove_const, linter_class.canonical_name)
    end
  end

  before do
    allow_any_instance_of(described_class).to receive(:all_linter_classes) { linter_classes }
    allow(application).to receive(:linter_base_class) { LintTrap::Linter }
  end

  describe '#linters_for_file' do
    let(:path) { 'file.slim' }
    subject { linter_selector.linters_for_file(path).map(&:canonical_name) }

    context 'when no linters are enabled in the configuration' do
      context 'when no linters are explicitly included' do
        it 'raises error with a helpful message' do
          expect { subject }.to raise_error(LintTrap::NoLintersError,
                                            'All linters are disabled. ' \
                                            'Enable some in your configuration!')
        end
      end

      context 'when linters are explicitly included' do
        let(:options) { { included_linters: %w[Linter1 Linter3] } }

        it 'returns those linters' do
          expect(subject).to match_array %w[Linter1 Linter3]
        end

        context 'and linters are explicitly excluded' do
          let(:options) { super().merge(excluded_linters: %w[Linter1]) }

          it 'returns the non-excluded linters' do
            expect(subject).to match_array %w[Linter3]
          end
        end

        context 'and all explicitly included linters are explicitly excluded' do
          let(:options) { super().merge(excluded_linters: super()[:included_linters]) }

          it 'raises error with a helpful message' do
            expect { subject }.to raise_error(LintTrap::NoLintersError,
                                              'All specified linters were explicitly excluded!')
          end
        end

        context 'and linters were excluded which were not explicitly included' do
          let(:options) { super().merge(excluded_linters: %w[Linter1 Linter2 Linter3]) }

          it 'raises error with a helpful message' do
            expect { subject }.to raise_error(LintTrap::NoLintersError,
                                              'All specified linters were explicitly excluded!')
          end
        end
      end
    end

    context 'when linters are enabled in the configuration' do
      let(:config) do
        {
          'linters' => {
            'Linter1' => { 'enabled' => true },
            'Linter2' => { 'enabled' => true },
          }
        }
      end

      context 'and no linters are explicitly included' do
        context 'and no linters are explicitly excluded' do
          it 'returns all enabled linters' do
            expect(subject).to match_array %w[Linter1 Linter2]
          end
        end

        context 'and an enabled linter is explicitly excluded' do
          let(:options) { { excluded_linters: %w[Linter2] } }

          it 'returns all enabled linters which are not excluded' do
            expect(subject).to match_array %w[Linter1]
          end
        end

        context 'and all enabled linters are explicitly excluded' do
          let(:options) { { excluded_linters: %w[Linter1 Linter2] } }

          it 'raises error with a helpful message' do
            expect { subject }.to raise_error(LintTrap::NoLintersError,
                                              'All enabled linters were explicitly excluded!')
          end
        end
      end

      context 'and an already-enabled linter is explicitly included' do
        let(:options) { { included_linters: %w[Linter1] } }

        it 'returns only the explicitly included linters' do
          expect(subject).to match_array %w[Linter1]
        end
      end

      context 'and a disabled linter is explicitly included' do
        let(:options) { { included_linters: %w[Linter3] } }

        it 'returns only the explicitly included linters' do
          expect(subject).to match_array %w[Linter3]
        end
      end

      context 'when a linter `include` pattern matches the file path' do
        let(:config) { super().tap { |h| h['linters']['Linter1']['include'] = %w[file.slim] } }

        it 'includes the linter' do
          expect(subject).to include 'Linter1'
        end
      end

      context 'when a linter `exclude` pattern matches the file path' do
        let(:config) { super().tap { |h| h['linters']['Linter1']['exclude'] = %w[file.slim] } }

        it 'excludes the linter' do
          expect(subject).to_not include 'Linter1'
        end
      end

      context 'when both linter `include`/`exclude` patterns match the file path' do
        let(:config) do
          super().tap do |h|
            h['linters']['Linter1']['include'] = %w[f*.slim]
            h['linters']['Linter1']['exclude'] = %w[*e.slim]
          end
        end

        it 'excludes the linter' do
          expect(subject).to_not include 'Linter1'
        end
      end
    end
  end
end
