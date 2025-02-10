# Changelog

## [2.8.0] - 2025-02-10

### Added

- Block type `ux` to facilitate the evaluation, display, and editing of shell variables.
  The body of the `ux` block is in YAML.

  A valid shell variable name is required as block key `name`. The remaining block keys are optional.

  When the block is executed, its value is computed from the `default`, `exec`, `prompt`, `transform`, and `validate` keys and its output is assigned to the shell variable.

  When a document is loaded, if one or more block names match `document_load_ux_block_name`, they are executed.
  `ux_auto_load_force_default` limits the setting of the shell variable resulting from the execution of blocks executed at this time.

  When an `ux` block is executed (after initial document load):
  If the `default` value is the `exec` symbol, the command in the `exec` key is executed and its output is processed.
  Else if the `allowed` value has one or more items, the user must pick from one of the items.
  Else if the `prompt` value exists, the user must enter a value or nothing for the `default` value. The user is prompted with `prompt_ux_enter_a_value`.
  Else the `default` value, as a string, is processed.

  The output is validated/parsed by the regular expression in `validate`.
  If the string matches, named groups are formatted with `menu_ux_row_format` and assigned to the shell variable.

  The default `menu_ux_row_format` looks like a shell variable assignment.
  If the output of `menu_ux_row_format` matches an immediately preceding table, the row is merged into that table.
  Else the output is decorated with `menu_ux_color`.

## [2.7.5] - 2025-02-02

### Added

- Option to control initial truncation of table cell text to fit screen width.
- Truncate text to fit table cell fit to screen width. Click on first row of any table to toggle.

### Changed

- Fix the display of collapsible sections.
- Fix the display of shell expansion and command substitution output.
- Hide gem sources in caller.deref.

## [2.7.3] - 2025-01-29

### Added

- Automatic loading of multiple Opts and Vars blocks when opening a document.

### Changed

- Fix text displayed when text is wrapped to the next line.
- Handle and report failure of single tests.

## [2.7.2] - 2025-01-03

### Added

- Block name comparison in FCB class.
- Option for automatic shell block per document.

### Changed

- Disable command substitution in comments.
- Fix the source reported by debug function ww0.
- Inverse the entire line to highlight the active menu line.
- Return single file if no globs in load block.
- Update the calculation and use of IDs for blocks used to retrieve the block selected from the menu.

## [2.7.1] - 2024-12-10

### Changed

- Register console dimensions prior to arguments.

## [2.7.0] - 2024-12-09

### Added

- Collapse or expand sections defined by heading and dividers per options, section definitions, and user interaction.
- Command substitution to displayed menu items.
- Margin on menu to highlight selections.
- Cycling to file selection menu.
- Print entire document if there are no active elements.
- Option to set a screen width. The document and interface are formatted to fit this dimension. The default is 0, which causes to read and use the console width.

### Changed

- Highlight prior selection in menu.
- Display live environment variable values in examples.

## [2.6.0] - 2024-11-27

### Added

- Ability to collapse and expand sections.
- Collapsible state configurable per document and per section.
- User can collapse and expand sections in the UI.
- Live shell variable expansion in text and various non-shell blocks.
- Option for name of function to manage executed scripts.

### Changed

- Tables are indented per the source.
- BATS test helper functions.

## [2.5.0] - 2024-10-27

### Added

- Block types for managing saved history files.
- Options for document configuration file names.
- Options for variable expansion in document and links.
- Options for displaying saved history.
- Indent imported blocks.
- Option for default shell (Bash or Sh).
- Option to enable cycling past top or bottom of menu.
- Options for matching table rows.
- Option to disable blocks with token in title.
- Remember and process start line for each block.
- Tests for published data.

### Changed

- Fix sorting of history menu choices.
- Color is optional for menu entries.
- Fix input source for prompt for input from user.

## [2.4.0] - 2024-09-12

### Added

- Commands to list, search, and view saved asset history.
- BATS tests for basic and common options.
- Options to format lists in report output.
- Options to format tables over multiple lines by role and order.
- Options for automatic menu entry to edit inherited code when none exists.
- Example documents for wrapped blocks, text and table formatting.

### Changed

