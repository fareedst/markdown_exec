# MarkdownExec

Interactively select and execute fenced code blocks in markdown files. Build complex scripts by naming and requiring blocks.

* Code blocks may be named.

* Named blocks can be required by other blocks.

* The user-selected code block, and all required blocks, are arranged in the order they appear in the markdown file.

* The code is presented for approval prior to execution.

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

### `mde --help`
Displays help information.

### `mde`
Process `README.md` file in the current folder. Displays all the blocks in the file and allows you to select using [up], [down], and [return]. Press [ctrl]-c to abort selection.

### `mde my.md` or `mde -f my.md`
Select a block to execute from `my.md`.

### `mde .` or `mde -p .`

Select a markdown file in the current folder. Select a block to execute from that file.

### `mde --list-blocks`
List all blocks in the all the markdown documents in the current folder.

### `mde --list-docs`
List all markdown documents in the current folder.

## Behavior
* If no file and no folder are specified, blocks within `./README.md` are presented.
* If a file is specified, its blocks are presented.
* If a folder is specified, its files are presented. When a file is selected, its blocks are presented.

## Configuration
While starting up, reads the YAML configuration file `.mde.yml` in the current folder if it exists.

e.g. Use to set the default file for the current folder.

* `filename: CHANGELOG.md` sets the file to open.
* `folder: documents` sets the folder to search for default or specified files.

# Example blocks
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
