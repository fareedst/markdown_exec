# Changelog

## [1.8.8] - 2024-01-15

### Added

- Debounce/Control repeated launching of the same block via the menu.

- Option to match block nicknames.
  Nicknames are used for scripting and are not displayed in the menu -- the block body is shown the menu.

- Option to execute script to launch Terminal window.
  Provide batch variables to use in the execute_command_format script.
  Limit iTerm window position to visible area.
  Store output of executed script.
  Menu to replay, review, and exit.

- Report line in document importing a missing file.

- Option to search for import files within each of the specified paths (recursion optional).

- Eval block loads (appends) local file to inherited lines.

- Eval block executes script and appends filtered output to inherited lines.
  Select output using begin and end matching lines.
  Transform selected output with per-line match and print specifications.

### Changed

- Sanitize block names in formatted lines above and below inherited code.

## [1.8.7] - 2023-12-31

### Added

- Option for block name that presents the menu.
- Options for decorating inherited lines in the menu.
- Options for parse and display of heading levels 1, 2, and 3.

### Changed

- Bypass chrome blocks when collecting dependencies.

## [1.8.6] - 2023-12-25

### Added

- Default path for find command.

### Changed

- Refactor command-line processing.

## [1.8.5] - 2023-12-22

### Added

- "eval" boolean value for Link blocks to compute lines to append to the inherited state.
- "return" boolean value for Link blocks to return to the original page.
- Options for dumping data associated with the menu or state.
- Debug and irb gems.

## [1.8.4] - 2023-12-15

### Added

- Options to dump blocks when processed.

### Changed

- Refactor code generation for and after Link blocks

## [1.8.2] - 2023-12-12

### Changed

- Set default colors.

## [1.8.1] - 2023-12-11

### Changed

- Name used in script saved file.

## [1.8] - 2023-12-11

### Changed

- Default colors.

### Added

- Run-time exception for unmet dependencies.
- Command to find text in directory name, file name, or file contents.
- Options to detect and display block dependency graph and exceptions.
- Options to dump parsed blocks structures.
- Options to add labels to shell code blocks.

## [1.7] - 2023-12-01

### Added

- Options to format menu and output blocks.
- Control display of imported content.
- Example documents.

## [1.6] - 2023-11-13

### Added

- Options to remember a block's indentation in the source document and to display with same indentation in the menu.

### Changed

- Note option matches the remaining lines in the document and they are displayed in the menu.

## [1.5] - 2023-11-08

### Added

- Confirmation between execution of block and display of next menu.
- Option for block loaded automatically per document.
- Options for note lines copied from source into menu.
- Options to format menu chrome.
- Options to generate title for a block without a name.
- Remove consecutive blank lines from menu.
- Restore options between menu choices. Add options for "notes" in menu.

## [1.4.1] - 2023-11-02

### Added

- Support for nested links.
  A Link block name can be followed by the block name to execute in the linked document.
  Nested links result in scripts with nested required blocks.

## [1.4] - 2023-10-31

### Added

- Add required code blocks to link block types.
  Allows for nested required code as links are navigated.

- Add fg_rgbh_* methods to process hex RGB specifications.

## [1.3.9] - 2023-10-29

Add block types for linking and variable control

Rename options to match use.

### Added

- Pass-through arguments after "--" to the executed script.
  See document `examples/pass-through.md`.

- Add RGB color specification to basic ANSI color names.
  Foreground R, G, and B values are encoded in the name "fg_rgb_R_G_B" with their decimal values.
  e.g. red = "fg_rgb_255_0_0"
  e.g. green = "fg_rgb_0_255_0"
  e.g. blue = "fg_rgb_0_0_255"

- Add a "link" fenced code block type as a menu choice to load a different document.
  The `link` block can specify:
  - environment variables and values to set prior to loading the document,
  - a block name to execute in the loaded document.
  In the resulting menu, an automatic option (Back) allows the user to return to the original document.
  See documents `examples/linked1.md`, `examples/linked2.md`.

- Add an "opts" fenced code block type as a menu choice to set current MDE options.
  See document `examples/opts.md`.

- Add a "vars" fenced code block type as a menu choice to set current environment variables.
  See document `examples/vars.md`.
  These blocks can be hidden blocks and required in a script.

- Add a "wrap" fenced code block type to facilitate script generation.
  See document `examples/wrap.md`.
  These blocks are hidden and can be required by one or more blocks.

### Changed

- Rename RegExp options to match use.

## [1.3.8] - 2023-10-20

### Added

- Options for hidden, included, and wrapped blocks

## [1.3.7] - 2023-10-16

### Changed

- Fix invocation of SavedAsset class

## [1.3.6] - 2023-10-15

### Added

- Option to inhibit display of menu decorations/chrome
- Options for tasks

