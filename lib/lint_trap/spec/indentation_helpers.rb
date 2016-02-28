module LintTrap::Spec::IndentationHelpers
  # Strips off excess leading indentation from each line so we can use Heredocs
  # for writing code without having the leading indentation count.
  def normalize_indent(code)
    LintTrap::Utils.normalize_indent(code)
  end
end
