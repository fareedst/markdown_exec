# Changelog

## [1.0.1] - 2022-05-21

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
- Single-stage tab completion, defaut
    - Presents matching options when current word starts with `-`
    - Presents directories and files otherwise.
- Two-stage tab completion for option arguments.
    - When prior word is an option and current word is empty
    - Presents option type on first tab, eg `.BOOL.` for a boolean option.
    - Presents option default value on second tab, eg `0` for false.
- Use 'bash' shell instead of default
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
| block_name_excluded_match | MDE_BLOCK_NAME_EXCLUDED_MATCH  | `^\(.+\)$` |
| block_name_match | MDE_BLOCK_NAME_MATCH  | `:(?<title>\S+)( \|$)` |
| block_required_scan | MDE_BLOCK_REQUIRED_SCAN  | `\+\S+` |
| fenced_start_and_end_match | MDE_FENCED_START_AND_END_MATCH  | ``^`{3,}`` |
| fenced_start_ex_match | MDE_FENCED_START_EX_MATCH  | ``^`{3,}(?<shell>[^`\s]*) *(?<name>.*)$`` |
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