## [1.3.5] - 2023-10-05

### Changed

- Fix display of menu dividers

## [1.3.3] - 2023-10-03

### Added

- Nest scripts by using an `import` directive

### Changed

- Convert constants for block selection into options

## [1.3.2] - 2022-11-12

### Added

- Add RSpec tests for internal classes

## [1.3.1] - 2022-10-29

### Added

- Delay to allow all command output to be received
- Display an error message when the specified document file is missing
- Options to display, format and colorize menu dividers and demarcations
- Tab completion for short option names

### Changed

- Fix handling of document supplied by process substitution

## [1.3.0] - 2022-07-16

### Added

- Short name `-p` for `--user-must-approve` option
  Enable/disable pause for user to review and approve script
- Automatic wrapping for data in blocks of yaml data eg ` ```yaml `
  Data is written to the file named in the fenced block heading
- Data transformations are embedded in the script at every invocation
  with arguments to the transformation as stdin and stdout for the `yq` process
  eg `export fruit_summary=$(yq e '[.fruit.name,.fruit.price]' fruit.yml)`
  for invocation `%(summarize_fruits <fruit.yml >fruit_summary)`
  and transformation `[.fruit.name,.fruit.price]`
- Option to extract document text and display it as disabled items in-line with the blocks in the selection menu
  Add options for constants used in parsing
- [x] yaml processing
    - ```yaml :(make_fruit_file) >fruit.yml```
      write to: fruit.yml
    - ```yq [summarize_fruits] +(make_fruit_file) <fruit.yml =color_price```
      not included in linear script
      read from: fruit.yml
      result into var: color_price instead of stdout
    - ```bash :show_fruit_yml +(summarize_fruits)```
      include summarize_fruits
      output value of var color_price

### Changed

- Refactoring
    - Run-time menu in YAML file
    - Tap module initialization

## [1.2.0] - 2022-06-11

### Added

- Options
    - Display document name in block selection menu
    - Display headings (levels 1,2,3) in block selection menu
- Trap Ctrl-C (SIGTERM) while script is executing
  Completes MDE processes such as saving output and reporting results

### Changed

- Refactoring

## [1.1.1] - 2022-05-25

### Added

- Post-install instructions to add tab completions permanently to the shell

### Changed

- Improve handling of threads ending while executing scripts

## [1.1.0] - 2022-05-21

### Added

- Display administrative output (command, save files) for executed blocks.
- Select base, administrative output as hierarchical output (MDE_DISPLAY_LEVEL).
- The user may select Exit, the first option, to quit the program.
- The block-selection menu is re-displayed after an approved script is exectued.
- Pause for and pass through standard input in scripts executed by the tool.
- Options
    - chmod for saved scripts
    - shebang for saved scripts
    - shell for executed and saved scripts

### Changed

- Exit option is at top of each menu.
- Single-stage tab completion, default
    - Presents matching options when current word starts with `-`
    - Presents directories and files otherwise.
- Two-stage tab completion for option arguments.
    - When prior word is an option and current word is empty
    - Presents option type on first tab, eg `.BOOL.` for a boolean option.
    - Presents option default value on second tab, eg `0` for false.
- Write STDOUT, STDERR, STDIN in sections to saved output file.

## [1.0.0] - 2022-04-26

### Added

- Command `--pwd` to print the gem's home folder.
- Command `--select-recent-output` to select and open a recent output log file.
e.g. `MDE_OUTPUT_VIEWER_OPTIONS="-a '/Applications/Sublime Text.app'" mde --select-recent-output`
- Command `--tab-completions` to list the application options.
- Tab completion script for Bash shell.

### Changed

- File names for saved scripts.
- Hide blocks with empty names, e.g. `:()`.

## [0.2.6] - 2022-04-07

### Changed

- Default values for command line options.

## [0.2.5] - 2022-04-03

### Added

- Command `--list-default-env` to show default configuration as environment variables.
- Command `--list-default-yaml` to show default configuration as YAML.
- Option to exit program when selecting files or blocks.

### Changed

- Composition of menu to facilitate reports.
- List default values in menu help.

## [0.2.4] - 2022-04-01

### Added

- Command `--list-recent-scripts` to list the last *N* saved scripts.
- Command `--run-last-script` to re-run the last saved script.
- Command `--select-recent-script` to select and execute a recently saved script.

| YAML Name | Environment Variable | Option Name | Default | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| list_count | MDE_LIST_COUNT | `--list-count` | `16` | Max. items to return in list |
| logged_stdout_filename_prefix | MDE_LOGGED_STDOUT_FILENAME_PREFIX | | `mde` | Name prefix for stdout files |
| save_execution_output | MDE_SAVE_EXECUTION_OUTPUT | `--save-execution-output` | False | Save standard output of the executed script |
| saved_script_filename_prefix | MDE_SAVED_SCRIPT_FILENAME_PREFIX | | `mde` | Name prefix for saved scripts |
| saved_script_folder | MDE_SAVED_SCRIPT_FOLDER | `--saved-script-folder` | `logs` | Saved script folder |
| saved_script_glob | MDE_SAVED_SCRIPT_GLOB | | `mde_*.sh` | Glob matching saved scripts |
| saved_stdout_folder | MDE_SAVED_STDOUT_FOLDER | `--saved-stdout-folder` | `logs` | Saved stdout folder |

### Changed

- Fix saving of executed script.
- Sort configuration keys output by `-0` (Show configuration.)

## [0.2.3] - 2022-03-29

### Added

- `rubocop` checks.
- Added optional command-line positional arguments:
  1. document file
  2. block name

	e.g. `mde doc1 block1` will execute the block named `block1` in file `doc1`.

### Changed

- Naming saved script files: The file name contains the time stamp, document name, and block name.
- Renamed folder with fixtures.
- Command options:

| YAML Name | Environment Variable | Option Name | Default | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| debug | MDE_DEBUG | `--debug` | False | Output debugging information (verbose) |
| filename | MDE_FILENAME | `--filename` | `README.md`* | File name of document |
| output_execution_summary | MDE_OUTPUT_STDOUT_SUMMARY | `--output-execution-summary` | False | Display summary for execution |
| output_script | MDE_OUTPUT_SCRIPT | `--output-script` | False | Display script |
| output_stdout | MDE_OUTPUT_EXECUTION | `--output-stdout` | True | Display standard output from execution |
| path | MDE_PATH | `--path` | `.` | Path to document(s) |
| save_executed_script | MDE_SAVE_EXECUTED_SCRIPT | `--save-executed-script` | False | Save executed script |
| saved_script_folder | MDE_SAVED_SCRIPT_FOLDER | `--saved-script-folder` | `logs` | Saved script folder |
| select_page_height | MDE_SELECT_PAGE_HEIGHT |  | `12` | Menu page height (maximum) |
| user_must_approve | MDE_USER_MUST_APPROVE | `--user-must-approve` | True | Pause to approve execution |

- Configuration options:

| YAML Name | Environment Variable | Default |
| :--- | :--- | :--- |
| block_name_hidden_match | MDE_BLOCK_NAME_HIDDEN_MATCH  | `^\(.+\)$` |
| block_name_match | MDE_BLOCK_NAME_MATCH  | `:(?<title>\S+)( \|$)` |
| block_required_scan | MDE_BLOCK_REQUIRED_SCAN  | `\+\S+` |
| fenced_start_and_end_regex | MDE_FENCED_START_AND_END_REGEX  | ``^`{3,}`` |
| fenced_start_extended_regex | MDE_FENCED_START_EXTENDED_REGEX  | ``^`{3,}(?<shell>[^`\s]*) *(?<name>.*)$`` |
| heading1_match | MDE_HEADING1_MATCH  | `^# *(?<name>[^#]*?) *$` |
| heading2_match | MDE_HEADING2_MATCH  | `^## *(?<name>[^#]*?) *$` |
| heading3_match | MDE_HEADING3_MATCH  | `^### *(?<name>.+?) *$` |
| md_filename_glob | MDE_MD_FILENAME_GLOB  | `*.[Mm][Dd]` |
| md_filename_match | MDE_MD_FILENAME_MATCH  | `.+\\.md` |

Most options can be configured in multiple ways. In order of use (earliest superceded by last):
1. environment variables
2. the configuration file `.mde.yml` in the current folder
3. command line arguments

#### Representing boolean values

Boolean values for options are specified as strings and interpreted as:
| Value | Boolean |
| :---: | :---: |
| *empty string* | False |
| `0` | False |
| `1` | True |
| *anything else* | True |

E.g. `opt1=1` will set option `opt1` to True.

Boolean options configured with environment variables:
- Set to `1` or non-empty value to save executed scripts; empty or `0` to disable saving.
  e.g. `export MDE_SAVE_EXECUTED_SCRIPT=1`
  e.g. `export MDE_SAVE_EXECUTED_SCRIPT=`
- Specify variable on command line.
  e.g. `MDE_SAVE_EXECUTED_SCRIPT=1 mde`

## [0.2.2] - 2022-03-17

- Update documentation.

## [0.2.1] - 2022-03-12

- Accept file or folder as first optional positional argument.
- Hide blocks with parentheses in the name, like "(name)". This is useful for blocks that are to be required and not selected to execute alone.

## [0.2.0] - 2022-03-12

- Improve processing of file and path sepcs.

## [0.1.0] - 2022-03-06

- Initial release
