module LintTrap
  # Store location of a {Lint} in a document.
  class Location
    include Comparable

    attr_reader :line, :column

    # @param line [Integer] One-based index
    # @param column [Integer] One-based index
    def initialize(line = 1, column = 1)
      raise ArgumentError, "Line must be >= 0, but was #{line}" if line < 0
      raise ArgumentError, "Column must be >= 0, but was #{column}" if column < 0

      @line   = line
      @column = column
    end

    def ==(other)
      [:line, :column].all? do |attr|
        send(attr) == other.send(attr)
      end
    end

    alias eql? ==

    def <=>(other)
      [:line, :column].each do |attr|
        result = send(attr) <=> other.send(attr)
        return result unless result == 0
      end

      0
    end

    def to_s
      "(#{line},#{column})"
    end
  end
end
