require 'find'

module LintTrappings
  # Finds files that should be linted.
  module FileFinder
    class << self
      # Return list of lintable files given the specified set of paths and glob
      # pattern search criteria.
      #
      # The distinction between paths and globs is so files with a `*` in their
      # name can still be matched if necessary without treating them as a glob
      # pattern.
      #
      # @param options [Hash]
      # @option options :included_paths [Array<String>] files/directories to include
      # @option options :excluded_paths [Array<String>] files/directories to exclude
      # @option options :included_patterns [Array<String>] glob patterns to include
      # @option options :excluded_patterns [Array<String>] glob patterns to exclude
      # @option options :file_extensions [Array<String>] extensions of files to
      #   include when searching directories specified by included_paths
      #
      # @raise [InvalidFilePathError] if included_paths/excluded_paths don't exist
      # @raise [InvalidFilePatternError] if any included_pattern doesn't match any files
      #
      # @return [Array<String>] list of matching files in lexicographic order
      def find(options)
        included_paths = options.fetch(:included_paths, []).map { |p| normalize_path(p) }
        excluded_paths = options.fetch(:excluded_paths, []).map { |p| normalize_path(p) }
        included_patterns = options.fetch(:included_patterns, []).map { |p| normalize_path(p) }
        excluded_patterns = options.fetch(:excluded_patterns, []).map { |p| normalize_path(p) }
        allowed_extensions = options.fetch(:allowed_extensions)

        included_files = expand_paths(included_paths, included_patterns, allowed_extensions)
        matching_files = filter_files(included_files, excluded_paths, excluded_patterns)

        matching_files.uniq.sort
      end

      private

      # Expand included paths to include lintable files under paths which are
      # directories.
      #
      # @param paths [Array<String>]
      # @param patterns [Array<String>]
      # @param allowed_extensions [Array<String>]
      #
      # @return [Array<String>]
      def expand_paths(paths, patterns, allowed_extensions)
        find_files_in_paths(paths, allowed_extensions) + find_matching_files(patterns)
      end

      # Exclude specified files from the list of included files, expanding the
      # excluded paths as necessary.
      #
      # @param included_paths [Array<String>]
      # @param excluded_paths [Array<String>]
      # @param excluded_patterns [Array<String>]
      #
      # @return [Array<String>]
      def filter_files(included_files, excluded_paths, excluded_patterns)
        # Convert excluded paths to patterns so we don't need to actually hold
        # all excluded files in memory
        excluded_patterns = excluded_patterns.dup
        excluded_paths.each do |path|
          if File.directory?(path)
            excluded_patterns << File.join(path, '**', '*')
          elsif File.file?(path)
            excluded_patterns << path
          else
            raise LintTrappings::InvalidFilePathError,
                  "Excluded path '#{path}' does not correspond to a valid file"
          end
        end

        included_files.reject do |file|
          LintTrappings::Utils.any_glob_matches?(excluded_patterns, file)
        end
      end

      # Search the specified paths for lintable files.
      #
      # If path is a directory, searches the directory recursively.
      #
      # @param paths [Array<String>]
      # @param allowed_extensions [Array<String>]
      #
      # @return [Array<String>]
      def find_files_in_paths(paths, allowed_extensions)
        files = []

        paths.each do |path|
          if File.directory?(path)
            files += find_files_in_directory(path, allowed_extensions)
          elsif File.file?(path)
            files << path
          else
            raise LintTrappings::InvalidFilePathError,
                  "Path '#{path}' does not correspond to a valid file or directory"
          end
        end

        files.uniq.map { |path| normalize_path(path) }
      end

      # Recursively search the specified directory for lintable files.
      #
      # @param directory [String]
      # @param allowed_extensions [Array<String>]
      #
      # @return [Array<String>]
      def find_files_in_directory(directory, allowed_extensions)
        files = []

        ::Find.find(directory) do |path|
          files << path if lintable_file?(path, allowed_extensions)
        end

        files
      end

      # Find all files matching the specified glob patterns.
      #
      # @param patterns [Array<String>] glob patterns
      #
      # @return [Array<String>]
      def find_matching_files(patterns)
        files = []

        patterns.each do |pattern|
          matches = ::Dir.glob(pattern,
                               ::File::FNM_PATHNAME | # Wildcards don't match path separators
                               ::File::FNM_DOTMATCH)  # `*` wildcard matches dotfiles

          if matches.empty?
            # One of the patterns specified does not match anything; raise a more
            # descriptive exception so we know which one
            raise LintTrappings::InvalidFilePatternError,
                  "Glob pattern '#{pattern}' does not match any file"
          end

          matches.each do |path|
            files << path if File.file?(path)
          end
        end

        files.flatten.uniq.map { |path| normalize_path(path) }
      end

      # Trim "./" from the front of relative paths.
      #
      # @param path [String]
      #
      # @return [String]
      def normalize_path(path)
        path.start_with?(".#{File::SEPARATOR}") ? path[2..-1] : path
      end

      # Whether a file should be treated as lintable.
      #
      # @param file [String]
      # @param allowed_extensions [Array<String>]
      #
      # @return [Boolean]
      def lintable_file?(file, allowed_extensions)
        return false unless ::File.file?(file)
        allowed_extensions.include?(::File.extname(file))
      end
    end
  end
end
