# Load all modules necessary to work with the framework.
# Ordering here can be important depending on class references in each module.

require 'lint_trap/errors'
require 'lint_trap/configuration'
require 'lint_trap/utils'
require 'lint_trap/file_finder'
require 'lint_trap/output'
require 'lint_trap/document'
require 'lint_trap/location'
require 'lint_trap/lint'
require 'lint_trap/linter'
require 'lint_trap/linter_loader'
require 'lint_trap/linter_selector'
require 'lint_trap/report'
require 'lint_trap/runner'
require 'lint_trap/application'
