# LintTrappings

[![Gem Version](https://badge.fury.io/rb/lint_trappings.svg)](http://badge.fury.io/rb/lint_trappings)
[![Build Status](https://travis-ci.org/sds/lint-trappings.svg?branch=master)](https://travis-ci.org/sds/lint-trappings)
[![Code Climate](https://codeclimate.com/github/sds/lint-trappings.svg)](https://codeclimate.com/github/sds/lint-trappings)
[![Coverage Status](https://coveralls.io/repos/sds/lint-trappings/badge.svg)](https://coveralls.io/r/sds/lint-trappings)
[![Dependency Status](https://gemnasium.com/sds/lint-trappings.svg)](https://gemnasium.com/sds/lint-trappings)
[![Inline docs](http://inch-ci.org/github/sds/lint-trappings.svg?branch=master)](http://inch-ci.org/github/sds/lint-trappings)

> [**trappings**](https://www.google.com/search?q=trappings): the outward signs,
> features, or objects associated with a particular situation, role, or thing.

> "It had the trappings of success"

**LintTrappings** is a Ruby framework for writing static analysis command line tools
(a.k.a. "linters"). It provides a large amount of functionality out of
the box so that the uninteresting aspects of writing one of these tools
(command line argument processing, configuration loading, file exclusion, etc.)
are managed by the framework instead of yourself.

Development of LintTrappings was inspired by a number of static analysis tools
I've built and maintained over the years, including [scss-lint], [haml-lint],
and [slim-lint]. A common set of patterns and functionality began to appear,
which have been extracted into this framework. It makes it far easier to get
started writing your own automated static analysis tool.

[scss-lint]: https://github.com/brigade/scss-lint
[haml-lint]: https://github.com/brigade/haml-lint
[slim-lint]: https://github.com/sds/slim-lint

* [Requirements](#requirements)
* [Configuration](#configuration)
* [Documentation](#documentation)
* [Contributing](#contributing)
* [Change History](#change-history)
* [License](#license)

## Requirements

 * Ruby 2.0+

## Configuration

### Application Configuration

When creating your own application, you need to create a class that inherits
`LintTrappings::Application`:

```ruby
module MyApp
  class Application < LintTrappings::Application
    name                      'MyApp'
    executable_name           'my-app'
    version                   MyApp::VERSION

    configuration_file_names  %w[.my-app.yaml .my-app.yml]
    file_extensions           %w[txt text]

    # Specify the default configuration that all configurations extend.
    # The example below loads the file from your gem's config/default.yaml
    # (make sure you include it in your gemspec's `files` setting!)
    base_configuration        MyApp::Configuration.new(
                                YAML.load_file(
                                  File.join(File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
                                            'config',
                                            'default.yaml')
                                )
                              )

    # Shown when an unhandled exception occurs so users know where to file issues
    home_url 'https://github.com/your-user/my-app'
    issues_url 'https://github.com/your-user/my-app/issues'

    # Path to the directory in your gem where built-in linters are defined
    linters_directory         File.join(gem_dir, 'lib', 'my_app', 'linter')

    # Class to use when figuring out all registered linters
    # (any subclass of this class is a registered linter).
    # Even if your base linter class has no custom logic, you still need to
    # define one to make sure your linter hierarchy is explorable.
    linter_base_class MyApp::Linter

    # Class to use to parse documents that will be linted.
    # Your implementation needs to define the `process_source` method.
    document_class MyApp::Document
  end
end
```

### Configuration File

LintTrappings supports a large collection of configuration options in your
application's YAML file. These are values that can be tweaked by the users
of your application without you having to write any code–they all work out
of the box.

```yaml
# List of configuration files to extend. These files will be loaded and
# merged with each other in order from first to last (last wins if they
# define values for the same configuration key), and finally will be merged
# with this configuration file.
#
# This is useful if you want to break apart your configuration into separate
# components for organizational purposes.
#
# The files are loaded relative to the location of this configuration file
# if the paths are not absolute.
extends:
  - 'some/config/file.yaml'
  - 'some/other/config/file.yaml'

# The types of severities that can be reported, and whether or not they
# would result in a warning or a failed run. A warning would still result
# in a successful exit status (zero), while a failure would result in
# a non-zero exit status and would thus fail in a test environment or CI.
severities:
  refactor: warn
  warning: warn
  error: fail
  fatal: fail

# If no severity is explicitly specified in a linter's configuration, any
# problem reported by the linter is assigned this severity.
default_severity: error

# Defines the list of extensions of files to include when recursively searching
# under directory paths. This allows you to specify directories in your
# `include`/`exclude` paths without needing the `**/*.ext` glob.
file_extensions:
  - txt
  - text

# Define a list of paths to include/exclude from linting.
# A path can be a directory or a file. Matching directories result in a
# recursive scan.
include:
  - 'some-file.txt'
  - 'some/directory/path'
  - 'some/glob/for/files/*.txt'
exclude:
  - 'some-other-file.txt'
  - 'everything/under/this/directory/excluded'
  - 'every/txt/file/under/this/directory/excluded/**/*.txt'

# AVOID USING THESE (provided for users with weird file names)
# Define an explicit list of literal paths to include/exclude from linting.
# A path can be a directory or a file. Prefer the `include`/`exclude`
# options as those allow you to specify globs. Use these options if
# your files have glob characters in their name which you need to match
# against. (`*`,`{`, etc.)
include_paths:
  - some/directory/path
  - some*file.txt # <- "*" treated as a literal asterisk in this context!
exclude_paths:
  - 'some/directory/path'
  - 'some*file.txt' # <- "*" treated as a literal asterisk in this context!

# List of directories to load custom linter implemenations from. This allows
# developers to easily write their own one-off custom linters for a repository.
#
# Directories are recursively scanned for `*.rb` files, so make sure you keep
# only linter implementaions in that directory, and no other Ruby files!
#
# If you find yourself needing the same custom linters in multiple projects,
# you should pull them out into a separate gem and load it via the
# `linter_plugins` option.
linter_directories:
  - custom-linters
  - path/to/more/linters

# List of paths to load via `require`. Will load any linter implementations
# and also extend any configuration defined in the gem. Note that this allows
# you to ship gems that only contain configuration, allowing you to reuse
# configuration across multiple projects.
#
# See the documentation on creating a reusable gem for how to create your own.
linter_plugins:
  - my_custom_linters
  - more_custom_linters

# A collection of all linter configurations. This will be the main point of
# configuration for most users of your application. Linter names must match
# their class name in both spelling and case.

# This can be used to configure built-in linters as well as any custom linters
# loaded via the `linter_directories` or `linter_plugins` options.
#
# Values specified here will overwrite values specified in configurations
# loaded via `extends` or `linter_plugins`, so this file has the final say.
linters:
  MyLinter:
    enabled: true     # If false, skips running this linter
    severity: warning # If unspecified, defaults to `default_severity`

    # Custom options are set here; run `my-app --show-docs MyLinter` to see
    # documentation of all options available to a given linter.
    some_option: true

    include: # List of file paths to include. The linter will ignore all others.
      - 'some/file.txt'
      - 'some/directory'
    exclude: # List of file paths to exclude. The linter will ignore any of these.
      - 'some/other/file.txt'
      - 'some/nested/**/directory'

  MyOtherLinter:
    ...

# Specifies the command that should be run to transform files before they are
# linted. Command will be passed the content of the file via the standard input
# stream and anything sent to the standard output stream will be passed to the
# linter.
# Remember that if your preprocessing alters the file such that line numbers
# change, then the linter may report line numbers that are different from the
# original file.
preprocess_command: "sed '1,2s/---//'" # Removes Jekyll front matter

# By default `preprocess_command` enables the preprocessor for all files. To
# only preprocess certain files, add paths/glob patterns to this list.
preprocess_files:
  - 'path/to/files/to/preprocess'
  - 'another/path/**/*.txt'
```

## Documentation

[Code documentation] is generated with [YARD] and hosted by [RubyDoc.info].

[Code documentation]: http://rdoc.info/github/sds/lint-trap/master/frames
[YARD]: http://yardoc.org/
[RubyDoc.info]: http://rdoc.info/

## Contributing

We love getting feedback with or without pull requests. If you do add a new
feature, please add tests so that we can avoid breaking it in the future.

## Change History

If you're interested in seeing the changes and bug fixes between each version
of LintTrappings, read the [LintTrappings Change History](CHANGELOG.md).

## License

This project is released under the [MIT license](LICENSE.md).
