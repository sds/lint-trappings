module LintTrappings::Spec::IndentationHelpers
  # Strips off excess leading indentation from each line so we can use Heredocs
  # for writing code without having the leading indentation count.
  def normalize_indent(code)
    LintTrappings::Utils.normalize_indent(code)
  end
end