- Rework argument processing.
- Update default line decorations. Avoid patterns likely to exist in code.
- Refactor block selection to default to all.
- Use AnsiString over String to decorate output.
- Handle Ctrl-C at menu.

## [2.3.0] - 2024-08-05

### Added

- In-line decoration of text
- ANSI graphics modes for text decoration.
- Translation from text to ANSI graphics.
- Options for decorations in three stages, with default (Main) in the middle.

## [2.2.0] - 2024-07-27

### Added

- Options to list recent saved assets.
- Short name for execute-in-own-window option.
- Short name for load-code option.

### Changed

- Improve handling of variations of block names.
- Remove functions to select recent saved assets.

## [2.1.0] - 2024-07-15

### Added

- Option to toggle the output of an execution report.
- Option to toggle a menu entry to view saved script and output files.
- Options for formatting and parsing saved script and output file names.

### Changed

- Fix handling of output streams for executed scripts to improve logging out output and addition to inherited code.
- YAML blocks are not executable from the menu.
- Fix collection of output of Link blocks.
- Pass-through arguments after "--" to the script.
- Remove app info from menu.yml.
- Remove test for unwanted arguments.
- Fix Link next_block_name when filename is used.
- In example doc, use nicknames to allow block content to be displayed.

## [2.0.8] - 2024-06-05

### Added

- Option to automatically resize the menu.
  Detect the maximum supported screen dimensions.
  Resize the terminal to the maximum dimensions.
  Every time the menu is displayed, format it to the terminal dimensions.

### Changed

- Remove "$" from saved file names to simplify handling.

## [2.0.7] - 2024-06-04

### Added

- Color names that set foreground and background color.
  Similar to the existing foreground-only color names.
  The background colors follow the foreground color values in the name.
  Two names, to accept values as decimal and hex.
- Example document for line wrapping.
- Menu entry to execute shell commands.
- Option to control menu entry for shell commands.
- Recognition of nicknames in command line processing.
- Trap user interrupting executing scripts.

### Changed

- Do not decorate indentations.
- Line-wrap and center headings.
  Headings are now centered, the text is case-folded and the color
  (foreground and background) is according to the level.
  Centering is based on the console width detected.
- Line-wrap normal document text and format headings.
- Parse lines into indentation, text, and trailing whitespace.
- Update nicknames example to exercise hidden blocks from the command line.
- The optional prompt to exit after execution is now more frequent.
- Set characters used in saved file names

## [2.0.6] - 2024-05-28

### Added

- Color-coding to folder names in the menu following a keyword search.
  Implement color-coding for folder names. Each folder name is assigned a color based on the folder name to highlight repetitive folder structures.

- Load-code option to read one or more files into inherited lines.

- Automatic Load, Edit, Save, and View menu entries to manage inherited lines.
  The value of `document_saved_lines_glob` is displayed above the menu items, if any.
  The Load menu item appears when one or more files match the glob.
  The Edit menu item appears when one or more lines have been inherited.
  The Save menu item appears when one or more lines have been inherited.
  The View menu item appears when one or more lines have been inherited.

### Changed

- Fix block name processing for blocks with no name.
  Demo in examples/block_names.md loads content of docs/dev/load1.sh.

## [2.0.5] - 2024-04-24

### Changed

- Open option: Search for keyword in block names instead of entire document.

## [2.0.4] - 2024-04-22

### Added

- Option to match and open directories and files.

## [2.0.3] - 2024-04-15

### Added

- Option to set menu line count to fill console height.
- Rescue when named block in link block is missing.

### Changed

- Fix handling of variables with spaces in link blocks.
- Fix substitution for '/' in block names used in file names.

## [2.0.2] - 2024-02-09

### Changed

- Fix development requirement.

## [2.0.0] - 2024-02-07

### Added

- Process format and glob to load, save script code.

- Provide ENV and batch variables to formatting function.

- Find files matching glob and present for user selection.

- Allow for entry of new file name when saving.

## [1.8.9] - 2024-01-20

### Added

- Variables set in inherited lines for use in scripts.

- Link key `save` to write inherited lines to disk.

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
  See document `examples/wrapped-blocks.md`.
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

### Representing boolean values

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
