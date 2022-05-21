# MarkdownExec

Interactively select and execute fenced code blocks in markdown files. Build complex scripts by naming and requiring blocks. Log resulting scripts and output. Re-run scripts.

* Code blocks may be named. Named blocks can be required by other blocks.

* The user-selected code block, and all required blocks, are arranged into a script in the order they appear in the markdown file. The script can be presented for approval prior to execution.

* Executed scripts can be saved. Saved scripts can be listed, selected, and executed.

* Output from executed scripts can be saved.

## Screenshots

### Select a file

![Select a file](/assets/select_a_file.png)

### Select a block

![Select a block](/assets/select_a_block.png)

### Approve code

![Approve code](/assets/approve_code.png)

### Output

![Output of execution](/assets/output_of_execution.png)

### Example blocks

![Example blocks](/assets/example_blocks.png)

## Installation

Install:
    $ gem install markdown_exec

## Usage

### Help

#### `mde --help`

Displays help information.

### Basic

#### `mde`

Process `README.md` file in the current folder. Displays all the blocks in the file and allows you to select using [up], [down], and [return]. Press [ctrl]-c to abort selection.

#### `mde my.md` or `mde -f my.md`

Select a block to execute from `my.md`.

#### `mde my.md myblock`

Execute the block named `myblock` from `my.md`.

#### `mde .` or `mde -p .`

Select a markdown file in the current folder. Select a block to execute from that file.

### Report documents and blocks

#### `mde --list-blocks`

List all blocks in the all the markdown documents in the current folder.

#### `mde --list-docs`

List all markdown documents in the current folder.

### Configuration

#### `mde --list-default-env` or `mde --list-default-yaml`

List default values that can be set in configuration file, environment, and command line.

#### `mde -0`

Show current configuation values that will be applied to the current run. Does not interrupt processing.

### Save scripts

#### `mde --save-executed-script 1`

Save executed script in saved script folder.

#### `mde --list-recent-scripts`

List recent saved scripts in saved script folder.

#### `mde --select-recent-script`

Select and execute a recently saved script in saved script folder.

### Save output

#### `mde --save-execution-output 1`

Save execution output in saved output folder.

## Behavior

* If no file and no folder are specified, blocks within `./README.md` are presented.
* If a file is specified, its blocks are presented.
* If a folder is specified, its files are presented. When a file is selected, its blocks are presented.

## Configuration

### Environment Variables

When executed, `mde` reads the current environment.
* Configuration in current and children shells, e.g. `export MDE_SAVE_EXECUTED_SCRIPT=1`.
* Configuration for the current command, e.g. `MDE_SAVE_EXECUTED_SCRIPT=1 mde`.

### Configuration Files

* Configuration in all shells, e.g. environment variables set in your user's `~/.bashrc` or `~/.bash_profile` files.
* Configuration in the optional file `.mde.yml` in the current folder. .e.g. `save_executed_script: true`
* Configuration in a YAML file and read while parsing the inputs, e.g. `--config my_path/my_file.yml`

### Program Arguments

* Configuration in command options, e.g. `mde --save-executed-script 1`

## Representing boolean values

Boolean values expressed as strings are interpreted as:
| String | Boolean |
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

## Tab Completion

### Install tab completion

Append a command to load the completion script to your shell configuration file. `mde` must be executable for the command to be composed correctly.

```bash :()
echo "source $(mde --pwd)/bin/tab_completion.sh" >> ~/.bash_profile
```

### Example Completions

Type tab at end of any of the following commands to see the options.
- `mde `
- `mde -`
- `mde --`
- `mde --o`
- `mde --filename my.md -`
- `mde --filename my.md --`

## Example Blocks

When prompted, select either the `awake` or `asleep` block.

``` :(day)
export TIME=early
```

``` :(night)
export TIME=late
```

``` :awake +(day) +(report)
export ACTIVITY=awake
```

``` :asleep +(night) +(report)
export ACTIVITY=asleep
```

``` :(report)
echo "$TIME -> $ACTIVITY"
```

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the MarkdownExec project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/markdown_exec/blob/master/CODE_OF_CONDUCT.md).
