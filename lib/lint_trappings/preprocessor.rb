require 'open3'
require 'stringio'

module LintTrappings
  # Processes a collection of streams with the specified command.
  class Preprocessor
    def initialize(config)
      @config = config
      @command = @config['preprocess_command']
      @preprocess_files = @config['preprocess_files']
    end

    def preprocess_files(files_to_lint)
      return unless @command

      files_to_lint.each do |file_to_lint|
        preprocess(file_to_lint) if preprocess_file?(file_to_lint.path)
      end
    end

    private

    def preprocess(file_to_lint)
      contents, status = Open3.capture2(@command, stdin_data: file_to_lint.io.read)

      unless status.success?
        raise PreprocessorError,
              "Preprocess command `#{@command}` failed when passed the " \
              "contents of '#{file_to_lint.path}', returning an exit " \
              "status of #{status.exitstatus}."
      end

      file_to_lint.io = StringIO.new(contents)
    end

    def preprocess_file?(file)
      return true unless @preprocess_files
      Utils.any_glob_matches?(@preprocess_files, file)
    end
  end
end
