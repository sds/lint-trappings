require 'spec_helper'
require 'lint_trappings/configuration_resolver'

RSpec.describe LintTrappings::ConfigurationResolver do
  let(:config_hash) { {} }
  let(:config) { LintTrappings::Configuration.new(config_hash) }
  let(:loader) { double }
  let(:resolver) { described_class.new(loader) }

  describe '#resolve' do
    let(:options) { {} }
    subject { resolver.resolve(config, options) }

    before do
      allow(loader).to receive(:load_file).and_return(LintTrappings::Configuration.new)
    end

    context 'when configuration does not contain `extends`' do
      it 'returns the original configuration' do
        expect(subject).to eq config
      end
    end

    context 'when configuration contains `extends`' do
      let(:config_hash) do
        {
          'extends' => [
            'some/path.yaml',
            'another/path.yaml',
          ],
          'some_hash' => {
            'key_touched_by_top_config' => 99,
          },
          'some_key' => [1, 2, 3],
        }
      end

      before do
        config.path = '/original/repo/config.yaml'
      end

      it 'loads each configuration file using path relative to the original config' do
        expect(loader).to receive(:load_file)
          .with('/original/repo/some/path.yaml')
          .and_return(LintTrappings::Configuration.new)

        expect(loader).to receive(:load_file)
          .with('/original/repo/another/path.yaml')
          .and_return(LintTrappings::Configuration.new)

        subject
      end

      it 'recursively resolves each configuration to extend' do
        config1 = LintTrappings::Configuration.new
        allow(loader).to receive(:load_file)
          .with('/original/repo/some/path.yaml')
          .and_return(config1)

        config2 = LintTrappings::Configuration.new
        allow(loader).to receive(:load_file)
          .with('/original/repo/another/path.yaml')
          .and_return(config2)

        allow(resolver).to receive(:resolve).and_call_original
        expect(resolver).to receive(:resolve).with(config1, options)
          .and_return(config1)
        expect(resolver).to receive(:resolve).with(config2, options)
          .and_return(config2)

        subject
      end

      it 'merges the extended configurations' do
        config1 = LintTrappings::Configuration.new(
          'some_hash' => {
            'replaced_key' => 1,
            'key_touched_by_top_config' => 2,
          },
        )
        allow(loader).to receive(:load_file)
          .with('/original/repo/some/path.yaml')
          .and_return(config1)

        config2 = LintTrappings::Configuration.new(
          'some_hash' => {
            'replaced_key' => 3,
          },
        )
        allow(loader).to receive(:load_file)
          .with('/original/repo/another/path.yaml')
          .and_return(config2)

        allow(resolver).to receive(:resolve).and_call_original
        expect(resolver).to receive(:resolve).with(config1, options)
          .and_return(config1)
        expect(resolver).to receive(:resolve).with(config2, options)
          .and_return(config2)

        expect(subject).to eq LintTrappings::Configuration.new(
          'some_hash' => {
            'replaced_key' => 3,
            'key_touched_by_top_config' => 99,
          },
          'some_key' => [1, 2, 3],
        )
      end

      it 'removes the `extends` from the resolved configuration' do
        expect(subject['extends']).to eq nil
      end
    end

    context 'when configuration contains `linter_plugins`' do
      let(:config_hash) do
        {
          'linter_plugins' => [
            'some/plugin',
            'another/plugin',
          ],
          'some_hash' => {
            'key_touched_by_top_config' => 99,
          },
          'some_key' => [1, 2, 3],
        }
      end

      before do
        plugin1 = double(config_file_path: 'some/plugin/gem/path/to/config.yaml')
        allow(LintTrappings::LinterPlugin)
          .to receive(:new).with('some/plugin').and_return(plugin1)

        plugin2 = double(config_file_path: 'another/plugin/gem/path/to/config.yaml')
        allow(LintTrappings::LinterPlugin)
          .to receive(:new).with('another/plugin').and_return(plugin2)
      end

      it 'loads a LinterPlugin for each path' do
        plugin1 = double(config_file_path: 'some/plugin/gem/path/to/config.yaml')
        expect(LintTrappings::LinterPlugin)
          .to receive(:new).with('some/plugin').and_return(plugin1)

        plugin2 = double(config_file_path: 'another/plugin/gem/path/to/config.yaml')
        expect(LintTrappings::LinterPlugin)
          .to receive(:new).with('another/plugin').and_return(plugin2)

        subject
      end

      context 'when the plugin includes a configuration file' do
        before do
          allow(File).to receive(:exist?)
            .with('some/plugin/gem/path/to/config.yaml')
            .and_return(true)
          allow(File).to receive(:exist?)
            .with('another/plugin/gem/path/to/config.yaml')
            .and_return(true)
        end

        it 'loads the configuration file and recursively resolves it' do
          config1 = LintTrappings::Configuration.new
          expect(loader).to receive(:load_file)
            .with('some/plugin/gem/path/to/config.yaml')
            .and_return(config1)

          config2 = LintTrappings::Configuration.new
          expect(loader).to receive(:load_file)
            .with('another/plugin/gem/path/to/config.yaml')
            .and_return(config2)

          allow(resolver).to receive(:resolve).and_call_original
          expect(resolver).to receive(:resolve).with(config1, options)
            .and_return(config1)
          expect(resolver).to receive(:resolve).with(config2, options)
            .and_return(config2)

          subject
        end
      end

      context 'when the plugin does not include a configuration file' do
        before do
          allow(File).to receive(:exist?)
            .with('some/plugin/gem/path/to/config.yaml')
            .and_return(false)
          allow(File).to receive(:exist?)
            .with('another/plugin/gem/path/to/config.yaml')
            .and_return(false)
        end

        it 'does not load/resolve plugin configuration files' do
          config1 = LintTrappings::Configuration.new
          expect(loader).to_not receive(:load_file)
            .with('some/plugin/gem/path/to/config.yaml')

          config2 = LintTrappings::Configuration.new
          expect(loader).to_not receive(:load_file)
            .with('another/plugin/gem/path/to/config.yaml')

          expect(resolver).to_not receive(:resolve).with(config1, options)
          expect(resolver).to_not receive(:resolve).with(config2, options)

          subject
        end
      end
    end

    context 'when `linter_plugins` option is specified' do
      let(:options) { { linter_plugins: %w[some/linter/plugin another/linter/plugin] } }

      it 'loads a LinterPlugin for each path' do
        plugin1 = double(config_file_path: 'some/plugin/gem/path/to/config.yaml')
        expect(LintTrappings::LinterPlugin)
          .to receive(:new).with('some/linter/plugin').and_return(plugin1)

        plugin2 = double(config_file_path: 'another/plugin/gem/path/to/config.yaml')
        expect(LintTrappings::LinterPlugin)
          .to receive(:new).with('another/linter/plugin').and_return(plugin2)

        subject
      end
    end
  end
end
