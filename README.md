# MarkdownExec

This gem allows you to interactively select and run code blocks in markdown files.

* Code blocks can be named.

* Named blocks can be required by other blocks.

* The selected code block, and all required blocks, are arranged in the order they appear in the markdown file.

* The resulting code is presented for approval prior to execution.

## Installation

Install:

    $ gem install markdown_exec

## Usage

`mde --help`
Displays help information.

`mde`
Process `README.md` file in the current directory. Displays all the blocks in the file and allows you to select using [up], [down], and [return]. Press [ctrl]-c to abort selection.

`mde -f my.md`
Process `my.md` file in the current directory.

`mde -p child`
Process markdown files in the `child` directory.

`mde --list-blocks`
List all blocks in the selected files.

`mde --list-docs`
List all markdown documents in the selected folder.

# Example blocks

When prompted, select either the `awake` or `asleep` block. The standard output confirms which required were blocks were included. Naming "hidden" blocks with parentheses "(" and ")" is a convention used here to re-inforce the purpose of the named blocks.

``` :(day)
# block named "(day)", required by other blocks
export MYTIME=early
```

``` :(night)
# block named "(night)", required by other blocks
export MYTIME=late
```

``` :awake +(day) +(report)
# block named "awake", select to see result
export ACTIVITY=awake
```

``` :asleep +(night) +(report)
# block named "asleep", select to see result
export ACTIVITY=asleep
```

``` :(report)
# block named "(report)", required by other blocks
echo "time: $MYTIME, activity: $ACTIVITY"
```

![Sample blocks](/assets/blocks.png)

![Selecting a block](/assets/select.png)

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the MarkdownExec project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/markdown_exec/blob/master/CODE_OF_CONDUCT.md).
