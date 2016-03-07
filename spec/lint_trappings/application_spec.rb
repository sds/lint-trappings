require 'spec_helper'
require 'lint_trappings/application'
require 'lint_trappings/output'

RSpec.describe LintTrappings::Application do
  let(:output) { LintTrappings::Output.silent }
  let(:app) { app_class.new(output) }

  let(:app_class) do
    Class.new(described_class) do
      name                      'MyApp'
      executable_name           'my-app'
      version                   '1.2.3'

      configuration_file_names  %w[.my-app.yaml .my-app.yml]
      file_extensions           %w[.txt .text]

      base_configuration        LintTrappings::Configuration.new

      home_url                  'https://example.com'
      issues_url                'https://example.com/issues'

      linters_directory         'some-gem-directory'
      linter_base_class         LintTrappings::Linter
      document_class            LintTrappings::Document
    end
  end

  describe '#run' do
    subject { app.run(options) }

    context 'when no options are specified' do
      let(:options) { {} }

      it 'raises' do
        expect { subject }.to raise_error LintTrappings::InvalidCommandError,
                                          /`command` option must be specified/
      end
    end

    context 'when command is specified' do
      require 'lint_trappings/command/scan'

      let(:options) { { command: :scan } }

      before do
        # Don't actually run the command
        allow_any_instance_of(LintTrappings::Command::Scan).to receive(:run)
      end

      it 'loads the code for the command' do
        expect(app).to receive(:require).with('lint_trappings/command/scan')
        subject
      end

      it 'creates an instance of the command and runs it' do
        command = double
        expect(LintTrappings::Command::Scan).to receive(:new)
          .with(app, LintTrappings::Configuration.new, options, output)
          .and_return(command)

        expect(command).to receive(:run)
        subject
      end

      context 'when the command does not exist' do
        let(:options) { { command: 'non-existent-command' } }

        it 'raises' do
          expect { subject }.to raise_error LintTrappings::InvalidCommandError,
                                            /Unable to load command 'non-existent-command'/
        end
      end

      context 'when the command file has a syntax error' do
        let(:options) { { command: 'command-with-syntax-error' } }

        before do
          allow(app).to receive(:require).and_raise SyntaxError
        end

        it 'raises' do
          expect { subject }.to raise_error LintTrappings::InvalidCommandError,
                                            /Unable to load command 'command-with-syntax-error'/
        end
      end
    end

    context 'when config_file option is specified' do
      let(:options) { { config_file: 'some-config.yaml' } }

      before do
        # We just want to verify config file loading, so don't run command
        command = double
        allow(app).to receive(:create_command).and_return(command)
        allow(command).to receive(:run)
      end

      it 'loads the file with the ConfigurationLoader' do
        expect_any_instance_of(LintTrappings::ConfigurationLoader)
          .to receive(:load_file)
          .with('some-config.yaml')
          .and_return(LintTrappings::Configuration.new)
        subject
      end

      it 'resolves the configuration' do
        config = double
        allow_any_instance_of(LintTrappings::ConfigurationLoader)
          .to receive(:load_file)
          .with('some-config.yaml')
          .and_return(config)

        expect_any_instance_of(LintTrappings::ConfigurationResolver)
          .to receive(:resolve)
          .with(config, options)
          .and_return(LintTrappings::Configuration.new)

        subject
      end
    end

    context 'when config_file option is not specified' do
      let(:options) { {} }

      before do
        # We just want to verify config file loading, so don't run command
        command = double
        allow(app).to receive(:create_command).and_return(command)
        allow(command).to receive(:run)
      end

      it 'loads the file from the current working directory' do
        expect_any_instance_of(LintTrappings::ConfigurationLoader)
          .to receive(:load).with(hash_including(working_directory: Dir.pwd))
          .and_return(LintTrappings::Configuration.new)
        subject
      end

      it 'resolves the configuration' do
        config = double
        allow_any_instance_of(LintTrappings::ConfigurationLoader)
          .to receive(:load).and_return(config)

        expect_any_instance_of(LintTrappings::ConfigurationResolver)
          .to receive(:resolve)
          .with(config, options)
          .and_return(LintTrappings::Configuration.new)

        subject
      end
    end
  end

  describe '.class_attribute' do
    context 'when an attribute was not declared in the class body' do
      let(:app_class) { Class.new(described_class) }

      it 'raises error when trying to access the attribute' do
        expect { app.name }.to raise_error LintTrappings::ApplicationConfigurationError,
                                           /`name` class attribute must be defined/

        expect { app_class.name }.to raise_error LintTrappings::ApplicationConfigurationError,
                                                 /`name` class attribute must be defined/
      end
    end

    context 'when an attribute was declared in the class body' do
      let(:app_class) do
        Class.new(described_class) do
          name 'MyApp'
        end
      end

      it 'returns the declared value' do
        expect(app.name).to eq 'MyApp'
        expect(app_class.name).to eq 'MyApp'
      end
    end
  end
end
