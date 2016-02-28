require 'forwardable'

module LintTrappings
  # Stores runtime configuration for the application.
  class Configuration
    # The path of this configuration, if it was loaded from a file.
    #
    # Used in certain scenarios to determine the absolute path of a file
    # specified in a configuration (i.e. getting the path relative to the
    # location of the configuration file itself).
    #
    # @return [String]
    attr_accessor :path

    # Creates a configuration from the given options hash.
    #
    # @param options [Hash]
    def initialize(options = {})
      @hash = options.dup
    end

    # Compares this configuration with another.
    #
    # @param other [LintTrappings::Configuration]
    #
    # @return [true,false] whether the given configuration is equivalent
    def ==(other)
      super || @hash == other.hash
    end

    def fetch(*args, &block)
      @hash.fetch(*args, &block)
    end

    def [](key)
      @hash[key]
    end

    def delete(key)
      @hash.delete(key)
    end

    # Merges the given configuration with this one.
    #
    # The provided configuration will either add to or replace any options
    # defined in this configuration.
    #
    # @param config [LintTrappings::Configuration]
    #
    # @return [LintTrappings::Configuration]
    def merge(config)
      merged_hash = smart_merge(@hash, config.hash)
      self.class.new(merged_hash)
    end

    def for_linter(linterish)
      linter_name =
        case linterish
        when Class, LintTrappings::Linter
          linterish.canonical_name
        else
          linterish.to_s
        end

      conf = @hash.fetch('linters', {}).fetch(linter_name, {}).dup
      conf['severity'] ||= @hash.fetch('default_severity', :error)
      conf['severity'] = conf['severity'].to_sym
      conf
    end

    protected

    # Internal hash storing the configuration.
    attr_reader :hash

    private

    # Merge two hashes such that nested hashes are merged rather than replaced.
    #
    # @param parent [Hash]
    # @param child [Hash]
    # @return [Hash]
    def smart_merge(parent, child)
      parent.merge(child) do |_key, old, new|
        case old
        when Hash
          smart_merge(old, new)
        else
          new
        end
      end
    end
  end
end
