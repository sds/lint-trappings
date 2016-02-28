# rubocop:disable Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength

module LintTrappings::Matchers
  # RSpec matcher that returns whether or not a linter reported lints matching
  # the specified criteria.
  #
  # @example
  #
  #   it { should report_lint line: 2 }
  class ReportLintMatcher
    ALLOWED_KEYWORD_ARGUMENTS = %i[line message].freeze

    def initialize(*args, **kwargs)
      @options = kwargs

      if args.any?
        raise ArgumentError,
              '`report_lint` was given more than one argument!' if args.length > 1

        if @options[:line]
          raise ArgumentError,
                '`line` keyword argument cannot be specified when Range is given'
        end

        @range = args.first
        if @range.is_a?(Array)
          if @range.length != 2 ||
             !@range.first.is_a?(Integer) ||
             !@range.last.is_a?(Integer)
            raise ArgumentError,
                  'Location tuple must be an Array of two integers ' \
                  "representing line and column, but was #{@range.inspect}"
          end

          # Convert to an actual range by assuming it spans nothing
          @range = @range..@range
        elsif !@range.is_a?(Range)
          raise ArgumentError, '`report_lint` must be given a Range e.g. [1, 2]..[3, 4]'
        elsif !(@range.begin.is_a?(Array) && @range.end.is_a?(Array))
          raise ArgumentError, 'Source range must have Array tuple endpoints'
        end
      else
        # Otherwise no explicit range was specified, so verify the options
        @options.keys.each do |key|
          raise ArgumentError,
                "Unknown keyword argument #{key}" unless ALLOWED_KEYWORD_ARGUMENTS.include?(key)
        end

        @line = @options[:line]
      end

      @message = @options[:message] if @options[:message]
    end

    def matches?(linter)
      # We're cheating by accessing private values here, but it will allow us to
      # present more-helpful error messages since we get access to so much more
      # information by passing the linter instead of just a list of lints.
      @linter = linter
      @lints = linter.instance_variable_get(:@lints)

      any_lint_matches?
    end

    def failure_message
      output = 'expected that a lint would be reported'

      if !any_range_matches?
        output <<
          if @line
            " on line #{@line}"
          elsif @range
            " on #{range_to_str(@range)}"
          end.to_s

        output <<
          case @lints.count
          when 0
            ', but none were'
          when 1
            if @line
              ", but was reported on line #{@lints.first.source_range.begin.line}"
            elsif @range
              ", but was reported on #{range_to_str(@lints.first.source_range)}"
            end.to_s
          else
            if @line
              ", but lints were reported on the following lines instead:\n" +
                @lints.map { |lint| lint.source_range.line }.sort.join(', ')
            elsif @range
              ", but lints were reported on the following ranges instead:\n" +
                @lints.map { |lint| range_to_str(lint.source_range) }.join("\n")
            end.to_s
          end
      elsif @message
        matching_lints = lints_matching_range
        output <<
          if @message.is_a?(Regexp)
            " with message matching pattern #{@message.inspect} "
          else
            " with message #{@message.inspect} "
          end

        output << "but got:\n" << matching_lints.map(&:message).join("\n")
      end

      output
    end

    def failure_message_when_negated
      'expected that a lint would NOT be reported'
    end

    def description
      output = 'report a lint'
      output <<
        if @line
          " on line #{@line}"
        elsif @range
          " on #{range_to_str(@range)}"
        end.to_s

      output
    end

    private

    def lints_matching_range
      @lints.select { |lint| range_matches?(lint) }
    end

    def any_lint_matches?
      return true if !@line && !@range && @lints.any?
      lints_matching_range.any? { |lint| message_matches?(lint) }
    end

    def any_range_matches?
      @lints.any? do |lint|
        range_matches?(lint)
      end
    end

    def range_matches?(lint)
      if @line
        lint.source_range.begin.line == @line
      else
        lint.source_range == @range
      end
    end

    def message_matches?(lint)
      if @message.nil?
        true
      elsif @message.is_a?(Regexp)
        lint.message =~ @message
      elsif @message.is_a?(String)
        lint.message == @message
      end
    end

    def range_to_str(range)
      "(L#{range.begin.line},C#{range.begin.column})..(L#{range.end.line},C#{range.end.column})"
    end
  end

  def report_lint(*args, **kwargs)
    ReportLintMatcher.new(*args, **kwargs)
  end
end
