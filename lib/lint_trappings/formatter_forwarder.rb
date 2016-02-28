module LintTrappings
  # Contains a collection of formatters and their output destinations, exposing
  # them a single formatter.
  #
  # This quacks like a Formatter so that it can be used in place of a single
  # formatter, but fans out the calls to all formatters in the collection.
  class FormatterForwarder
    def initialize(formatters)
      @formatters = formatters
    end

    %i[
      started
      job_started
      job_finished
      finished
    ].each do |method_sym|
      define_method method_sym do |*args|
        @formatters.each { |formatter| formatter.send(method_sym, *args) }
      end
    end
  end
end
