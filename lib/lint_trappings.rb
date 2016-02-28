# Load all modules necessary to work with the framework.
# Ordering here can be important depending on class references in each module.

require 'lint_trappings/errors'
require 'lint_trappings/configuration'
require 'lint_trappings/utils'
require 'lint_trappings/file_finder'
require 'lint_trappings/output'
require 'lint_trappings/document'
require 'lint_trappings/location'
require 'lint_trappings/lint'
require 'lint_trappings/linter'
require 'lint_trappings/linter_loader'
require 'lint_trappings/linter_selector'
require 'lint_trappings/report'
require 'lint_trappings/runner'
require 'lint_trappings/application'
