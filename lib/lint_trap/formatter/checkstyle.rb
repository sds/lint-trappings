require 'lint_trap/formatter/base'
require 'stringio'

module LintTrap::Formatter
  # Outputs results in a Checkstyle-compatible format.
  #
  # @see http://checkstyle.sourceforge.net/
  class Checkstyle < Base
    def finished(report)
      xml = StringIO.new
      xml << "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"

      xml << "<checkstyle version=\"1.5.6\">\n"
      report.lints.group_by(&:path).each do |path, lints|
        file_name_absolute = File.expand_path(path)
        xml << "  <file name=#{file_name_absolute.encode(xml: :attr)}>\n"

        lints.each do |lint|
          xml << "    <error source=\"#{lint.linter.canonical_name if lint.linter}\" " \
             "line=\"#{lint.location.line}\" " \
             "column=\"#{lint.location.column}\" " \
             "length=\"#{lint.location.length}\" " \
             "severity=\"#{lint.severity}\" " \
             "message=#{lint.message.encode(xml: :attr)} />\n"
        end

        xml << "  </file>\n"
      end
      xml << "</checkstyle>\n"

      output.print xml.string
    end
  end
end
