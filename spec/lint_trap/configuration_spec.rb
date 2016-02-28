require 'spec_helper'

RSpec.describe LintTrap::Configuration do
  let(:hash) { {} }
  let(:config) { described_class.new(hash) }

  describe 'merge' do
    let(:other_config) { described_class.new(other_hash) }
    subject { config.merge(other_config) }

    context 'when base configuration is empty' do
      let(:hash) { {} }

      context 'and other configuration is empty' do
        let(:other_hash) { {} }

        it { should == described_class.new }
      end

      context 'and other configuration is not empty' do
        let(:other_hash) { { 'some-key' => 'value' } }

        it { should == other_config }
      end
    end

    context 'when base configuration is not empty' do
      let(:hash) do
        {
          'key' => {
            'array' => [1, 2, 3, 4],
            'untouched-nested-key' => 'some-value',
            'one-more-nested-key' => {
              'key' => 'some-value',
            }
          },
          'untouched-key' => {
            'nested-key' => 5,
          },
        }
      end

      context 'and other configuration is empty' do
        let(:other_hash) { {} }

        it { should == config }
      end

      context 'and other configuration is not empty' do
        let(:other_hash) do
          {
            'key' => {
              'array' => [4, 5, 6, 7],
              'one-more-nested-key' => {
                'new-key' => 'some-other-value',
              }
            },
          }
        end

        it 'replaces arrays that have changed' do
          subject['key']['array'] = other_hash['key']['array']
        end

        it 'merges new nested keys into existing keys' do
          expect(subject['key']['one-more-nested-key']['key']).to eq 'some-value'
          expect(subject['key']['one-more-nested-key']['new-key']).to eq 'some-other-value'
        end

        it 'leaves untouched keys alone' do
          expect(subject['untouched-key']).to eq config['untouched-key']
        end

        it 'leaves untouched nested keys alone' do
          expect(subject['key']['untouched-nested-key']).to eq config['key']['untouched-nested-key']
        end
      end
    end
  end
end
