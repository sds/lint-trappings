require 'spec_helper'
require 'fileutils'

RSpec.describe LintTrappings::FileFinder do
  describe '.find' do
    let(:files) { [] }
    let(:allowed_extensions) { %w[.lint] }

    let(:options) do
      {}.tap do |opts|
        opts[:included_paths] = included_paths if respond_to?(:included_paths)
        opts[:excluded_paths] = excluded_paths if respond_to?(:excluded_paths)
        opts[:included_patterns] = included_patterns if respond_to?(:included_patterns)
        opts[:excluded_patterns] = excluded_patterns if respond_to?(:excluded_patterns)
        opts[:allowed_extensions] = allowed_extensions
      end
    end

    subject { described_class.find(options) }

    around do |example|
      directory do
        files.each do |file|
          FileUtils.mkdir_p(File.join(File.dirname(file).split('/')))
          FileUtils.touch(file)
        end

        example.run
      end
    end

    context 'when included_paths contains a non-existent file/directory' do
      let(:included_paths) { %w[nonexistent.file] }

      it 'raises' do
        expect { subject }.to raise_error LintTrappings::InvalidFilePathError
      end
    end

    context 'when included_paths contains a matching file' do
      let(:files) { %w[file.lint] }
      let(:included_paths) { %w[file.lint] }

      it { should == %w[file.lint] }

      context 'and that file is an excluded path' do
        let(:excluded_paths) { %w[file.lint] }

        it { should == [] }
      end

      context 'and that file is an excluded pattern' do
        let(:excluded_patterns) { %w[file.*] }

        it { should == [] }
      end
    end

    context 'when included_paths contains a directory' do
      let(:included_paths) { %w[directory] }

      context 'and the directory contains no matching files' do
        let(:files) { %w[directory/file.nomatch] }

        it { should == [] }
      end

      context 'and the directory contains matching files' do
        let(:files) { %w[directory/file.lint] }

        it { should == [File.join(%w[directory file.lint])] }

        context 'and that file is an excluded path' do
          let(:excluded_paths) { [File.join(%w[directory file.lint])] }

          it { should == [] }
        end

        context 'and that file is an excluded pattern' do
          let(:excluded_patterns) { %w[**/file.*] }

          it { should == [] }
        end

        context 'and that directory is an excluded path' do
          let(:excluded_paths) { %w[directory] }

          it { should == [] }
        end

        context 'and that directory is an excluded pattern' do
          let(:excluded_patterns) { [File.join(%w[directory ** *])] }

          it { should == [] }
        end
      end
    end

    context 'when included_patterns matches no file' do
      let(:included_patterns) { %w[nonexistent.file] }

      it 'raises' do
        expect { subject }.to raise_error LintTrappings::InvalidFilePatternError
      end
    end

    context 'when excluded_patterns matches no file' do
      let(:excluded_patterns) { %w[nonexistent.file] }

      it 'does not raise' do
        should == []
      end
    end

    context 'when included_patterns matches files' do
      let(:files) { %w[file.lint file.otherext] }
      let(:included_patterns) { %w[file.*] }

      it { should == %w[file.lint file.otherext] }

      context 'and file is an excluded path' do
        let(:excluded_paths) { %w[file.lint] }

        it { should == %w[file.otherext] }
      end

      context 'and file is an excluded pattern' do
        let(:excluded_patterns) { %w[file.*] }

        it { should == [] }
      end
    end
  end
end
